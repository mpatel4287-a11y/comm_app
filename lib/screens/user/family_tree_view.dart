// lib/screens/user/family_tree_view.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/member_model.dart';
import '../../services/member_service.dart';
import '../../services/language_service.dart';
import '../../services/theme_service.dart';
import 'package:provider/provider.dart';
import 'member_detail_screen.dart';

class FamilyTreeView extends StatefulWidget {
  final String mainFamilyDocId;
  final String familyName;

  const FamilyTreeView({
    super.key,
    required this.mainFamilyDocId,
    required this.familyName,
  });

  @override
  State<FamilyTreeView> createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> {
  final MemberService _memberService = MemberService();
  List<MemberModel> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    _memberService.streamAllMembers().listen((members) {
      if (mounted) {
        setState(() {
          _members = members
              .where((m) => m.familyDocId == widget.mainFamilyDocId)
              .toList();
          _loading = false;
        });
      }
    });
  }

  List<MemberModel> _getChildren(String? parentMid) {
    return _members.where((m) => m.parentMid == parentMid).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  List<MemberModel> _getRootMembers() {
    return _members.where((m) => m.parentMid.isEmpty).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
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

    final rootMembers = _getRootMembers();

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text('${widget.familyName} - ${lang.translate('family_tree')}'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: () {
              // Zoom out / reset view
            },
          ),
        ],
      ),
      body: _members.isEmpty
          ? Center(
              child: Text(
                lang.translate('no_members_found'),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : InteractiveViewer(
              minScale: 0.5,
              maxScale: 2.0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rootMembers.map((member) {
                        return _buildFamilyTreeNode(member, 0);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFamilyTreeNode(MemberModel member, int level) {
    final children = _getChildren(member.mid);
    final hasChildren = children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Member Card
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MemberDetailScreen(memberId: member.id),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.only(left: level * 40.0, top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade900,
                  backgroundImage:
                      member.photoUrl.isNotEmpty &&
                          member.photoUrl.startsWith('http')
                      ? NetworkImage(member.photoUrl)
                      : null,
                  child:
                      member.photoUrl.isEmpty ||
                          !member.photoUrl.startsWith('http')
                      ? Text(
                          member.fullName.isNotEmpty
                              ? member.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Member Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (member.age > 0)
                      Text(
                        '${member.age} ${member.marriageStatus == 'married' ? '👫' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (member.bloodGroup.isNotEmpty)
                      Text(
                        member.bloodGroup,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Children
        if (hasChildren) ...[
          // Connector Line
          Container(
            margin: EdgeInsets.only(left: level * 40.0 + 24),
            width: 2,
            height: 16,
            color: Colors.grey.shade400,
          ),
          // Children Nodes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical connector
              Container(
                margin: EdgeInsets.only(left: level * 40.0 + 24),
                width: 2,
                height: children.length * 100.0,
                color: Colors.grey.shade400,
              ),
              // Horizontal connector
              Container(
                margin: EdgeInsets.only(top: children.length * 50.0 - 8),
                width: 20,
                height: 2,
                color: Colors.grey.shade400,
              ),
              // Children
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children.map((child) {
                    return _buildFamilyTreeNode(child, level + 1);
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
