import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/session_manager.dart';
import '../../services/chit_service.dart';
import '../../services/firm_service.dart';
import '../../models/chit_model.dart';
import '../../widgets/animation_utils.dart';

class ChitsScreen extends StatefulWidget {
  const ChitsScreen({super.key});

  @override
  State<ChitsScreen> createState() => _ChitsScreenState();
}

class _ChitsScreenState extends State<ChitsScreen> {
  final ChitService _chitService = ChitService();
  final FirmService _firmService = FirmService();
  
  bool _isAdminOrManager = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final role = await SessionManager.getRole();
    final isAdmin = await SessionManager.getIsAdmin() ?? false;
    // We should ideally fetch current user gender to filter visibility if they are not admin/manager
    // For now, we'll assume we have it from session or fetch later.
    
    if (mounted) {
      setState(() {
        _isAdminOrManager = isAdmin || 
                           role?.toLowerCase() == 'manager' || 
                           role?.toLowerCase() == 'admin';
        _loading = false;
      });
    }
  }

  void _showSchemeDialog([ChitModel? chit]) async {
    final titleCtrl = TextEditingController(text: chit?.title ?? '');
    final amountCtrl = TextEditingController(text: chit?.amount ?? '');
    final tenureCtrl = TextEditingController(text: chit?.tenure ?? '');
    List<String> selectedGroups = List.from(chit?.visibleToGroups ?? []);
    
    // Load firms for selection
    final firms = await _firmService.getAllFirms();
    String? selectedFirmId = chit?.firmId;
    String? selectedFirmName = chit?.firmName;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(chit == null ? 'Create New Scheme' : 'Edit Scheme'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Scheme Title', hintText: 'e.g. Monthly Gold Chit'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount / Installment', hintText: 'e.g. ₹2,000 / month'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tenureCtrl,
                  decoration: const InputDecoration(labelText: 'Tenure', hintText: 'e.g. 12 Months'),
                ),
                const SizedBox(height: 20),
                
                // Firm Selection
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Link to Firm (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedFirmId,
                  isExpanded: true,
                  hint: const Text('Select Firm'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Firm (General)')),
                    ...firms.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
                  ],
                  onChanged: (val) {
                    setDialogState(() {
                      selectedFirmId = val;
                      selectedFirmName = val == null ? null : firms.firstWhere((f) => f.id == val).name;
                    });
                  },
                ),
                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Visibility (Select Groups)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Samaj', 'Yuvak Mandal', 'Mahila Mandal', 'Business Group'].map((group) {
                    final isSelected = selectedGroups.contains(group);
                    return FilterChip(
                      label: Text(group),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedGroups.add(group);
                          } else {
                            selectedGroups.remove(group);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Target Particular Members', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter Member IDs (comma separated)',
                    prefixIcon: Icon(Icons.person_search, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                
                if (chit == null) {
                  await _chitService.createChit(ChitModel(
                    id: '',
                    title: titleCtrl.text,
                    amount: amountCtrl.text,
                    tenure: tenureCtrl.text,
                    firmId: selectedFirmId,
                    firmName: selectedFirmName,
                    visibleToGroups: selectedGroups,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                } else {
                  await _chitService.updateChit(chit.id, {
                    'title': titleCtrl.text,
                    'amount': amountCtrl.text,
                    'tenure': tenureCtrl.text,
                    'firmId': selectedFirmId,
                    'firmName': selectedFirmName,
                    'visibleToGroups': selectedGroups,
                  });
                }
                if (mounted) Navigator.pop(context);
              },
              child: Text(chit == null ? 'Create' : 'Save & Notify'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ChitModel chit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scheme'),
        content: Text('Are you sure you want to delete "${chit.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _chitService.deleteChit(chit.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('chits')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ChitModel>>(
        stream: _chitService.streamChits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chits = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(lang, theme),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Schemes',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_isAdminOrManager)
                      const Badge(
                        label: Text('ADMIN SYNC ACTIVE'),
                        backgroundColor: Colors.green,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (chits.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.money_off, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No active schemes found', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                ...chits.map((chit) => _buildSchemeItem(context, chit, lang, theme)),
              ],
            ),
          );
        }
      ),
      floatingActionButton: _isAdminOrManager
          ? FloatingActionButton.extended(
              onPressed: () => _showSchemeDialog(),
              backgroundColor: theme.colorScheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Scheme', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildInfoCard(LanguageService lang, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          const Text(
            'Community Chit Fund',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isAdminOrManager 
              ? 'Changes are now synced with Firestore. Updating an amount will notify members of the linked firm.'
              : 'Secure group savings and lending for community members. View-only access granted.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeItem(
    BuildContext context,
    ChitModel chit,
    LanguageService lang,
    ThemeData theme,
  ) {
    return SlideInAnimation(
      beginOffset: const Offset(0, 0.1),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.monetization_on, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chit.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${chit.amount} • ${chit.tenure}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        if (chit.firmName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Linked Firm: ${chit.firmName}',
                              style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isAdminOrManager) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _showSchemeDialog(chit),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(chit),
                    ),
                  ],
                ],
              ),
              if (chit.visibleToGroups.isNotEmpty) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 14, color: Colors.teal.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Visible to: ${chit.visibleToGroups.join(", ")}',
                        style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
