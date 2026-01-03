// lib/models/attendance_model.dart

class AttendanceModel {
  final String id;
  final String eventId;
  final String memberId;
  final String memberName;
  final String status; // present | absent
  final DateTime markedAt;
  final String markedBy;

  AttendanceModel({
    required this.id,
    required this.eventId,
    required this.memberId,
    required this.memberName,
    required this.status,
    required this.markedAt,
    required this.markedBy,
  });

  // ---------------- TO MAP ----------------
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'memberId': memberId,
      'memberName': memberName,
      'status': status,
      'markedAt': markedAt,
      'markedBy': markedBy,
    };
  }

  // ---------------- FROM MAP ----------------
  factory AttendanceModel.fromMap(String id, Map<String, dynamic> data) {
    return AttendanceModel(
      id: id,
      eventId: data['eventId'] ?? '',
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      status: data['status'] ?? 'absent',
      markedAt: (data['markedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      markedBy: data['markedBy'] ?? '',
    );
  }
}
