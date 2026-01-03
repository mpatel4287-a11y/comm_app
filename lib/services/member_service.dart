// lib/services/member_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class MemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------- ADD MEMBER ----------------
  Future<void> addMember({
    required String familyId,
    required String fullName,
    required String fatherName,
    required String motherName,
    required String birthDate,
    required String gender,
    required String phone,
    required String address,
    required List<Map<String, String>> firms,
    required List<String> tags, // admin only
  }) async {
    final age = MemberModel.calculateAge(birthDate);

    final cleanedTags = tags
        .where((t) => t.trim().isNotEmpty)
        .map((t) => t.trim().substring(0, t.length > 15 ? 15 : t.length))
        .toList();

    final memberRef = _firestore.collection('members').doc();

    final member = MemberModel(
      id: memberRef.id,
      familyId: familyId,
      fullName: fullName.trim(),
      fatherName: fatherName.trim(),
      motherName: motherName.trim(),
      birthDate: birthDate.trim(),
      age: age,
      gender: gender.trim(),
      phone: phone.trim(),
      address: address.trim(),
      firms: firms.where((f) => f['firmName']!.isNotEmpty).toList(),
      tags: cleanedTags,
      createdAt: DateTime.now(),
    );

    await memberRef.set(member.toMap());
  }

  // ---------------- UPDATE MEMBER ----------------
  Future<void> updateMember({
    required String memberId,
    required Map<String, dynamic> updates,
    bool recalcAge = false,
  }) async {
    if (recalcAge && updates.containsKey('birthDate')) {
      updates['age'] = MemberModel.calculateAge(updates['birthDate'] as String);
    }

    if (updates.containsKey('tags')) {
      final List<String> tags = List<String>.from(updates['tags']);
      updates['tags'] = tags
          .where((t) => t.trim().isNotEmpty)
          .map((t) => t.trim().substring(0, t.length > 15 ? 15 : t.length))
          .toList();
    }

    await _firestore.collection('members').doc(memberId).update(updates);
  }

  // ---------------- GET MEMBERS BY FAMILY ----------------
  Stream<List<MemberModel>> streamFamilyMembers(String familyId) {
    return _firestore
        .collection('members')
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MemberModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ---------------- TAG FILTER ----------------
  Stream<List<MemberModel>> filterByTag(String tag) {
    return _firestore
        .collection('members')
        .where('tags', arrayContains: tag)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MemberModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}
