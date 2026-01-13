// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import '../models/subfamily_model.dart';
import '../services/subfamily_service.dart';
import '../services/family_service.dart';
import 'member_list_screen.dart';

class SubFamilyListScreen extends StatefulWidget {
  final String mainFamilyDocId;
  final String mainFamilyId;
  final String mainFamilyName;

  const SubFamilyListScreen({
    super.key,
    required this.mainFamilyDocId,
    required this.mainFamilyId,
    required this.mainFamilyName,
  });

  @override
  State<SubFamilyListScreen> createState() => _SubFamilyListScreenState();
}

class _SubFamilyListScreenState extends State<SubFamilyListScreen> {
  final SubFamilyService _subFamilyService = SubFamilyService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mainFamilyName} - Sub Families'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSubFamilyScreen(
                    mainFamilyDocId: widget.mainFamilyDocId,
                    mainFamilyId: widget.mainFamilyId,
                    mainFamilyName: widget.mainFamilyName,
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
                hintText: 'Search sub-families...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SubFamilyModel>>(
              stream: _subFamilyService.streamSubFamilies(
                widget.mainFamilyDocId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (snapshot.data!.isEmpty) {
                  return const Center(child: Text('No sub-families found'));
                }

                final subFamilies = snapshot.data!.where((subFamily) {
                  final name = subFamily.subFamilyName.toLowerCase();
                  final head = subFamily.headOfFamily.toLowerCase();
                  final searchLower = _searchQuery.toLowerCase();
                  return name.contains(searchLower) ||
                      head.contains(searchLower);
                }).toList();

                if (subFamilies.isEmpty) {
                  return const Center(
                    child: Text('No sub-families match your search'),
                  );
                }

                return ListView.builder(
                  itemCount: subFamilies.length,
                  itemBuilder: (context, index) {
                    final subFamily = subFamilies[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      elevation: 3,
                      color: subFamily.isActive
                          ? Colors.white
                          : Colors.grey.shade200,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemberListScreen(
                                familyDocId: widget.mainFamilyDocId,
                                familyName: subFamily.subFamilyName,
                                subFamilyDocId: subFamily.id,
                              ),
                            ),
                          );
                        },
                        onLongPress: () async {
                          // Show edit/delete options
                          final result = await showModalBottomSheet<String>(
                            context: context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  title: const Text('Edit Sub Family'),
                                  onTap: () => Navigator.pop(context, 'edit'),
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: const Text('Delete Sub Family'),
                                  onTap: () => Navigator.pop(context, 'delete'),
                                ),
                                ListTile(
                                  leading: Icon(
                                    subFamily.isActive
                                        ? Icons.block
                                        : Icons.check_circle,
                                    color: subFamily.isActive
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                  title: Text(
                                    subFamily.isActive
                                        ? 'Deactivate'
                                        : 'Activate',
                                  ),
                                  onTap: () => Navigator.pop(context, 'toggle'),
                                ),
                              ],
                            ),
                          );

                          if (result == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditSubFamilyScreen(
                                  subFamily: subFamily,
                                  mainFamilyDocId: widget.mainFamilyDocId,
                                ),
                              ),
                            );
                          } else if (result == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Sub Family'),
                                content: const Text(
                                  'Are you sure you want to delete this sub family and all its members?',
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
                              await _subFamilyService.deleteSubFamily(
                                mainFamilyDocId: widget.mainFamilyDocId,
                                subFamilyDocId: subFamily.id,
                              );
                            }
                          } else if (result == 'toggle') {
                            await _subFamilyService.toggleSubFamilyStatus(
                              mainFamilyDocId: widget.mainFamilyDocId,
                              subFamilyDocId: subFamily.id,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade900,
                                ),
                                child: const Icon(
                                  Icons.family_restroom,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Sub Family Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    Text(
                                      subFamily.subFamilyName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: subFamily.isActive
                                            ? Colors.black87
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Head of Family
                                    Text(
                                      'Head: ${subFamily.headOfFamily}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: subFamily.isActive
                                            ? Colors.black54
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Member Count
                                    Text(
                                      '${subFamily.memberCount} members',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status Indicator
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: subFamily.isActive
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
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
              builder: (_) => AddSubFamilyScreen(
                mainFamilyDocId: widget.mainFamilyDocId,
                mainFamilyId: widget.mainFamilyId,
                mainFamilyName: widget.mainFamilyName,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Add Sub Family Screen
class AddSubFamilyScreen extends StatefulWidget {
  final String mainFamilyDocId;
  final String mainFamilyId;
  final String mainFamilyName;

  const AddSubFamilyScreen({
    super.key,
    required this.mainFamilyDocId,
    required this.mainFamilyId,
    required this.mainFamilyName,
  });

  @override
  State<AddSubFamilyScreen> createState() => _AddSubFamilyScreenState();
}

class _AddSubFamilyScreenState extends State<AddSubFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subFamilyNameCtrl = TextEditingController();
  final _headOfFamilyCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _subFamilyNameCtrl.dispose();
    _headOfFamilyCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await SubFamilyService().addSubFamily(
        mainFamilyDocId: widget.mainFamilyDocId,
        mainFamilyId: widget.mainFamilyId,
        mainFamilyName: widget.mainFamilyName,
        subFamilyName: _subFamilyNameCtrl.text.trim(),
        headOfFamily: _headOfFamilyCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding sub family: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sub Family'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _subFamilyNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sub Family Name *',
                      hintText: 'e.g., Sharma Family',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _headOfFamilyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Head of Family *',
                      hintText: 'e.g., Rajesh Sharma',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description about this sub family',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Add Sub Family'),
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Adding sub family...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Edit Sub Family Screen
class EditSubFamilyScreen extends StatefulWidget {
  final SubFamilyModel subFamily;
  final String mainFamilyDocId;

  const EditSubFamilyScreen({
    super.key,
    required this.subFamily,
    required this.mainFamilyDocId,
  });

  @override
  State<EditSubFamilyScreen> createState() => _EditSubFamilyScreenState();
}

class _EditSubFamilyScreenState extends State<EditSubFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subFamilyNameCtrl = TextEditingController();
  final _headOfFamilyCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _subFamilyNameCtrl.text = widget.subFamily.subFamilyName;
    _headOfFamilyCtrl.text = widget.subFamily.headOfFamily;
    _descriptionCtrl.text = widget.subFamily.description;
  }

  @override
  void dispose() {
    _subFamilyNameCtrl.dispose();
    _headOfFamilyCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await SubFamilyService().updateSubFamily(
        mainFamilyDocId: widget.mainFamilyDocId,
        subFamilyDocId: widget.subFamily.id,
        subFamilyName: _subFamilyNameCtrl.text.trim(),
        headOfFamily: _headOfFamilyCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating sub family: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Sub Family'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _subFamilyNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sub Family Name *',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _headOfFamilyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Head of Family *',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Update Sub Family'),
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Updating sub family...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
