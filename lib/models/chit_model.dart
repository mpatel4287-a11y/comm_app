// lib/models/chit_model.dart

class ChitModel {
  final String id;
  final String title;
  final String amount;
  final String tenure;
  final String? firmId;
  final String? firmName;
  final List<String> visibleToGroups;
  final List<String> visibleToMembers;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChitModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.tenure,
    this.firmId,
    this.firmName,
    this.visibleToGroups = const [],
    this.visibleToMembers = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'tenure': tenure,
      'firmId': firmId,
      'firmName': firmName,
      'visibleToGroups': visibleToGroups,
      'visibleToMembers': visibleToMembers,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChitModel.fromMap(String id, Map<String, dynamic> map) {
    return ChitModel(
      id: id,
      title: map['title'] ?? '',
      amount: map['amount'] ?? '',
      tenure: map['tenure'] ?? '',
      firmId: map['firmId'],
      firmName: map['firmName'],
      visibleToGroups: List<String>.from(map['visibleToGroups'] ?? []),
      visibleToMembers: List<String>.from(map['visibleToMembers'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
