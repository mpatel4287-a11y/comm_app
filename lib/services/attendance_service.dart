// lib/services/attendance_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------- MARK ATTENDANCE ----------------
  Future<void> markAttendance({
    required String eventId,
    required String memberId,
    required String memberName,
    required String status, // present | absent
    required String markedBy,
  }) async {
    // Check if attendance already marked
    final existing = await _firestore
        .collection('attendance')
        .where('eventId', isEqualTo: eventId)
        .where('memberId', isEqualTo: memberId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Update existing
      await existing.docs.first.reference.update({
        'status': status,
        'markedAt': DateTime.now(),
        'markedBy': markedBy,
      });
    } else {
      // Create new
      final attendanceRef = _firestore.collection('attendance').doc();

      final attendance = AttendanceModel(
        id: attendanceRef.id,
        eventId: eventId,
        memberId: memberId,
        memberName: memberName,
        status: status,
        markedAt: DateTime.now(),
        markedBy: markedBy,
      );

      await attendanceRef.set(attendance.toMap());
    }
  }

  // ---------------- BULK MARK ATTENDANCE ----------------
  Future<void> bulkMarkAttendance({
    required String eventId,
    required List<Map<String, dynamic>> attendanceList,
    required String markedBy,
  }) async {
    final batch = _firestore.batch();

    for (final item in attendanceList) {
      final attendanceRef = _firestore.collection('attendance').doc();

      final attendance = AttendanceModel(
        id: attendanceRef.id,
        eventId: eventId,
        memberId: item['memberId'],
        memberName: item['memberName'],
        status: item['status'],
        markedAt: DateTime.now(),
        markedBy: markedBy,
      );

      batch.set(attendanceRef, attendance.toMap());
    }

    await batch.commit();
  }

  // ---------------- GET ATTENDANCE FOR EVENT ----------------
  Stream<List<AttendanceModel>> streamAttendanceForEvent(String eventId) {
    return _firestore
        .collection('attendance')
        .where('eventId', isEqualTo: eventId)
        .orderBy('memberName')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AttendanceModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ---------------- GET ATTENDANCE FOR MEMBER ----------------
  Stream<List<AttendanceModel>> streamAttendanceForMember(String memberId) {
    return _firestore
        .collection('attendance')
        .where('memberId', isEqualTo: memberId)
        .orderBy('markedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AttendanceModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ---------------- GET ATTENDANCE PERCENTAGE FOR MEMBER ----------------
  Future<double> getAttendancePercentage(String memberId) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('memberId', isEqualTo: memberId)
        .count()
        .get();

    final total = snapshot.count ?? 0;

    if (total == 0) return 0.0;

    final presentSnapshot = await _firestore
        .collection('attendance')
        .where('memberId', isEqualTo: memberId)
        .where('status', isEqualTo: 'present')
        .count()
        .get();

    final present = presentSnapshot.count ?? 0;

    return (present / total) * 100;
  }

  // ---------------- GET EVENT ATTENDANCE PERCENTAGE ----------------
  Future<double> getEventAttendancePercentage(String eventId) async {
    final totalSnapshot = await _firestore
        .collection('attendance')
        .where('eventId', isEqualTo: eventId)
        .count()
        .get();

    final total = totalSnapshot.count ?? 0;

    if (total == 0) return 0.0;

    final presentSnapshot = await _firestore
        .collection('attendance')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'present')
        .count()
        .get();

    final present = presentSnapshot.count ?? 0;

    return (present / total) * 100;
  }

  // ---------------- DELETE ATTENDANCE RECORD ----------------
  Future<void> deleteAttendanceRecord(String attendanceId) async {
    await _firestore.collection('attendance').doc(attendanceId).delete();
  }
}
