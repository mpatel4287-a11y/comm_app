// lib/models/member_model.dart

class MemberModel {
  final String id;

  final String familyId;

  final String fullName;
  final String fatherName;
  final String motherName;

  final String birthDate; // dd/MM/yyyy
  final int age; // auto calculated

  final String gender;
  final String phone;
  final String address;

  final List<Map<String, String>> firms; // multiple firms
  final List<String> tags; // admin-only

  final DateTime createdAt;

  MemberModel({
    required this.id,
    required this.familyId,
    required this.fullName,
    required this.fatherName,
    required this.motherName,
    required this.birthDate,
    required this.age,
    required this.gender,
    required this.phone,
    required this.address,
    required this.firms,
    required this.tags,
    required this.createdAt,
  });

  // ---------------- AGE CALCULATION ----------------
  static int calculateAge(String birthDate) {
    final parts = birthDate.split('/');
    if (parts.length != 3) return 0;

    final day = int.tryParse(parts[0]) ?? 1;
    final month = int.tryParse(parts[1]) ?? 1;
    final year = int.tryParse(parts[2]) ?? 2000;

    final dob = DateTime(year, month, day);
    final today = DateTime.now();

    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  // ---------------- TO MAP ----------------
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'familyId': familyId,
      'fullName': fullName,
      'fatherName': fatherName,
      'motherName': motherName,
      'birthDate': birthDate,
      'age': age,
      'gender': gender,
      'phone': phone,
      'address': address,
      'createdAt': createdAt,
    };

    if (firms.isNotEmpty) map['firms'] = firms;
    if (tags.isNotEmpty) map['tags'] = tags;

    return map;
  }

  // ---------------- FROM MAP ----------------
  factory MemberModel.fromMap(String id, Map<String, dynamic> data) {
    return MemberModel(
      id: id,
      familyId: data['familyId'] ?? '',
      fullName: data['fullName'] ?? '',
      fatherName: data['fatherName'] ?? '',
      motherName: data['motherName'] ?? '',
      birthDate: data['birthDate'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      firms: (data['firms'] as List<dynamic>? ?? [])
          .map((e) => Map<String, String>.from(e))
          .toList(),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as dynamic).toDate(),
    );
  }
}
