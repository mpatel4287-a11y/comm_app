// lib/models/event_model.dart

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String time;
  final String type;
  final String createdBy;
  final String familyDocId;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.location = '',
    required this.date,
    this.time = '',
    this.type = 'general',
    required this.createdBy,
    this.familyDocId = '',
    required this.createdAt,
  });

  // ---------------- TO MAP ----------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date': date,
      'time': time,
      'type': type,
      'createdBy': createdBy,
      'familyDocId': familyDocId,
      'createdAt': createdAt,
    };
  }

  // ---------------- FROM MAP ----------------
  factory EventModel.fromMap(String id, Map<String, dynamic> data) {
    return EventModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
      time: data['time'] ?? '',
      type: data['type'] ?? 'general',
      createdBy: data['createdBy'] ?? '',
      familyDocId: data['familyDocId'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
