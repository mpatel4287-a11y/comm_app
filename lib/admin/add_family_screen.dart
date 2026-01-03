// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/family_service.dart';

class AddFamilyScreen extends StatefulWidget {
  const AddFamilyScreen({super.key});

  @override
  State<AddFamilyScreen> createState() => _AddFamilyScreenState();
}

class _AddFamilyScreenState extends State<AddFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyIdCtrl = TextEditingController();
  final _familyNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final FamilyService _familyService = FamilyService();
  bool _loading = false;
  String? _error;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _familyService.addFamily(
        familyId: int.parse(_familyIdCtrl.text.trim()),
        familyName: _familyNameCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Family')),
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
                controller: _familyIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Family ID (6 digit)',
                ),
                validator: (v) =>
                    v != null && v.length == 6 ? null : 'Must be 6 digits',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Password (6 digit)',
                ),
                validator: (v) =>
                    v != null && v.length == 6 ? null : 'Must be 6 digits',
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _save,
                      child: const Text('Create Family'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
