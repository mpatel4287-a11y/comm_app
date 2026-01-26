// lib/screens/user/event_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';
import '../../services/member_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/animation_utils.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final MemberService _memberService = MemberService();
  String? _currentMemberId;
  String? _currentMemberName;
  String? _familyDocId;
  String? _subFamilyDocId;
  String? _familyName;
  int _totalAttendance = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAttendanceCount();
  }

  Future<void> _loadUserData() async {
    final memberId = await SessionManager.getMemberId();
    final familyDocId = await SessionManager.getFamilyDocId();
    final subFamilyDocId = await SessionManager.getSubFamilyDocId();
    final familyName = await SessionManager.getFamilyName();
    
    if (memberId != null) {
      final allMembers = await _memberService.getAllMembers();
      final member = allMembers.firstWhere(
        (m) => m.id == memberId,
        orElse: () => allMembers.firstWhere(
          (m) => m.mid == memberId,
          orElse: () => throw Exception('Member not found'),
        ),
      );
      
      setState(() {
        _currentMemberId = memberId;
        _currentMemberName = member.fullName;
        _familyDocId = familyDocId ?? member.familyDocId;
        _subFamilyDocId = subFamilyDocId ?? member.subFamilyDocId;
        _familyName = familyName ?? member.familyName;
      });
    }
  }

  Future<void> _loadAttendanceCount() async {
    final count = await _attendanceService.getAttendanceCount(widget.event.id);
    if (mounted) {
      setState(() {
        _totalAttendance = count;
      });
    }
  }

  Future<void> _markAttendance(String type) async {
    if (_currentMemberId == null || _currentMemberName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to mark attendance')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String entityId = '';
      String entityName = '';

      if (type == 'family') {
        entityId = _familyDocId ?? '';
        entityName = _familyName ?? 'Family';
      } else if (type == 'subfamily') {
        entityId = '$_familyDocId/$_subFamilyDocId';
        entityName = 'Sub-Family';
      } else if (type == 'firm') {
        // Show firm selection dialog
        final firm = await _showFirmSelectionDialog();
        if (firm == null) {
          setState(() => _loading = false);
          return;
        }
        entityId = firm;
        entityName = firm;
      }

      await _attendanceService.markAttendance(
        eventId: widget.event.id,
        markedBy: _currentMemberId!,
        markedByName: _currentMemberName!,
        attendanceType: type,
        entityId: entityId,
        entityName: entityName,
      );

      await _loadAttendanceCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance marked successfully for $entityName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  Future<String?> _showFirmSelectionDialog() async {
    final allMembers = await _memberService.getAllMembers();
    final currentMember = allMembers.firstWhere(
      (m) => m.id == _currentMemberId,
      orElse: () => throw Exception('Member not found'),
    );

    if (currentMember.firms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No firms found for your account')),
      );
      return null;
    }

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Firm'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currentMember.firms.length,
            itemBuilder: (context, index) {
              final firm = currentMember.firms[index];
              return ListTile(
                leading: const Icon(Icons.business),
                title: Text(firm['name'] ?? ''),
                onTap: () => Navigator.pop(context, firm['name']),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPast = widget.event.date.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        backgroundColor: Colors.blue.shade900,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Header
                  FadeInAnimation(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.event,
                                    color: Colors.blue.shade900,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.event.title,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(widget.event.date),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (widget.event.time.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildInfoRow(Icons.access_time, widget.event.time),
                            ],
                            if (widget.event.location.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.location_on, widget.event.location),
                            ],
                            if (widget.event.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(widget.event.description),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Attendance Count
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: Colors.green.shade700,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Attendance',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '$_totalAttendance',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (!isPast) ...[
                    const SizedBox(height: 24),

                    // Mark Attendance Section
                    FadeInAnimation(
                      delay: const Duration(milliseconds: 200),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mark Attendance',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildAttendanceButton(
                                'Mark for Family',
                                Icons.family_restroom,
                                Colors.blue,
                                () => _markAttendance('family'),
                              ),
                              const SizedBox(height: 12),
                              _buildAttendanceButton(
                                'Mark for Sub-Family',
                                Icons.home_work,
                                Colors.purple,
                                () => _markAttendance('subfamily'),
                              ),
                              const SizedBox(height: 12),
                              _buildAttendanceButton(
                                'Mark for Firm',
                                Icons.business,
                                Colors.orange,
                                () => _markAttendance('firm'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Attendance List
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 300),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance Records',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<List<AttendanceModel>>(
                              stream: _attendanceService.getEventAttendance(widget.event.id),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final attendanceList = snapshot.data!;
                                if (attendanceList.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.people_outline,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No attendance marked yet',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: attendanceList.length,
                                  itemBuilder: (context, index) {
                                    final attendance = attendanceList[index];
                                    return SlideInAnimation(
                                      delay: Duration(milliseconds: 50 * index),
                                      child: Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: _getTypeColor(attendance.attendanceType),
                                            child: Icon(
                                              _getTypeIcon(attendance.attendanceType),
                                              color: Colors.white,
                                            ),
                                          ),
                                          title: Text(attendance.entityName),
                                          subtitle: Text(
                                            'Marked by ${attendance.markedByName}',
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${attendance.memberCount}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                attendance.memberCount == 1
                                                    ? 'member'
                                                    : 'members',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'family':
        return Colors.blue;
      case 'subfamily':
        return Colors.purple;
      case 'firm':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'family':
        return Icons.family_restroom;
      case 'subfamily':
        return Icons.home_work;
      case 'firm':
        return Icons.business;
      default:
        return Icons.people;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
