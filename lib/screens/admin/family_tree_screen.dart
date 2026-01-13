// lib/screens/admin/family_tree_screen.dart

// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import '../../models/member_model.dart';
import '../../services/member_service.dart';
import '../user/member_detail_screen.dart';

// Helper widget to handle profile images with error handling
class _TreeProfileImage extends StatefulWidget {
  final String? photoUrl;
  final String fullName;
  final double radius;

  const _TreeProfileImage({
    this.photoUrl,
    required this.fullName,
    this.radius = 20,
  });

  @override
  State<_TreeProfileImage> createState() => __TreeProfileImageState();
}

class __TreeProfileImageState extends State<_TreeProfileImage> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.photoUrl ?? '';
    final hasValidUrl = photoUrl.isNotEmpty && photoUrl.startsWith('http');

    if (!hasValidUrl || _hasError) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.blue.shade900,
        child: Text(
          widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : '?',
          style: TextStyle(fontSize: widget.radius * 0.7, color: Colors.white),
        ),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.blue.shade900,
      backgroundImage: NetworkImage(photoUrl),
      onBackgroundImageError: (_, __) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      },
    );
  }
}

class FamilyTreeScreen extends StatefulWidget {
  final String mainFamilyDocId;
  final String familyName;

  const FamilyTreeScreen({
    super.key,
    required this.mainFamilyDocId,
    required this.familyName,
  });

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  final MemberService _memberService = MemberService();
  List<MemberModel> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final stream = _memberService.streamAllMembers();
    stream.listen((members) {
      setState(() {
        _members = members;
        _loading = false;
      });
    });
  }

  List<MemberModel> _getChildren(String? parentMid) {
    return _members.where((m) => m.parentMid == parentMid).toList();
  }

  MemberModel? _getParent(MemberModel member) {
    if (member.parentMid.isEmpty) return null;
    return _members.firstWhere((m) => m.mid == member.parentMid);
  }

  List<MemberModel> _getRootMembers() {
    return _members.where((m) => m.parentMid.isEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rootMembers = _getRootMembers();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.familyName} - Family Tree'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: _members.isEmpty
          ? const Center(child: Text('No members in this family'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rootMembers.map((member) {
                      return _buildFamilyTree(member, 0);
                    }).toList(),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFamilyTree(MemberModel member, int level) {
    final children = _getChildren(member.mid);
    final parent = _getParent(member);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connector line from parent (if not root)
        if (parent != null)
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 8),
            child: Container(width: 2, height: 8, color: Colors.grey),
          ),
        // Member card
        Padding(
          padding: EdgeInsets.only(left: level * 30.0, top: 4),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberDetailScreen(memberId: member.id),
                ),
              );
            },
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade900),
                borderRadius: BorderRadius.circular(8),
                color: level == 0 ? Colors.blue.shade50 : Colors.white,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TreeProfileImage(
                        photoUrl: member.photoUrl,
                        fullName: member.fullName,
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              member.mid,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (member.phone.isNotEmpty)
                        const Icon(Icons.phone, size: 14, color: Colors.green),
                      if (member.phone.isNotEmpty) const SizedBox(width: 4),
                      if (member.phone.isNotEmpty)
                        Text(
                          member.phone,
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  if (member.marriageStatus.isNotEmpty)
                    Text(
                      member.marriageStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: member.marriageStatus == 'married'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Connector to children
        if (children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 4),
            child: Container(width: 2, height: 16, color: Colors.grey),
          ),
        // Children
        if (children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Column(
              children: children.map((child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Horizontal connector
                    Container(width: 15, height: 2, color: Colors.grey),
                    // Vertical connector for child
                    Container(
                      width: 2,
                      height: _getChildren(child.mid).isNotEmpty ? 100 : 50,
                      color: Colors.grey,
                    ),
                    // Child tree
                    Expanded(child: _buildFamilyTree(child, level + 1)),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
