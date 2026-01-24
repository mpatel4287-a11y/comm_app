// lib/models/notification_model.dart

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // announcement | event | alert
  final String targetType; // all | family | member
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.targetType,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
    required this.createdBy,
    this.expiresAt,
  });

  // ---------------- TO MAP ----------------
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'targetType': targetType,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'expiresAt': expiresAt,
    };
  }

  // ---------------- FROM MAP ----------------
  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'announcement',
      targetType: data['targetType'] ?? 'all',
      targetId: data['targetId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      expiresAt: (data['expiresAt'] as dynamic)?.toDate(),
    );
  }
}
