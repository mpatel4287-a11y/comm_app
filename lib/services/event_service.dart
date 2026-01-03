// lib/services/event_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------- CREATE EVENT ----------------
  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String createdBy,
    String location = '',
    String type = 'general',
    String familyDocId = '',
  }) async {
    final eventRef = _firestore.collection('events').doc();

    final event = EventModel(
      id: eventRef.id,
      title: title.trim(),
      description: description.trim(),
      location: location.trim(),
      date: date,
      type: type,
      createdBy: createdBy,
      familyDocId: familyDocId,
      createdAt: DateTime.now(),
    );

    await eventRef.set(event.toMap());
  }

  // ---------------- UPDATE EVENT ----------------
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    String? type,
  }) async {
    final updates = <String, dynamic>{};

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (location != null) updates['location'] = location;
    if (date != null) updates['date'] = date;
    if (type != null) updates['type'] = type;

    if (updates.isNotEmpty) {
      await _firestore.collection('events').doc(eventId).update(updates);
    }
  }

  // ---------------- DELETE EVENT ----------------
  Future<void> deleteEvent(String eventId) async {
    // Delete all attendance records for this event
    final attendance = await _firestore
        .collection('attendance')
        .where('eventId', isEqualTo: eventId)
        .get();

    for (final doc in attendance.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('events').doc(eventId).delete();
  }

  // ---------------- STREAM EVENTS (ALL) ----------------
  Stream<List<EventModel>> streamAllEvents() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => EventModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ---------------- STREAM EVENTS (UPCOMING) ----------------
  Stream<List<EventModel>> streamUpcomingEvents() {
    final now = DateTime.now();
    return _firestore
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: now)
        .orderBy('date')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => EventModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ---------------- GET EVENT ----------------
  Future<EventModel?> getEvent(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();
    if (doc.exists) {
      return EventModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // ---------------- GET EVENT COUNT ----------------
  Future<int> getEventCount() async {
    final snapshot = await _firestore.collection('events').count().get();
    return snapshot.count ?? 0;
  }
}
