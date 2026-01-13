// lib/models/member_model.dart

class MemberModel {
  // Identity
  final String id;
  final String mid; // unique member ID (format: F{XX}-S{XX}-{XXX})
  final String familyDocId;
  final String subFamilyDocId; // Reference to sub-family document
  final String subFamilyId; // 2-digit sub-family ID (e.g., "01", "02")
  final String familyId; // 2-digit family prefix (e.g., "01", "02")
  final String familyName;

  // Personal
  final String fullName;
  final String surname;
  final String fatherName;
  final String motherName;
  final String gotra;
  final String birthDate; // dd/MM/yyyy
  final int age; // auto calculated
  final String bloodGroup;
  final String marriageStatus; // married | unmarried
  final String nativeHome;

  // Contact
  final String phone;
  final String address;
  final String googleMapLink;

  // Firms (Multiple)
  final List<Map<String, String>> firms; // [{name, phone, mapLink}]

  // Social
  final String whatsapp;
  final String instagram;
  final String facebook;

  // Media
  final String photoUrl;

  // Meta
  final String role; // member | manager
  final List<String> tags; // admin only, max 15 chars
  final bool isActive;
  final String parentMid; // for family tree (parent member ID)
  final String tod; // Date of Death (dd/MM/yyyy)
  final DateTime createdAt;

  MemberModel({
    required this.id,
    required this.mid,
    required this.familyDocId,
    required this.subFamilyDocId,
    required this.subFamilyId,
    required this.familyId,
    required this.familyName,
    required this.fullName,
    required this.surname,
    required this.fatherName,
    required this.motherName,
    required this.gotra,
    required this.birthDate,
    required this.age,
    required this.bloodGroup,
    required this.marriageStatus,
    required this.nativeHome,
    required this.phone,
    required this.address,
    required this.googleMapLink,
    required this.firms,
    required this.whatsapp,
    required this.instagram,
    required this.facebook,
    required this.photoUrl,
    required this.role,
    required this.tags,
    required this.isActive,
    required this.parentMid,
    this.tod = '',
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

  // ---------------- GENERATE MID (Pattern: F{XX}-S{XX}-{XXX}) ----------------
  // Example: F13-S01-123 where:
  // - F13 = "F" + first 2 digits of family ID (e.g., family ID "132345" → "13")
  // - S01 = "S" + 2-digit subfamily number (padded with leading zero if needed)
  // - 123 = auto-generated 3-digit random member number
  static String generateMid(String familyId, String subFamilyId) {
    // Generate a random 3-digit integer between 100 and 999
    final random = DateTime.now().millisecondsSinceEpoch % 900 + 100;
    // Ensure familyId is 2 digits (use first 2 digits, or pad with leading zero)
    final shortFamilyId = familyId.length >= 2
        ? familyId.substring(0, 2)
        : familyId.padLeft(2, '0');
    // Ensure subFamilyId is 2 digits (pad with leading zero if needed)
    final formattedSubFamilyId = subFamilyId.padLeft(2, '0');
    return 'F$shortFamilyId-S$formattedSubFamilyId-$random';
  }

  // ---------------- TO MAP ----------------
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'mid': mid,
      'familyDocId': familyDocId,
      'subFamilyDocId': subFamilyDocId,
      'subFamilyId': subFamilyId,
      'familyId': familyId,
      'familyName': familyName,
      'fullName': fullName,
      'surname': surname,
      'fatherName': fatherName,
      'motherName': motherName,
      'gotra': gotra,
      'birthDate': birthDate,
      'age': age,
      'bloodGroup': bloodGroup,
      'marriageStatus': marriageStatus,
      'nativeHome': nativeHome,
      'phone': phone,
      'address': address,
      'googleMapLink': googleMapLink,
      'whatsapp': whatsapp,
      'instagram': instagram,
      'facebook': facebook,
      'photoUrl': photoUrl,
      'role': role,
      'tags': tags,
      'isActive': isActive,
      'parentMid': parentMid,
      'tod': tod,
      'createdAt': createdAt,
    };

    if (firms.isNotEmpty) map['firms'] = firms;

    return map;
  }

  // ---------------- FROM MAP ----------------
  factory MemberModel.fromMap(String id, Map<String, dynamic> data) {
    return MemberModel(
      id: id,
      mid: data['mid'] ?? '',
      familyDocId: data['familyDocId'] ?? '',
      subFamilyDocId: data['subFamilyDocId'] ?? '',
      subFamilyId: data['subFamilyId'] ?? '',
      familyId: data['familyId'] ?? '',
      familyName: data['familyName'] ?? '',
      fullName: data['fullName'] ?? '',
      surname: data['surname'] ?? '',
      fatherName: data['fatherName'] ?? '',
      motherName: data['motherName'] ?? '',
      gotra: data['gotra'] ?? '',
      birthDate: data['birthDate'] ?? '',
      age: data['age'] ?? 0,
      bloodGroup: data['bloodGroup'] ?? '',
      marriageStatus: data['marriageStatus'] ?? 'unmarried',
      nativeHome: data['nativeHome'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      googleMapLink: data['googleMapLink'] ?? '',
      firms: (data['firms'] as List<dynamic>? ?? [])
          .map((e) => Map<String, String>.from(e))
          .toList(),
      whatsapp: data['whatsapp'] ?? '',
      instagram: data['instagram'] ?? '',
      facebook: data['facebook'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      role: data['role'] ?? 'member',
      tags: List<String>.from(data['tags'] ?? []),
      isActive: data['isActive'] ?? true,
      parentMid: data['parentMid'] ?? '',
      tod: data['tod'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  // ---------------- COPY WITH ----------------
  MemberModel copyWith({
    String? id,
    String? mid,
    String? familyDocId,
    String? subFamilyDocId,
    String? subFamilyId,
    String? familyId,
    String? familyName,
    String? fullName,
    String? surname,
    String? fatherName,
    String? motherName,
    String? gotra,
    String? birthDate,
    String? bloodGroup,
    String? marriageStatus,
    String? nativeHome,
    String? phone,
    String? address,
    String? googleMapLink,
    List<Map<String, String>>? firms,
    String? whatsapp,
    String? instagram,
    String? facebook,
    String? photoUrl,
    String? role,
    List<String>? tags,
    bool? isActive,
    String? parentMid,
    String? tod,
  }) {
    return MemberModel(
      id: id ?? this.id,
      mid: mid ?? this.mid,
      familyDocId: familyDocId ?? this.familyDocId,
      subFamilyDocId: subFamilyDocId ?? this.subFamilyDocId,
      subFamilyId: subFamilyId ?? this.subFamilyId,
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      fullName: fullName ?? this.fullName,
      surname: surname ?? this.surname,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      gotra: gotra ?? this.gotra,
      birthDate: birthDate ?? this.birthDate,
      age: birthDate != null ? calculateAge(birthDate) : age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      marriageStatus: marriageStatus ?? this.marriageStatus,
      nativeHome: nativeHome ?? this.nativeHome,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      googleMapLink: googleMapLink ?? this.googleMapLink,
      firms: firms ?? this.firms,
      whatsapp: whatsapp ?? this.whatsapp,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      parentMid: parentMid ?? this.parentMid,
      tod: tod ?? this.tod,
      createdAt: createdAt,
    );
  }
}
