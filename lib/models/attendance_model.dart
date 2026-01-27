// lib/models/attendance_model.dart

class AttendanceModel {
  final String id;
  final String eventId;
  final String markedBy; // Member ID who marked attendance
  final String markedByName; // Name of person who marked
  final String attendanceType; // 'family' | 'subfamily' | 'firm'
  final String entityId; // familyDocId | subFamilyDocId | firmName
  final String entityName; // Display name
  final List<String> memberIds; // List of member IDs included in this attendance
  final int memberCount; // Total count
  final DateTime markedAt;
  final bool isCustomCount;

  AttendanceModel({
    required this.id,
    required this.eventId,
    required this.markedBy,
    required this.markedByName,
    required this.attendanceType,
    required this.entityId,
    required this.entityName,
    required this.memberIds,
    required this.memberCount,
    required this.markedAt,
    this.isCustomCount = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'markedBy': markedBy,
      'markedByName': markedByName,
      'attendanceType': attendanceType,
      'entityId': entityId,
      'entityName': entityName,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'markedAt': markedAt,
      'isCustomCount': isCustomCount,
    };
  }

  factory AttendanceModel.fromMap(String id, Map<String, dynamic> data) {
    return AttendanceModel(
      id: id,
      eventId: data['eventId'] ?? '',
      markedBy: data['markedBy'] ?? '',
      markedByName: data['markedByName'] ?? '',
      attendanceType: data['attendanceType'] ?? 'family',
      entityId: data['entityId'] ?? '',
      entityName: data['entityName'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      markedAt: (data['markedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      isCustomCount: data['isCustomCount'] ?? false,
    );
  }
}
