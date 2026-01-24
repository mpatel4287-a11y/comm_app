// lib/screens/user/family_tree_view.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/member_model.dart';
import '../../services/member_service.dart';
import '../../services/language_service.dart';
import '../../services/theme_service.dart';
import 'package:provider/provider.dart';
import '../../services/session_manager.dart';
import '../admin/member_list_screen.dart';
import 'member_detail_screen.dart';

/// Represents a unit in the tree: either a single person or a married couple
class TreeEntity {
  final MemberModel primary;
  final MemberModel? spouse;
  final List<TreeEntity> children = [];
  Offset position = Offset.zero;
  double subtreeWidth = 0;

  TreeEntity({required this.primary, this.spouse});

  String get id => primary.mid;
  bool get isCouple => spouse != null;
}

class FamilyTreeView extends StatefulWidget {
  final String mainFamilyDocId;
  final String familyName;
  final String? subFamilyDocId;

  const FamilyTreeView({
    super.key,
    required this.mainFamilyDocId,
    required this.familyName,
    this.subFamilyDocId,
  });

  @override
  State<FamilyTreeView> createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> {
  final MemberService _memberService = MemberService();
  List<MemberModel> _members = [];
  bool _loading = true;
  bool _isAdmin = false;
  bool _isWholeFamily = true;
  String? _userSubFamilyId;

  // Layout state
  final List<TreeEntity> _rootEntities = [];
  double _treeWidth = 0;
  double _treeHeight = 0;

  static const double nodeWidth = 140.0;
  static const double nodeHeight = 160.0; // Taller for the image-style node
  static const double horizontalPadding = 40.0;
  static const double verticalPadding = 120.0;
  static const double coupleSpacing = 20.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final isAdmin = await SessionManager.getIsAdmin() ?? false;
    final userSubFamilyId = await SessionManager.getSubFamilyDocId();

    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _userSubFamilyId = userSubFamilyId;
        if (widget.subFamilyDocId != null) {
          _isWholeFamily = false;
        }
      });
    }

    _memberService.streamAllMembers().listen((members) {
      if (mounted) {
        setState(() {
          _members = members
              .where((m) => m.familyDocId == widget.mainFamilyDocId)
              .toList();
          _loading = false;
          _calculateLayout();
        });
      }
    });
  }

  void _calculateLayout() {
    _rootEntities.clear();
    if (_members.isEmpty) return;

    // 1. Group members into Entities (person + spouse)
    final Map<String, TreeEntity> entityMap = {};
    final List<MemberModel> remaining = List.from(_members);

    // First, find all 'head' members
    final heads = remaining.where((m) => m.relationToHead == 'head').toList();
    for (var head in heads) {
      // Find his spouse (relation 'wife' in same subFamily)
      final wife = remaining.firstWhere(
        (m) => m.relationToHead == 'wife' && m.subFamilyDocId == head.subFamilyDocId,
        orElse: () => MemberModel(id: '', mid: '', familyDocId: '', subFamilyDocId: '', subFamilyId: '', familyId: '', familyName: '', fullName: '', surname: '', fatherName: '', motherName: '', gotra: '', gender: 'female', birthDate: '', age: 0, education: '', bloodGroup: '', marriageStatus: '', nativeHome: '', phone: '', address: '', googleMapLink: '', firms: [], whatsapp: '', instagram: '', facebook: '', photoUrl: '', password: '', role: '', tags: [], isActive: true, parentMid: '', createdAt: DateTime.now()),
      );

      final entity = TreeEntity(
        primary: head,
        spouse: wife.id.isNotEmpty ? wife : null,
      );
      entityMap[head.mid] = entity;
      remaining.remove(head);
      if (wife.id.isNotEmpty) remaining.remove(wife);
    }

    // Wrap remaining as single entities
    for (var m in remaining) {
      entityMap[m.mid] = TreeEntity(primary: m);
    }

    // 2. Build Hierarchy
    for (var entity in entityMap.values) {
      // A child's parentMid refers to the HUSBAND (primary) in our logic
      final directChildren = entityMap.values.where((e) => e.primary.parentMid == entity.primary.mid).toList();
      
      // Joint logic: Sub-family bridge
      final isMainHead = entity.primary.relationToHead == 'head' && (entity.primary.subFamilyDocId.isEmpty || entity.primary.subFamilyDocId == 'null');
      final bridgedHeads = (_isWholeFamily && isMainHead)
          ? entityMap.values.where((e) => e.primary.relationToHead == 'head' && e.primary.subFamilyHeadRelationToMainHead.isNotEmpty).toList()
          : <TreeEntity>[];

      entity.children.addAll([...directChildren, ...bridgedHeads]);
    }

    // 3. Select Roots based on view mode
    if (_isWholeFamily) {
      _rootEntities.addAll(entityMap.values.where((e) {
        final isMainHead = e.primary.relationToHead == 'head' && (e.primary.subFamilyDocId.isEmpty || e.primary.subFamilyDocId == 'null');
        final hasNoParent = e.primary.parentMid.isEmpty;
        return isMainHead || (hasNoParent && e.primary.relationToHead == 'head');
      }));
    } else {
      final targetSubFamilyDocId = widget.subFamilyDocId ?? _userSubFamilyId;
      if (targetSubFamilyDocId != null) {
        _rootEntities.addAll(entityMap.values.where((e) => e.primary.subFamilyDocId == targetSubFamilyDocId && (e.primary.relationToHead == 'head' || e.primary.parentMid.isEmpty)));
      }
    }

    if (_rootEntities.isEmpty && entityMap.isNotEmpty) {
      _rootEntities.add(entityMap.values.first);
    }

    // 4. Recursive Positioning
    double currentX = 50;
    for (var root in _rootEntities) {
      currentX += _positionEntity(root, 0, currentX) + horizontalPadding;
    }

    // Bounds
    double maxX = 0, maxY = 0;
    for (var e in entityMap.values) {
      final x = e.position.dx + (e.isCouple ? nodeWidth * 2 + coupleSpacing : nodeWidth);
      final y = e.position.dy + nodeHeight;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    _treeWidth = maxX + 100;
    _treeHeight = maxY + 150;
  }

  double _positionEntity(TreeEntity entity, int level, double startX) {
    double childrenWidth = 0;
    if (entity.children.isEmpty) {
      childrenWidth = entity.isCouple ? nodeWidth * 2 + coupleSpacing : nodeWidth;
    } else {
      double childX = startX;
      for (var child in entity.children) {
        childrenWidth += _positionEntity(child, level + 1, childX) + horizontalPadding;
        childX = startX + childrenWidth;
      }
      childrenWidth -= horizontalPadding;
    }

    double entityWidth = entity.isCouple ? nodeWidth * 2 + coupleSpacing : nodeWidth;
    double x = startX + (childrenWidth / 2) - (entityWidth / 2);
    double y = 50.0 + level * (nodeHeight + verticalPadding);

    entity.position = Offset(x, y);
    entity.subtreeWidth = childrenWidth;
    return childrenWidth;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(lang.translate('family_tree')),
          backgroundColor: Colors.blue.shade900,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${widget.familyName} - ${lang.translate('family_tree')}'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() {
              _isWholeFamily = val;
              _calculateLayout();
            }),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: false, child: Text(lang.translate('my_family'))),
              PopupMenuItem(value: true, child: Text(lang.translate('whole_family'))),
            ],
          ),
        ],
      ),
      body: _members.isEmpty
          ? Center(child: Text(lang.translate('no_members_found')))
          : InteractiveViewer(
              constrained: false,
              minScale: 0.05,
              maxScale: 2.0,
              child: SizedBox(
                width: _treeWidth,
                height: _treeHeight,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(_treeWidth, _treeHeight),
                      painter: ForkLinePainter(rootEntities: _rootEntities, nodeWidth: nodeWidth, nodeHeight: nodeHeight, coupleSpacing: coupleSpacing),
                    ),
                    ..._buildEntityWidgets(lang, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildEntityWidgets(LanguageService lang, bool isDark) {
    final List<Widget> widgets = [];
    void traverse(TreeEntity e) {
      // Primary Node
      widgets.add(Positioned(
        left: e.position.dx,
        top: e.position.dy,
        child: _buildMemberNode(e.primary, lang, isDark),
      ));

      // Spouse Node
      if (e.spouse != null) {
        widgets.add(Positioned(
          left: e.position.dx + nodeWidth + coupleSpacing,
          top: e.position.dy,
          child: _buildMemberNode(e.spouse!, lang, isDark),
        ));
      }

      for (var child in e.children) {
        traverse(child);
      }
    }

    for (var root in _rootEntities) {
      traverse(root);
    }
    return widgets;
  }

  Widget _buildMemberNode(MemberModel member, LanguageService lang, bool isDark) {
    final bool isFemale = member.gender == 'female' || member.relationToHead == 'wife' || member.relationToHead == 'daughter';
    final Color themeColor = isFemale ? Colors.pink.shade400 : Colors.blue.shade600;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailScreen(memberId: member.id))),
      child: Container(
        width: nodeWidth,
        height: nodeHeight,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            // Top Accent Bar
            Container(height: 4, decoration: BoxDecoration(color: themeColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))),
            const SizedBox(height: 12),
            // Profile Image (Matches reference)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
                image: member.photoUrl.isNotEmpty 
                  ? DecorationImage(image: NetworkImage(member.photoUrl), fit: BoxFit.cover)
                  : null,
              ),
              child: member.photoUrl.isEmpty 
                ? Icon(Icons.person, size: 40, color: Colors.grey.shade400)
                : null,
            ),
            const SizedBox(height: 12),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                member.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            // Born Year
            Text(
              member.birthDate.isNotEmpty ? 'Born: ${member.birthDate.split('/').last}' : '',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            // Admin Actions
            if (_isAdmin) 
               Container(
                 decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8))),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                     IconButton(icon: Icon(Icons.person_add, size: 16, color: Colors.green.shade700), onPressed: () => _navToAddChild(member), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                     IconButton(icon: Icon(Icons.edit, size: 16, color: Colors.blue.shade700), onPressed: () => _navToEdit(member), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                     IconButton(icon: Icon(Icons.delete, size: 16, color: Colors.red.shade700), onPressed: () => _confirmDelete(context, member), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                   ],
                 ),
               ),
          ],
        ),
      ),
    );
  }

  void _navToAddChild(MemberModel m) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddMemberScreen(familyDocId: m.familyDocId, subFamilyDocId: m.subFamilyDocId, familyName: m.familyName, initialParentMid: m.mid)));
  }

  void _navToEdit(MemberModel m) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditMemberScreen(memberId: m.id, familyDocId: m.familyDocId, subFamilyDocId: m.subFamilyDocId.isEmpty ? null : m.subFamilyDocId)));
  }

  Future<void> _confirmDelete(BuildContext context, MemberModel member) async {
    final lang = Provider.of<LanguageService>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.translate('confirmation')),
        content: Text('${lang.translate('are_you_sure')} ${member.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lang.translate('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(lang.translate('delete'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _memberService.deleteMember(mainFamilyDocId: member.familyDocId, subFamilyDocId: member.subFamilyDocId, memberId: member.id);
    }
  }
}

class ForkLinePainter extends CustomPainter {
  final List<TreeEntity> rootEntities;
  final double nodeWidth;
  final double nodeHeight;
  final double coupleSpacing;

  ForkLinePainter({required this.rootEntities, required this.nodeWidth, required this.nodeHeight, required this.coupleSpacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    void drawLines(TreeEntity e) {
      double parentCenterX = e.position.dx + (e.isCouple ? (nodeWidth * 2 + coupleSpacing) / 2 : nodeWidth / 2);
      double parentBottomY = e.position.dy + nodeHeight;

      if (e.isCouple) {
        // Horizontal line between couple
        final lineY = e.position.dy + nodeHeight / 2;
        canvas.drawLine(Offset(e.position.dx + nodeWidth, lineY), Offset(e.position.dx + nodeWidth + coupleSpacing, lineY), paint);
      }

      if (e.children.isNotEmpty) {
        // Vertical line down from parents
        final forkY = parentBottomY + 40;
        canvas.drawLine(Offset(parentCenterX, parentBottomY), Offset(parentCenterX, forkY), paint);

        // Horizontal span
        double firstChildX = e.children.first.position.dx + (e.children.first.isCouple ? (nodeWidth * 2 + coupleSpacing) / 2 : nodeWidth / 2);
        double lastChildX = e.children.last.position.dx + (e.children.last.isCouple ? (nodeWidth * 2 + coupleSpacing) / 2 : nodeWidth / 2);
        canvas.drawLine(Offset(firstChildX, forkY), Offset(lastChildX, forkY), paint);

        // Vertical lines to each child
        for (var child in e.children) {
          double childCenterX = child.position.dx + (child.isCouple ? (nodeWidth * 2 + coupleSpacing) / 2 : nodeWidth / 2);
          canvas.drawLine(Offset(childCenterX, forkY), Offset(childCenterX, child.position.dy), paint);
          drawLines(child);
        }
      }
    }

    for (var root in rootEntities) {
      drawLines(root);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


