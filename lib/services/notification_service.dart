// lib/services/notification_service.dart

// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------- CREATE NOTIFICATION ----------------
  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    required String targetType,
    String? targetId,
    required String createdBy,
  }) async {
    final notificationRef = _firestore.collection('notifications').doc();

    final notification = NotificationModel(
      id: notificationRef.id,
      title: title.trim(),
      message: message.trim(),
      type: type,
      targetType: targetType,
      targetId: targetId,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );

    await notificationRef.set(notification.toMap());
  }

  // ---------------- MARK AS READ ----------------
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // ---------------- MARK ALL AS READ ----------------
  Future<void> markAllAsRead() async {
    final notifications = await _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // ---------------- DELETE NOTIFICATION ----------------
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // ---------------- STREAM ALL NOTIFICATIONS (ADMIN) ----------------
  Stream<List<NotificationModel>> streamAllNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ---------------- STREAM NOTIFICATIONS FOR USER ----------------
  Stream<List<NotificationModel>> streamUserNotifications(String familyDocId) {
    return _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) {
          return snap.docs
              .where((doc) {
                final data = doc.data();
                final targetType = data['targetType'] as String;
                final targetId = data['targetId'] as String?;

                if (targetType == 'all') return true;
                if (targetType == 'family' && targetId == familyDocId)
                  return true;
                return false;
              })
              .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // ---------------- GET UNREAD COUNT ----------------
  Stream<int> streamUnreadCount(String familyDocId) {
    return _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) {
          int count = 0;
          for (final doc in snap.docs) {
            final data = doc.data();
            final targetType = data['targetType'] as String;
            final targetId = data['targetId'] as String?;

            if (targetType == 'all') {
              count++;
            } else if (targetType == 'family' && targetId == familyDocId) {
              count++;
            }
          }
          return count;
        });
  }

  // ---------------- DELETE ALL NOTIFICATIONS ----------------
  Future<void> deleteAllNotifications() async {
    final notifications = await _firestore.collection('notifications').get();

    final batch = _firestore.batch();

    for (final doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
