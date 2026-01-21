// lib/screens/admin/notification_center_screen.dart

import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/family_service.dart';
import '../../services/fcm_service.dart';
import '../../services/session_manager.dart';
import '../../models/notification_model.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService();
  final FamilyService _familyService = FamilyService();
  
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  
  String _targetType = 'all'; // all | family
  String? _selectedFamilyDocId;
  String? _currentUserRole;
  bool _loading = false;
  bool _sendPush = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await SessionManager.getRole();
    setState(() => _currentUserRole = role);
  }

  Future<void> _sendNotification() async {
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and message')),
      );
      return;
    }

    if (_targetType == 'family' && _selectedFamilyDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target family')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _notificationService.createNotification(
        title: _titleCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        type: 'announcement',
        targetType: _targetType,
        targetId: _targetType == 'family' ? _selectedFamilyDocId : null,
        createdBy: _currentUserRole ?? 'admin',
      );

      // --- NEW: Trigger Push Notification if enabled ---
      if (_sendPush) {
        await FcmService.sendPushToTopic(
          title: _titleCtrl.text.trim(),
          body: _messageCtrl.text.trim(),
          topic: _targetType == 'all' ? 'all' : 'family_$_selectedFamilyDocId',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully!')),
        );
        _titleCtrl.clear();
        _messageCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Compose Message'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Important Announcement',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Type your message here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _targetType,
                      decoration: const InputDecoration(
                        labelText: 'Target Audience',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Members')),
                        DropdownMenuItem(value: 'family', child: Text('Specific Family')),
                      ],
                      onChanged: (val) => setState(() {
                        _targetType = val!;
                        if (_targetType == 'all') _selectedFamilyDocId = null;
                      }),
                    ),
                    if (_targetType == 'family') ...[
                      const SizedBox(height: 16),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _familyService.streamFamilies(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final families = snapshot.data!;
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedFamilyDocId,
                            decoration: const InputDecoration(
                              labelText: 'Select Family',
                              border: OutlineInputBorder(),
                            ),
                            items: families.map((f) {
                              return DropdownMenuItem(
                                value: f['docId'] as String,
                                child: Text(f['familyName'] as String),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedFamilyDocId = val),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Send Push Notification'),
                      subtitle: const Text('Alert users even if the app is closed'),
                      value: _sendPush,
                      onChanged: (val) => setState(() => _sendPush = val),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _sendNotification,
                      icon: _loading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(_loading ? 'Sending...' : 'Send Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Recent History'),
            StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.streamAllNotifications(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final notifications = snapshot.data!;
                if (notifications.isEmpty) return const Center(child: Text('No previous notifications'));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: n.type == 'event' ? Colors.orange : Colors.blue.shade900,
                          child: Icon(
                            n.type == 'event' ? Icons.event : Icons.announcement,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'To: ${n.targetType.toUpperCase()}\n${n.createdAt.day}/${n.createdAt.month} at ${n.createdAt.hour}:${n.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _notificationService.deleteNotification(n.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      ),
    );
  }
}
