// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/family_service.dart';

class EditFamilyScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditFamilyScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EditFamilyScreen> createState() => _EditFamilyScreenState();
}

class _EditFamilyScreenState extends State<EditFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _familyNameCtrl.text = widget.data['familyName'] ?? '';
  }

  @override
  void dispose() {
    _familyNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
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
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length != 6) {
                    return 'Must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        setState(() => _loading = true);

                        try {
                          await FamilyService().updateFamily(
                            familyDocId: widget.docId,
                            familyName: _familyNameCtrl.text.trim(),
                            password: _passwordCtrl.text.isNotEmpty
                                ? _passwordCtrl.text.trim()
                                : null,
                          );

                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating family: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _loading = false);
                          }
                        }
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
