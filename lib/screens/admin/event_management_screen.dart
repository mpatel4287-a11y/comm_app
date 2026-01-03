// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../../../services/event_service.dart';
import '../../../services/session_manager.dart';
import '../../../models/event_model.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final EventService _eventService = EventService();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _selectedType = 'general';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _familyDocId;

  @override
  void initState() {
    super.initState();
    _loadFamilyDocId();
  }

  Future<void> _loadFamilyDocId() async {
    final docId = await SessionManager.getFamilyDocId();
    setState(() => _familyDocId = docId);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
      body: StreamBuilder<List<EventModel>>(
        stream: _eventService.streamAllEvents(),
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
            Text('${_formatDate(event.date)} • ${_formatTime(event.date)}'),
            if (event.location.isNotEmpty)
              Text(event.location, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showEditDialog(event);
            } else if (value == 'attendance') {
              Navigator.pushNamed(
                context,
                '/admin/eventAttendance',
                arguments: event.id,
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
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'attendance', child: Text('Attendance')),
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
    _titleCtrl.clear();
    _descriptionCtrl.clear();
    _locationCtrl.clear();
    _selectedType = 'general';
    _selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['general', 'puja', 'function', 'meeting', 'yar']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date & Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatDate(_selectedDate)} • ${_formatTime(_selectedDate)}',
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleCtrl.text.trim().isEmpty) return;

              await _eventService.createEvent(
                title: _titleCtrl.text.trim(),
                description: _descriptionCtrl.text.trim(),
                location: _locationCtrl.text.trim(),
                date: _selectedDate,
                type: _selectedType,
                createdBy: 'admin',
                familyDocId: _familyDocId ?? '',
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(EventModel event) {
    _titleCtrl.text = event.title;
    _descriptionCtrl.text = event.description;
    _locationCtrl.text = event.location;
    _selectedType = event.type;
    _selectedDate = event.date;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['general', 'puja', 'function', 'meeting', 'yar']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date & Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatDate(_selectedDate)} • ${_formatTime(_selectedDate)}',
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleCtrl.text.trim().isEmpty) return;
              await _eventService.updateEvent(
                eventId: event.id,
                title: _titleCtrl.text.trim(),
                description: _descriptionCtrl.text.trim(),
                location: _locationCtrl.text.trim(),
                date: _selectedDate,
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
