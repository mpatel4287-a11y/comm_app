import 'package:cloud_firestore/cloud_firestore.dart';

class CounterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the next auto-increment ID for families (returns 2-digit string like "01", "02", ...)
  Future<String> getNextFamilyId() async {
    final docRef = _firestore.collection('counters').doc('familyCounter');

    return _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        // Initialize counter at 1
        transaction.set(docRef, {'current': 1});
        return _formatId(1);
      }

      int current = doc['current'] as int? ?? 1;
      current++;
      transaction.update(docRef, {'current': current});
      return _formatId(current);
    });
  }

  /// Get the next auto-increment ID for sub-families within a main family
  Future<String> getNextSubFamilyId(String mainFamilyDocId) async {
    final docRef = _firestore
        .collection('families')
        .doc(mainFamilyDocId)
        .collection('counters')
        .doc('subFamilyCounter');

    return _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        // Initialize counter at 1 for this family
        transaction.set(docRef, {'current': 1});
        return _formatId(1);
      }

      int current = doc['current'] as int? ?? 1;
      current++;
      transaction.update(docRef, {'current': current});
      return _formatId(current);
    });
  }

  /// Format ID as 2-digit string (e.g., 1 -> "01", 23 -> "23")
  String _formatId(int id) {
    return id.toString().padLeft(2, '0');
  }
}
