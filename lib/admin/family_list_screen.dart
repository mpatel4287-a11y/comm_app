// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_service.dart';
import 'add_family_screen.dart';
import 'member_list_screen.dart';

// Placeholder for EditFamilyScreen
class EditFamilyScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditFamilyScreen({super.key, required this.docId, required this.data});

  @override
  State<EditFamilyScreen> createState() => _EditFamilyScreenState();
}

class _EditFamilyScreenState extends State<EditFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _familyNameCtrl.text = widget.data['familyName'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Family')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _familyNameCtrl,
                decoration: const InputDecoration(labelText: 'Family Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New Password (6 digit)',
                  hintText: 'Leave blank to keep current',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  await FamilyService().updateFamily(
                    familyDocId: widget.docId,
                    familyName: _familyNameCtrl.text.trim(),
                    password: _passwordCtrl.text.isNotEmpty
                        ? _passwordCtrl.text.trim()
                        : null,
                  );

                  Navigator.pop(context);
                },
                child: const Text('Update Family'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FamilyListScreen extends StatelessWidget {
  const FamilyListScreen({super.key});

  void _showFamilyOptions(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final isBlocked = data['isBlocked'] as bool? ?? false;
    final familyId = data['familyId'];
    final familyName = data['familyName'] ?? 'Unnamed';

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              familyName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Family ID: $familyId'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Family'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditFamilyScreen(docId: docId, data: data),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(isBlocked ? Icons.lock_open : Icons.block),
              title: Text(isBlocked ? 'Unblock Family' : 'Block Family'),
              onTap: () async {
                Navigator.pop(context);
                await FamilyService().toggleBlockFamily(docId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Family',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Family'),
                    content: Text(
                      'Are you sure you want to delete $familyName? This will also delete all members.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FamilyService().deleteFamily(docId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Families'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('families')
            .where('isAdmin', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No families found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isBlocked = data['isBlocked'] as bool? ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: isBlocked ? Colors.grey.shade200 : Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isBlocked
                        ? Colors.grey
                        : Colors.blue.shade900,
                    child: Icon(
                      isBlocked ? Icons.lock : Icons.family_restroom,
                      color: Colors.white,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['familyName'] ?? 'Unnamed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isBlocked
                                ? Colors.grey.shade700
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (isBlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'BLOCKED',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text('Family ID: ${data['familyId']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MemberListScreen(doc.id, data['familyName']),
                      ),
                    );
                  },
                  onLongPress: () => _showFamilyOptions(context, doc.id, data),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFamilyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
