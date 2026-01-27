// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../../../services/event_service.dart';
import '../../../services/session_manager.dart';
import '../../../models/event_model.dart';
import '../user/event_detail_screen.dart';
import 'add_edit_event_screen.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final EventService _eventService = EventService();
  String? _familyDocId;
  String? _role;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFamilyDocId();
  }

  Future<void> _loadFamilyDocId() async {
    final docId = await SessionManager.getFamilyDocId();
    final role = await SessionManager.getRole();
    setState(() {
      _familyDocId = docId;
      _role = role;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_familyDocId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Stack(
        children: [
          StreamBuilder<List<EventModel>>(
            stream: _eventService.streamAllEvents(userRole: _role),
            builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;
          final now = DateTime.now();

          // Separate upcoming and past events
          final upcoming = events.where((e) => e.date.isAfter(now)).toList();
          final past = events.where((e) => e.date.isBefore(now)).toList();

          if (events.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No events found'),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (upcoming.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Upcoming Events',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ...upcoming.map((e) => _buildEventCard(e)),
                const Divider(),
              ],
              if (past.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Past Events',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ...past.map((e) => _buildEventCard(e)),
              ],
            ],
          );
            },
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isPast = event.date.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isPast ? Colors.grey.shade100 : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPast ? Colors.grey : Colors.blue.shade900,
          child: Icon(_getEventIcon(event.type), color: Colors.white),
        ),
        title: Text(
          event.title,
          style: TextStyle(color: isPast ? Colors.grey.shade700 : Colors.black),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_formatDate(event.date)} • ${event.time.isNotEmpty ? event.time : _formatTime(event.date)}'),
            if (event.location.isNotEmpty)
              Text(event.location, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showEditDialog(event);
            } else if (value == 'reminder') {
              setState(() => _loading = true);
              try {
                await _eventService.sendEventReminder(
                  event: event,
                  triggeredBy: _role ?? 'admin',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder sent to all members')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              } finally {
                setState(() => _loading = false);
              }
            } else if (value == 'view') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(event: event),
                ),
              );
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Event'),
                  content: const Text(
                    'Are you sure you want to delete this event?',
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
                await _eventService.deleteEvent(event.id);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'reminder', child: Text('Send Reminder')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'puja':
        return Icons.holiday_village;
      case 'function':
        return Icons.celebration;
      case 'meeting':
        return Icons.meeting_room;
      case 'yar':
        return Icons.group;
      default:
        return Icons.event;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditEventScreen()),
    );
  }

  void _showEditDialog(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditEventScreen(event: event)),
    );
  }

}
