// lib/screens/user/family_tree_view.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/member_model.dart';
import '../../services/member_service.dart';
import '../../services/language_service.dart';
import '../../services/theme_service.dart';
import 'package:provider/provider.dart';
import '../../services/session_manager.dart';
import '../admin/member_list_screen.dart'; // Correctly import Add/Edit screens from here
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

  // Layout configuration (Exactly matching Image 3 proportions)
  double _nodeWidth = 85.0;
  double _nodeHeight = 90.0; // Base height, will grow if needed
  double _horizontalPadding = 20.0;
  double _verticalPadding = 60.0;
  double _coupleSpacing = 10.0;



  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final role = await SessionManager.getRole();
    final isAdmin = role == 'admin';
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
        final familyMembers = members
            .where((m) => m.familyDocId == widget.mainFamilyDocId)
            .toList();
        setState(() {
          _members = familyMembers;
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
      // Find children who have this person as parentMid
      final directChildren = entityMap.values.where((e) => e.primary.parentMid == entity.primary.mid).toList();
      
      // Bridge logic for sub-families if parentMid is missing but they are marked as having a relation to main head
      final isMainHead = entity.primary.relationToHead == 'head' && (entity.primary.subFamilyDocId.isEmpty || entity.primary.subFamilyDocId == 'null');
      
      final bridgedHeads = (_isWholeFamily && isMainHead)
          ? entityMap.values.where((e) {
              final isRelatedHead = e.primary.relationToHead == 'head' && e.primary.subFamilyHeadRelationToMainHead.isNotEmpty;
              // Only bridge if they don't already have a parent in the set (don't over-bridge if data has parentMid)
              final hasNoParent = e.primary.parentMid.isEmpty || !entityMap.containsKey(e.primary.parentMid);
              return isRelatedHead && hasNoParent;
            }).toList()
          : <TreeEntity>[];

      entity.children.addAll([...directChildren, ...bridgedHeads]);
    }


    // 3. Select Roots based on view mode (Image 3 logic: only main ancestors at top)
    if (_isWholeFamily) {
      final allMids = entityMap.values.map((e) => e.primary.mid).toSet();
      _rootEntities.addAll(entityMap.values.where((e) {
        // A root criteria: 
        // 1. Their parentMid is NOT in our set. 
        // 2. AND (they are marked as 'head' OR they have no parents at all).
        final hasNoParentInSet = e.primary.parentMid.isEmpty || !allMids.contains(e.primary.parentMid);
        
        // Fix: If they are a 'wife' but their husband is in the set, she's NOT a root (she's grouped).
        // If they are a 'daughter' and their parent IS in the set, they are NOT a root.
        final shouldBeChild = !hasNoParentInSet;

        return !shouldBeChild && (e.primary.relationToHead == 'head' || e.primary.parentMid.isEmpty);
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
      currentX += _positionEntity(root, 0, currentX) + _horizontalPadding;
    }

    // Bounds
    double maxX = 0, maxY = 0;
    for (var e in entityMap.values) {
      final x = e.position.dx + (e.isCouple ? _nodeWidth * 2 + _coupleSpacing : _nodeWidth);
      final y = e.position.dy + _nodeHeight;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    _treeWidth = maxX + 100;
    _treeHeight = maxY + 150;
  }

  double _positionEntity(TreeEntity entity, int level, double startX) {
    double childrenWidth = 0;
    if (entity.children.isEmpty) {
      childrenWidth = entity.isCouple ? _nodeWidth * 2 + _coupleSpacing : _nodeWidth;
    } else {
      double childX = startX;
      for (var child in entity.children) {
        childrenWidth += _positionEntity(child, level + 1, childX) + _horizontalPadding;
        childX = startX + childrenWidth;
      }
      childrenWidth -= _horizontalPadding;
    }

    double entityWidth = entity.isCouple ? _nodeWidth * 2 + _coupleSpacing : _nodeWidth;
    double x = startX + (childrenWidth / 2) - (entityWidth / 2);
    double y = 50.0 + level * (_nodeHeight + _verticalPadding);

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

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    
    // Scale dimensions slightly but keep them compact
    _nodeWidth = (85.0 * textScale.clamp(1.0, 1.2));
    _nodeHeight = (90.0 + (_isAdmin ? 30.0 : 0)) * textScale; 
    _horizontalPadding = 20.0 * textScale;
    _verticalPadding = 60.0 * textScale;
    _coupleSpacing = 10.0 * textScale;


    // Recalculate layout with new dimensions
    _calculateLayout();

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
                child: RepaintBoundary(
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(_treeWidth, _treeHeight),
                        painter: ForkLinePainter(
                          rootEntities: _rootEntities,
                          nodeWidth: _nodeWidth,
                          nodeHeight: _nodeHeight,
                          coupleSpacing: _coupleSpacing,
                          verticalPadding: _verticalPadding,
                        ),
                      ),

                      ..._buildEntityWidgets(lang, isDark),
                    ],
                  ),
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
          left: e.position.dx + _nodeWidth + _coupleSpacing,
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
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailScreen(memberId: member.id))),
      child: Container(
        width: _nodeWidth,
        constraints: BoxConstraints(minHeight: _nodeHeight),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(2), // Match Image 3 sharp corners
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, 1))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Accent Bar (Strictly matching Image 3)
            Container(height: 2, decoration: BoxDecoration(color: themeColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(2)))),
            const SizedBox(height: 4),
            // Profile Image (Matches Image 3 proportions)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                image: member.photoUrl.isNotEmpty 
                  ? DecorationImage(image: NetworkImage(member.photoUrl), fit: BoxFit.cover)
                  : null,
              ),
              child: member.photoUrl.isEmpty 
                ? Icon(Icons.person, size: 24, color: Colors.grey.shade300)
                : null,
            ),
            const SizedBox(height: 4),
            // Info Section - Use Flexible/Wrap to avoid overflow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8.5, height: 1.1),
                    textAlign: TextAlign.center,
                    maxLines: 2, // Allow 2 lines for long names
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Born: ${member.birthDate.split("/").last}', // Mocking Image 3 style
                    style: const TextStyle(fontSize: 7, color: Colors.black54),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '(${lang.translate(member.relationToHead)})',
                      style: TextStyle(fontSize: 7, color: themeColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            if (_isAdmin) ...[
              const Spacer(),
              Container(
                 padding: const EdgeInsets.symmetric(vertical: 2),
                 color: Colors.grey.shade100,
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                     InkWell(onTap: () => _navToAddChild(member), child: Icon(Icons.add_circle_outline, size: 12, color: Colors.green.shade700)),
                     InkWell(onTap: () => _navToEdit(member), child: Icon(Icons.edit, size: 12, color: Colors.blue.shade700)),
                     InkWell(onTap: () => _confirmDelete(context, member), child: Icon(Icons.delete_forever, size: 12, color: Colors.red.shade700)),
                   ],
                 ),
               ),
            ],
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
  final double verticalPadding;

  ForkLinePainter({
    required this.rootEntities,
    required this.nodeWidth,
    required this.nodeHeight,
    required this.coupleSpacing,
    required this.verticalPadding,
  });


  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0 // Strictly matching Image 3 (thinner lines)
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
        final forkY = parentBottomY + (verticalPadding / 2); 
        canvas.drawLine(Offset(parentCenterX, parentBottomY), Offset(parentCenterX, forkY), paint);


        // Horizontal span
        double firstChildX = e.children.first.position.dx + (e.children.first.isCouple ? (nodeWidth * 2 + coupleSpacing) / 2 : nodeWidth / 2);
        double lastChildX = e.children.last.position.dx + (e.children.last.isCouple ? (nodeWidth * 2 + coupleSpacing) / 2 : nodeWidth / 2);
        
        if (e.children.length > 1) {
          canvas.drawLine(Offset(firstChildX, forkY), Offset(lastChildX, forkY), paint);
        }

        // Vertical lines to each child
        for (var child in e.children) {
          double childCenterX = child.position.dx + (child.isCouple ? (nodeWidth * 2 + coupleSpacing) / 2 : nodeWidth / 2);
          // Line from fork to child top
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


