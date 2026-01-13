import 'package:cloud_firestore/cloud_firestore.dart';
import 'counter_service.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CounterService _counterService = CounterService();

  // ---------------- ADD FAMILY (Auto-generate 2-digit ID) ----------------
  Future<void> addFamily({
    required String familyName,
    required String password,
  }) async {
    if (password.length != 6) {
      throw Exception('Password must be 6 digits');
    }

    // Auto-generate 2-digit familyId
    final familyId = await _counterService.getNextFamilyId();

    await _firestore.collection('families').add({
      'familyId': familyId,
      'familyName': familyName,
      'password': password,
      'isAdmin': false,
      'isBlocked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- ADD FAMILY WITH MANUAL ID (Legacy - for migration) ----------------
  Future<void> addFamilyWithManualId({
    required String familyId,
    required String familyName,
    required String password,
  }) async {
    if (familyId.length != 2) {
      throw Exception('Family ID must be 2 digits');
    }
    if (password.length != 6) {
      throw Exception('Password must be 6 digits');
    }

    // Check duplicate familyId
    final existing = await _firestore
        .collection('families')
        .where('familyId', isEqualTo: familyId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Family ID already exists');
    }

    await _firestore.collection('families').add({
      'familyId': familyId,
      'familyName': familyName,
      'password': password,
      'isAdmin': false,
      'isBlocked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- UPDATE FAMILY ----------------
  Future<void> updateFamily({
    required String familyDocId,
    String? familyName,
    String? password,
    bool? isBlocked,
  }) async {
    final updates = <String, dynamic>{};

    if (familyName != null) updates['familyName'] = familyName;
    if (password != null) updates['password'] = password;
    if (isBlocked != null) updates['isBlocked'] = isBlocked;

    if (updates.isNotEmpty) {
      await _firestore.collection('families').doc(familyDocId).update(updates);
    }
  }

  // ---------------- DELETE FAMILY ----------------
  Future<void> deleteFamily(String familyDocId) async {
    // Delete all members of this family
    final members = await _firestore
        .collection('members')
        .where('familyDocId', isEqualTo: familyDocId)
        .get();

    for (final doc in members.docs) {
      await doc.reference.delete();
    }

    // Delete all groups of this family
    final groups = await _firestore
        .collection('families')
        .doc(familyDocId)
        .collection('groups')
        .get();

    for (final doc in groups.docs) {
      await doc.reference.delete();
    }

    // Delete the family document
    await _firestore.collection('families').doc(familyDocId).delete();
  }

  // ---------------- TOGGLE BLOCK FAMILY ----------------
  Future<void> toggleBlockFamily(String familyDocId) async {
    final doc = await _firestore.collection('families').doc(familyDocId).get();
    if (doc.exists) {
      final isBlocked = doc['isBlocked'] as bool? ?? false;
      await doc.reference.update({'isBlocked': !isBlocked});
    }
  }

  // ---------------- GET FAMILY BY ID ----------------
  Future<Map<String, dynamic>?> getFamilyByDocId(String familyDocId) async {
    final doc = await _firestore.collection('families').doc(familyDocId).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data()!};
    }
    return null;
  }

  // ---------------- GET FAMILY BY FAMILY ID ----------------
  Future<Map<String, dynamic>?> getFamilyByFamilyId(int familyId) async {
    final query = await _firestore
        .collection('families')
        .where('familyId', isEqualTo: familyId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return {'id': doc.id, ...doc.data()};
    }
    return null;
  }

  // ---------------- STREAM FAMILIES (ALL) ----------------
  Stream<List<Map<String, dynamic>>> streamFamilies() {
    return _firestore
        .collection('families')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        );
  }

  // ---------------- STREAM FAMILIES (NON-ADMIN) ----------------
  Stream<List<Map<String, dynamic>>> streamNormalFamilies() {
    return _firestore
        .collection('families')
        .where('isAdmin', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        );
  }

  // ---------------- GET FAMILY COUNT ----------------
  Future<int> getFamilyCount() async {
    final snapshot = await _firestore
        .collection('families')
        .where('isAdmin', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ---------------- GET BLOCKED FAMILY COUNT ----------------
  Future<int> getBlockedFamilyCount() async {
    final snapshot = await _firestore
        .collection('families')
        .where('isAdmin', isEqualTo: false)
        .where('isBlocked', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ---------------- GET ACTIVE FAMILY COUNT ----------------
  Future<int> getActiveFamilyCount() async {
    final snapshot = await _firestore
        .collection('families')
        .where('isAdmin', isEqualTo: false)
        .where('isBlocked', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
