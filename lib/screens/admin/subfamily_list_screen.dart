// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import '../../models/subfamily_model.dart';
import '../../services/subfamily_service.dart';
import '../../services/family_service.dart';
import '../../services/member_service.dart'; // Added MemberService
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search sub-families...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
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

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: subFamilies.length,
                  itemBuilder: (context, index) {
                    final subFamily = subFamilies[index];
                    final isActive = subFamily.isActive;

                    return InkWell(
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
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: isActive ? Colors.white : Colors.grey.shade200,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HEADER
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isActive
                                        ? Colors.blue.shade900
                                        : Colors.grey,
                                    child: const Icon(
                                      Icons.groups_2_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'INACTIVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // SUB FAMILY NAME
                              Text(
                                subFamily.subFamilyName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.black
                                      : Colors.grey.shade700,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // HEAD OF FAMILY
                              Text(
                                subFamily.headOfFamily,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),

                              // REAL-TIME MEMBER COUNT
                              FutureBuilder<int>(
                                future: MemberService().getSubFamilyMemberCount(
                                  widget.mainFamilyDocId,
                                  subFamily.id,
                                ),
                                builder: (context, countSnap) {
                                  final count = countSnap.data ?? 0;
                                  return Text(
                                    '$count members',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),

                              const Spacer(),

                              // ACTIONS
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // EDIT
                                  _buildCompactAction(
                                    icon: Icons.edit,
                                    color: Colors.blue,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditSubFamilyScreen(
                                            subFamily: subFamily,
                                            mainFamilyDocId:
                                                widget.mainFamilyDocId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // TOGGLE STATUS
                                  _buildCompactAction(
                                    icon: isActive
                                        ? Icons.check_circle
                                        : Icons.block,
                                    color: isActive
                                        ? Colors.green
                                        : Colors.grey,
                                    onTap: () async {
                                      await _subFamilyService
                                          .toggleSubFamilyStatus(
                                        mainFamilyDocId:
                                            widget.mainFamilyDocId,
                                        subFamilyDocId: subFamily.id,
                                      );
                                    },
                                  ),

                                  // DELETE
                                  _buildCompactAction(
                                    icon: Icons.delete,
                                    color: Colors.red,
                                    onTap: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text(
                                              'Delete Sub Family'),
                                          content: const Text(
                                            'Are you sure? This deletes all members.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(c, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (ok == true) {
                                        await _subFamilyService
                                            .deleteSubFamily(
                                          mainFamilyDocId:
                                              widget.mainFamilyDocId,
                                          subFamilyDocId: subFamily.id,
                                        );
                                      }
                                    },
                                  ),
                                ],
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

  Widget _buildCompactAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
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
