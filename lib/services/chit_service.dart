import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chit_model.dart';
import 'fcm_service.dart';

class ChitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'chits';

  Future<void> createChit(ChitModel chit) async {
    await _firestore.collection(_collectionName).doc().set(chit.toMap());
  }

  Future<void> updateChit(String id, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData['updatedAt'] = DateTime.now().toIso8601String();
    
    // Get existing chit to check if amount changed
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    final oldAmount = doc.data()?['amount'];
    final newAmount = data['amount'];
    final firmName = doc.data()?['firmName'] ?? data['firmName'];

    await _firestore.collection(_collectionName).doc(id).update(updateData);

    // If amount changed and firm is linked, notify firm members
    if (newAmount != null && newAmount != oldAmount && firmName != null) {
      await _notifyFirmMembers(firmName, data['title'] ?? doc.data()?['title'], newAmount);
    }
  }

  Future<void> deleteChit(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  Stream<List<ChitModel>> streamChits() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChitModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> _notifyFirmMembers(String firmName, String schemeTitle, String newAmount) async {
    try {
      // 1. Find all members associated with this firm
      // Members have a list of firms: [{'name': 'FirmName', ...}]
      final membersSnap = await _firestore.collectionGroup('members').get();
      
      List<String> targetTokens = [];
      for (var doc in membersSnap.docs) {
        final data = doc.data();
        final firms = data['firms'] as List?;
        if (firms != null) {
          final isMember = firms.any((f) => (f['name'] ?? '').toString().toLowerCase() == firmName.toLowerCase());
          if (isMember && data['fcmToken'] != null) {
            targetTokens.add(data['fcmToken']);
          }
        }
      }

      if (targetTokens.isEmpty) return;

      // 2. Send notifications via FcmService (if multi-send is supported)
      // For now, we'll send a general notification or iterate
      for (var token in targetTokens) {
        await FcmService.sendNotification(
          token: token,
          title: 'Chit Update: $firmName',
          body: 'The installment for "$schemeTitle" has been updated to $newAmount.',
          data: {'type': 'chit_update'},
        );
      }
    } catch (e) {
      debugPrint('Error notifying firm members: $e');
    }
  }
}
