// lib/models/group_model.dart

class GroupModel {
  final String id;
  final String familyDocId;
  final String name;
  final String description;
  final String type;
  final List<String> memberIds;
  final List<String> managerMids;
  final String createdBy;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.familyDocId,
    required this.name,
    this.description = '',
    this.type = 'community',
    this.memberIds = const [],
    this.managerMids = const [],
    required this.createdBy,
    required this.createdAt,
  });

  // ---------------- TO MAP ----------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyDocId': familyDocId,
      'name': name,
      'description': description,
      'type': type,
      'memberIds': memberIds,
      'managerMids': managerMids,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  // ---------------- FROM MAP ----------------
  factory GroupModel.fromMap(String id, Map<String, dynamic> data) {
    return GroupModel(
      id: id,
      familyDocId: data['familyDocId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'community',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      managerMids: List<String>.from(data['managerMids'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  // ---------------- COPY WITH ----------------
  GroupModel copyWith({
    String? name,
    String? description,
    String? type,
    List<String>? memberIds,
    List<String>? managerMids,
  }) {
    return GroupModel(
      id: id,
      familyDocId: familyDocId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      memberIds: memberIds ?? this.memberIds,
      managerMids: managerMids ?? this.managerMids,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
