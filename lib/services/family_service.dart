import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFamily({
    required int familyId,
    required String familyName,
    required String password,
  }) async {
    if (familyId.toString().length != 6) {
      throw Exception('Family ID must be 6 digits');
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
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
