// lib/services/member_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class MemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get members subcollection reference for a family
  CollectionReference<Map<String, dynamic>> _getMembersCollection(
    String familyDocId,
  ) {
    return _firestore
        .collection('families')
        .doc(familyDocId)
        .collection('members');
  }

  // ---------------- ADD MEMBER ----------------
  Future<void> addMember({
    required String familyDocId,
    required String familyId,
    required String familyName,
    required String fullName,
    required String surname,
    required String fatherName,
    required String motherName,
    required String gotra,
    required String birthDate,
    required String bloodGroup,
    required String marriageStatus,
    required String nativeHome,
    required String phone,
    required String address,
    required String googleMapLink,
    required List<Map<String, String>> firms,
    required String whatsapp,
    required String instagram,
    required String facebook,
    required List<String> tags,
    required String parentMid,
  }) async {
    final age = MemberModel.calculateAge(birthDate);

    // Clean and truncate tags (max 15 chars)
    final cleanedTags = tags
        .where((t) => t.trim().isNotEmpty)
        .map((t) => t.trim().substring(0, t.length > 15 ? 15 : t.length))
        .toList();

    // Clean firms
    final cleanedFirms = firms
        .where((f) => (f['name'] ?? '').isNotEmpty)
        .map(
          (f) => {
            'name': f['name']!.trim(),
            'phone': (f['phone'] ?? '').trim(),
            'mapLink': (f['mapLink'] ?? '').trim(),
          },
        )
        .toList();

    // Create member in the family's subcollection
    final memberRef = _getMembersCollection(familyDocId).doc();

    final member = MemberModel(
      id: memberRef.id,
      mid: MemberModel.generateMid(),
      familyDocId: familyDocId,
      familyId: familyId,
      familyName: familyName,
      fullName: fullName.trim(),
      surname: surname.trim(),
      fatherName: fatherName.trim(),
      motherName: motherName.trim(),
      gotra: gotra.trim(),
      birthDate: birthDate.trim(),
      age: age,
      bloodGroup: bloodGroup.trim(),
      marriageStatus: marriageStatus,
      nativeHome: nativeHome.trim(),
      phone: phone.trim(),
      address: address.trim(),
      googleMapLink: googleMapLink.trim(),
      firms: cleanedFirms,
      whatsapp: whatsapp.trim(),
      instagram: instagram.trim(),
      facebook: facebook.trim(),
      photoUrl: '',
      role: 'member',
      tags: cleanedTags,
      isActive: true,
      parentMid: parentMid.trim(),
      createdAt: DateTime.now(),
    );

    await memberRef.set(member.toMap());
  }

  // ---------------- UPDATE MEMBER ----------------
  Future<void> updateMember({
    required String familyDocId,
    required String memberId,
    required Map<String, dynamic> updates,
  }) async {
    // Handle tags cleaning
    if (updates.containsKey('tags')) {
      final List<String> tags = List<String>.from(updates['tags']);
      updates['tags'] = tags
          .where((t) => t.trim().isNotEmpty)
          .map((t) => t.trim().substring(0, t.length > 15 ? 15 : t.length))
          .toList();
    }

    // Handle age recalculation
    if (updates.containsKey('birthDate')) {
      updates['age'] = MemberModel.calculateAge(updates['birthDate'] as String);
    }

    await _getMembersCollection(familyDocId).doc(memberId).update(updates);
  }

  // ---------------- DELETE MEMBER ----------------
  Future<void> deleteMember({
    required String familyDocId,
    required String memberId,
  }) async {
    await _getMembersCollection(familyDocId).doc(memberId).delete();
  }

  // ---------------- GET MEMBER ----------------
  Future<MemberModel?> getMember({
    required String familyDocId,
    required String memberId,
  }) async {
    final doc = await _getMembersCollection(familyDocId).doc(memberId).get();
    if (doc.exists) {
      return MemberModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // ---------------- GET MEMBERS BY FAMILY ----------------
  Stream<List<MemberModel>> streamFamilyMembers(String familyDocId) {
    return _getMembersCollection(familyDocId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MemberModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ---------------- GET ALL MEMBERS (ADMIN - from all families) ----------------
  Stream<List<MemberModel>> streamAllMembers() {
    // For admin view, we need to use collection group query
    // This will query all 'members' subcollections across all families
    return _firestore
        .collectionGroup('members')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MemberModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ---------------- SEARCH MEMBERS ----------------
  Stream<List<MemberModel>> searchMembers(String query) {
    // Use collection group for cross-family search
    return _firestore
        .collectionGroup('members')
        .orderBy('fullName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MemberModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ---------------- TAG FILTER ----------------
  Stream<List<MemberModel>> filterByTag(String tag) {
    // Use collection group for cross-family tag filter
    return _firestore
        .collectionGroup('members')
        .where('tags', arrayContains: tag)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MemberModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ---------------- GET MEMBER COUNT (ALL FAMILIES) ----------------
  Future<int> getMemberCount() async {
    final snapshot = await _firestore.collectionGroup('members').count().get();
    return snapshot.count ?? 0;
  }

  // ---------------- GET UNMARRIED COUNT (ALL FAMILIES) ----------------
  Future<int> getUnmarriedCount() async {
    final snapshot = await _firestore
        .collectionGroup('members')
        .where('marriageStatus', isEqualTo: 'unmarried')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ---------------- GET ACTIVE MEMBER COUNT (ALL FAMILIES) ----------------
  Future<int> getActiveMemberCount() async {
    final snapshot = await _firestore
        .collectionGroup('members')
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ---------------- GET ALL UNIQUE TAGS (ALL FAMILIES) ----------------
  Future<List<String>> getAllTags() async {
    final snapshot = await _firestore.collectionGroup('members').get();
    final allTags = <String>{};
    for (final doc in snapshot.docs) {
      final tags = List<String>.from(doc['tags'] ?? []);
      allTags.addAll(tags);
    }
    return allTags.toList()..sort();
  }

  // ---------------- GET ALL MEMBERS (ONE-TIME FETCH - ALL FAMILIES) ----------------
  Future<List<MemberModel>> getAllMembers() async {
    final snapshot = await _firestore
        .collectionGroup('members')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => MemberModel.fromMap(d.id, d.data()))
        .toList();
  }

  // ---------------- GET MARRIED COUNT (ALL FAMILIES) ----------------
  Future<int> getMarriedCount() async {
    final snapshot = await _firestore
        .collectionGroup('members')
        .where('marriageStatus', isEqualTo: 'married')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ---------------- GET NEW MEMBERS THIS MONTH (ALL FAMILIES) ----------------
  Future<int> getNewMembersThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await _firestore
        .collectionGroup('members')
        .where('createdAt', isGreaterThan: startOfMonth)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ---------------- GET MEMBER BY MID (3-digit) ----------------
  Future<MemberModel?> getMemberByMid(String mid) async {
    // Since MID is not unique across families, we need to search all families
    final snapshot = await _firestore.collectionGroup('members').get();

    for (final doc in snapshot.docs) {
      if (doc['mid'] == mid) {
        return MemberModel.fromMap(doc.id, doc.data());
      }
    }
    return null;
  }
}
