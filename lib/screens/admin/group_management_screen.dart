// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../../../services/group_service.dart';
import '../../../services/member_service.dart';
import '../../../services/session_manager.dart';
import '../../../models/group_model.dart';
import '../../../models/member_model.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final GroupService _groupService = GroupService();
  final MemberService _memberService = MemberService();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _selectedType = 'community';
  String? _familyDocId;
  List<MemberModel> _allMembers = [];

  @override
  void initState() {
    super.initState();
    _loadFamilyDocId();
    _loadMembers();
  }

  Future<void> _loadFamilyDocId() async {
    final docId = await SessionManager.getFamilyDocId();
    setState(() => _familyDocId = docId);
  }

  Future<void> _loadMembers() async {
    final members = await _memberService.streamAllMembers().first;
    setState(() => _allMembers = members);
  }

  @override
  Widget build(BuildContext context) {
    if (_familyDocId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Management'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: StreamBuilder<List<GroupModel>>(
        stream: _groupService.streamGroups(_familyDocId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data!;

          if (groups.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No groups found'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTypeColor(group.type),
                    child: Icon(_getTypeIcon(group.type), color: Colors.white),
                  ),
                  title: Text(group.name),
                  subtitle: Text('${group.memberIds.length} members'),
                  children: [
                    if (group.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          group.description,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: group.memberIds.map((memberId) {
                        final member = _allMembers.firstWhere(
                          (m) => m.id == memberId,
                          orElse: () => MemberModel(
                            id: memberId,
                            mid: '',
                            familyDocId: '',
                            subFamilyDocId: '',
                            subFamilyId: '',
                            familyId: '',
                            familyName: '',
                            fullName: 'Unknown',
                            surname: '',
                            fatherName: '',
                            motherName: '',
                            gotra: '',
                            gender: 'male',
                            birthDate: '',
                            age: 0,
                            education: '', // Added
                            email: '', // Added
                            bloodGroup: '',
                            marriageStatus: 'unmarried',
                            nativeHome: '',
                            phone: '',
                            address: '',
                            googleMapLink: '',
                            surdhan: '', // Added
                            firms: [],
                            whatsapp: '',
                            instagram: '',
                            facebook: '',
                            photoUrl: '',
                            password: 'password', // Added to fix constructor
                            role: 'member',
                            tags: [],
                            isActive: true,
                            parentMid: '',
                            createdAt: DateTime.now(),
                          ),
                        );
                        return Chip(
                          label: Text(member.fullName),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeMember(group, memberId),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Members'),
                          onPressed: () => _showAddMembersDialog(group),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showEditDialog(group);
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Group'),
                                  content: const Text(
                                    'Are you sure you want to delete this group?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _groupService.deleteGroup(
                                  _familyDocId!,
                                  group.id,
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'yuvak':
        return Icons.people;
      case 'mahila':
        return Icons.woman;
      case 'sanskar':
        return Icons.school;
      default:
        return Icons.group;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'yuvak':
        return Colors.blue;
      case 'mahila':
        return Colors.pink;
      case 'sanskar':
        return Colors.orange;
      default:
        return Colors.blue.shade900;
    }
  }

  Future<void> _removeMember(GroupModel group, String memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
          'Are you sure you want to remove this member from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _groupService.removeMemberFromGroup(
        familyDocId: _familyDocId!,
        groupId: group.id,
        memberId: memberId,
      );
    }
  }

  void _showAddMembersDialog(GroupModel group) {
    final availableMembers = _allMembers
        .where((m) => !group.memberIds.contains(m.id))
        .toList();

    if (availableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All members are already in this group')),
      );
      return;
    }

    final Set<String> _selectedMembers = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Members to ${group.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableMembers.length,
              itemBuilder: (context, index) {
                final member = availableMembers[index];
                return CheckboxListTile(
                  title: Text(member.fullName),
                  value: _selectedMembers.contains(member.id),
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        _selectedMembers.add(member.id);
                      } else {
                        _selectedMembers.remove(member.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                for (final memberId in _selectedMembers) {
                  await _groupService.addMemberToGroup(
                    familyDocId: _familyDocId!,
                    groupId: group.id,
                    memberId: memberId,
                  );
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Members added successfully')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    _nameCtrl.clear();
    _descriptionCtrl.clear();
    _selectedType = 'community';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items:
                  [
                        {'value': 'community', 'label': 'Community'},
                        {'value': 'yuvak', 'label': 'Yuvak'},
                        {'value': 'mahila', 'label': 'Mahila'},
                        {'value': 'sanskar', 'label': 'Sanskar'},
                      ]
                      .map(
                        (t) => DropdownMenuItem(
                          value: t['value'] as String,
                          child: Text(t['label'] as String),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameCtrl.text.trim().isEmpty) return;
              await _groupService.createGroupWithDetails(
                familyDocId: _familyDocId!,
                name: _nameCtrl.text.trim(),
                description: _descriptionCtrl.text.trim(),
                type: _selectedType,
                createdBy: 'admin',
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(GroupModel group) {
    _nameCtrl.text = group.name;
    _descriptionCtrl.text = group.description;
    _selectedType = group.type;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items:
                  [
                        {'value': 'community', 'label': 'Community'},
                        {'value': 'yuvak', 'label': 'Yuvak'},
                        {'value': 'mahila', 'label': 'Mahila'},
                        {'value': 'sanskar', 'label': 'Sanskar'},
                      ]
                      .map(
                        (t) => DropdownMenuItem(
                          value: t['value'] as String,
                          child: Text(t['label'] as String),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameCtrl.text.trim().isEmpty) return;
              await _groupService.updateGroupWithDetails(
                familyDocId: _familyDocId!,
                groupId: group.id,
                name: _nameCtrl.text.trim(),
                description: _descriptionCtrl.text.trim(),
                type: _selectedType,
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
