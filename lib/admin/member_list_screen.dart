// ignore_for_file: prefer_final_fields, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/member_service.dart';

// Placeholder for AddMemberScreen
class AddMemberScreen extends StatefulWidget {
  final String familyDocId;
  final String familyName;

  const AddMemberScreen({
    super.key,
    required this.familyDocId,
    required this.familyName,
  });

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _gotraCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _googleMapLinkCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _nativeHomeCtrl = TextEditingController();
  final _parentMidCtrl = TextEditingController();

  String _bloodGroup = '';
  String _marriageStatus = 'unmarried';
  List<String> _tags = [];
  List<Map<String, String>> _firms = [];
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Personal Info
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _surnameCtrl,
              decoration: const InputDecoration(labelText: 'Surname'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fatherNameCtrl,
              decoration: const InputDecoration(labelText: 'Father Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motherNameCtrl,
              decoration: const InputDecoration(labelText: 'Mother Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gotraCtrl,
              decoration: const InputDecoration(labelText: 'Gotra'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _birthDateCtrl,
              decoration: const InputDecoration(
                labelText: 'Birth Date (dd/MM/yyyy) *',
                hintText: '15/08/1990',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _bloodGroup.isEmpty ? null : _bloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group'),
              items: ['', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                  .map(
                    (bg) => DropdownMenuItem(
                      value: bg,
                      child: Text(bg.isEmpty ? 'Select' : bg),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _bloodGroup = v ?? ''),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _marriageStatus,
              decoration: const InputDecoration(labelText: 'Marriage Status'),
              items: [
                'unmarried',
                'married',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) =>
                  setState(() => _marriageStatus = v ?? 'unmarried'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nativeHomeCtrl,
              decoration: const InputDecoration(labelText: 'Native Home'),
            ),

            // Contact Info
            const SizedBox(height: 20),
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone *'),
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _googleMapLinkCtrl,
              decoration: const InputDecoration(
                labelText: 'Google Map Link',
                hintText: 'https://maps.google.com/...',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _whatsappCtrl,
              decoration: const InputDecoration(labelText: 'WhatsApp'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instagramCtrl,
              decoration: const InputDecoration(labelText: 'Instagram'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _facebookCtrl,
              decoration: const InputDecoration(labelText: 'Facebook'),
            ),

            // Family Tree
            const SizedBox(height: 20),
            const Text(
              'Family Tree',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _parentMidCtrl,
              decoration: const InputDecoration(
                labelText: 'Parent Member ID',
                hintText: 'Enter parent MID (optional)',
              ),
            ),

            // Tags (Admin Only)
            const SizedBox(height: 20),
            const Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Add Tag (max 15 chars)',
                    ),
                    onFieldSubmitted: (v) {
                      if (v.isNotEmpty && v.length <= 15) {
                        setState(() {
                          if (!_tags.contains(v)) _tags.add(v);
                          _tagsCtrl.clear();
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final v = _tagsCtrl.text.trim();
                    if (v.isNotEmpty && v.length <= 15 && !_tags.contains(v)) {
                      setState(() {
                        _tags.add(v);
                        _tagsCtrl.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      setState(() => _loading = true);

                      try {
                        // Get family data for familyId
                        final familyDoc = await FirebaseFirestore.instance
                            .collection('families')
                            .doc(widget.familyDocId)
                            .get();
                        final familyData =
                            familyDoc.data() as Map<String, dynamic>;
                        final familyId = familyData['familyId'].toString();

                        await MemberService().addMember(
                          familyDocId: widget.familyDocId,
                          familyId: familyId,
                          familyName: widget.familyName,
                          fullName: _fullNameCtrl.text.trim(),
                          surname: _surnameCtrl.text.trim(),
                          fatherName: _fatherNameCtrl.text.trim(),
                          motherName: _motherNameCtrl.text.trim(),
                          gotra: _gotraCtrl.text.trim(),
                          birthDate: _birthDateCtrl.text.trim(),
                          bloodGroup: _bloodGroup,
                          marriageStatus: _marriageStatus,
                          nativeHome: _nativeHomeCtrl.text.trim(),
                          phone: _phoneCtrl.text.trim(),
                          address: _addressCtrl.text.trim(),
                          googleMapLink: _googleMapLinkCtrl.text.trim(),
                          firms: _firms,
                          whatsapp: _whatsappCtrl.text.trim(),
                          instagram: _instagramCtrl.text.trim(),
                          facebook: _facebookCtrl.text.trim(),
                          tags: _tags,
                          parentMid: _parentMidCtrl.text.trim(),
                        );

                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
                    child: const Text('Add Member'),
                  ),
          ],
        ),
      ),
    );
  }
}

class EditMemberScreen extends StatefulWidget {
  final String memberId;
  final String familyDocId;

  const EditMemberScreen({
    super.key,
    required this.memberId,
    required this.familyDocId,
  });

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _gotraCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _googleMapLinkCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  String _bloodGroup = '';
  String _marriageStatus = 'unmarried';
  List<String> _tags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    final member = await MemberService().getMember(widget.memberId);
    if (member != null) {
      _fullNameCtrl.text = member.fullName;
      _surnameCtrl.text = member.surname;
      _fatherNameCtrl.text = member.fatherName;
      _motherNameCtrl.text = member.motherName;
      _gotraCtrl.text = member.gotra;
      _birthDateCtrl.text = member.birthDate;
      _phoneCtrl.text = member.phone;
      _addressCtrl.text = member.address;
      _googleMapLinkCtrl.text = member.googleMapLink;
      _bloodGroup = member.bloodGroup;
      _marriageStatus = member.marriageStatus;
      _tags = List.from(member.tags);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Member')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _surnameCtrl,
              decoration: const InputDecoration(labelText: 'Surname'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fatherNameCtrl,
              decoration: const InputDecoration(labelText: 'Father Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motherNameCtrl,
              decoration: const InputDecoration(labelText: 'Mother Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gotraCtrl,
              decoration: const InputDecoration(labelText: 'Gotra'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _birthDateCtrl,
              decoration: const InputDecoration(
                labelText: 'Birth Date (dd/MM/yyyy)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _bloodGroup.isEmpty ? null : _bloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group'),
              items: ['', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                  .map(
                    (bg) => DropdownMenuItem(
                      value: bg,
                      child: Text(bg.isEmpty ? 'Select' : bg),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _bloodGroup = v ?? ''),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _marriageStatus,
              decoration: const InputDecoration(labelText: 'Marriage Status'),
              items: [
                'unmarried',
                'married',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) =>
                  setState(() => _marriageStatus = v ?? 'unmarried'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _googleMapLinkCtrl,
              decoration: const InputDecoration(
                labelText: 'Google Map Link',
                hintText: 'https://maps.google.com/...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Add Tag (max 15 chars)',
                    ),
                    onFieldSubmitted: (v) {
                      if (v.isNotEmpty && v.length <= 15) {
                        setState(() {
                          if (!_tags.contains(v)) _tags.add(v);
                          _tagsCtrl.clear();
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final v = _tagsCtrl.text.trim();
                    if (v.isNotEmpty && v.length <= 15 && !_tags.contains(v)) {
                      setState(() {
                        _tags.add(v);
                        _tagsCtrl.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                await MemberService().updateMember(
                  memberId: widget.memberId,
                  updates: {
                    'fullName': _fullNameCtrl.text.trim(),
                    'surname': _surnameCtrl.text.trim(),
                    'fatherName': _fatherNameCtrl.text.trim(),
                    'motherName': _motherNameCtrl.text.trim(),
                    'gotra': _gotraCtrl.text.trim(),
                    'birthDate': _birthDateCtrl.text.trim(),
                    'bloodGroup': _bloodGroup,
                    'marriageStatus': _marriageStatus,
                    'phone': _phoneCtrl.text.trim(),
                    'address': _addressCtrl.text.trim(),
                    'googleMapLink': _googleMapLinkCtrl.text.trim(),
                    'tags': _tags,
                  },
                );

                Navigator.pop(context);
              },
              child: const Text('Update Member'),
            ),
          ],
        ),
      ),
    );
  }
}

class MemberListScreen extends StatefulWidget {
  final String familyDocId;
  final String familyName;

  const MemberListScreen(this.familyDocId, this.familyName, {super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  String _searchQuery = '';
  String _selectedTag = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.familyName),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMemberScreen(
                    familyDocId: widget.familyDocId,
                    familyName: widget.familyName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search members...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          FutureBuilder<List<String>>(
            future: MemberService().getAllTags(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final tags = snapshot.data!;
              return SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    final isSelected = _selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTag = selected ? tag : '';
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('members')
                  .where('familyDocId', isEqualTo: widget.familyDocId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No members found'));
                }

                final members = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fullName = (data['fullName'] ?? '').toLowerCase();
                  final searchLower = _searchQuery.toLowerCase();
                  final matchesSearch = fullName.contains(searchLower);
                  final tags = List<String>.from(data['tags'] ?? []);
                  final matchesTag =
                      _selectedTag.isEmpty || tags.contains(_selectedTag);
                  return matchesSearch && matchesTag;
                }).toList();

                if (members.isEmpty) {
                  return const Center(
                    child: Text('No members match your search'),
                  );
                }

                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final doc = members[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final tags = List<String>.from(data['tags'] ?? []);
                    final isActive = data['isActive'] as bool? ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      color: isActive ? Colors.white : Colors.grey.shade200,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade900,
                          child: Text(
                            (data['fullName'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          data['fullName'] ?? 'Unnamed',
                          style: TextStyle(
                            color: isActive
                                ? Colors.black
                                : Colors.grey.shade700,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['surname'] ?? ''} • ${data['age'] ?? 0} years',
                            ),
                            if (tags.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: tags.take(3).map((tag) {
                                  return Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    padding: EdgeInsets.zero,
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditMemberScreen(
                                    memberId: doc.id,
                                    familyDocId: widget.familyDocId,
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Member'),
                                  content: const Text(
                                    'Are you sure you want to delete this member?',
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
                                await MemberService().deleteMember(doc.id);
                              }
                            } else if (value == 'toggle') {
                              await MemberService().updateMember(
                                memberId: doc.id,
                                updates: {'isActive': !isActive},
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(isActive ? 'Deactivate' : 'Activate'),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMemberScreen(
                familyDocId: widget.familyDocId,
                familyName: widget.familyName,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
