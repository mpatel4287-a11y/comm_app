// lib/services/attendance_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import '../models/member_model.dart';
import 'member_service.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MemberService _memberService = MemberService();

  // ---------------- MARK ATTENDANCE ----------------
  Future<void> markAttendance({
    required String eventId,
    required String markedBy,
    required String markedByName,
    required String attendanceType, // 'family' | 'subfamily' | 'firm'
    required String entityId, // familyDocId | subFamilyDocId | firmName
    required String entityName,
  }) async {
    // Get members based on attendance type
    List<MemberModel> members = [];
    
    if (attendanceType == 'family') {
      // Get all members from the family
      final allMembers = await _memberService.getAllMembers();
      members = allMembers.where((m) => m.familyDocId == entityId).toList();
    } else if (attendanceType == 'subfamily') {
      // Get members from sub-family
      // entityId format: "familyDocId/subFamilyDocId"
      final pathParts = entityId.split('/');
      if (pathParts.length >= 2) {
        final familyDocId = pathParts[0];
        final subFamilyDocId = pathParts[1];
        final allMembers = await _memberService.getAllMembers();
        members = allMembers.where((m) => 
          m.familyDocId == familyDocId && m.subFamilyDocId == subFamilyDocId
        ).toList();
      } else {
        // Fallback: try to get from member's own subfamily
        final allMembers = await _memberService.getAllMembers();
        final currentMember = allMembers.firstWhere(
          (m) => m.id == markedBy,
          orElse: () => throw Exception('Member not found'),
        );
        members = allMembers.where((m) => 
          m.familyDocId == currentMember.familyDocId && 
          m.subFamilyDocId == currentMember.subFamilyDocId
        ).toList();
      }
    } else if (attendanceType == 'firm') {
      // Get members who have this firm
      final allMembers = await _memberService.getAllMembers();
      members = allMembers.where((m) => 
        m.firms.any((firm) => firm['name'] == entityId)
      ).toList();
    }

    // Check if attendance already exists for this event and entity
    final existing = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('attendance')
        .where('entityId', isEqualTo: entityId)
        .where('attendanceType', isEqualTo: attendanceType)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Update existing attendance
      await existing.docs.first.reference.update({
        'markedBy': markedBy,
        'markedByName': markedByName,
        'memberIds': members.map((m) => m.id).toList(),
        'memberCount': members.length,
        'markedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new attendance
      final attendance = AttendanceModel(
        id: '',
        eventId: eventId,
        markedBy: markedBy,
        markedByName: markedByName,
        attendanceType: attendanceType,
        entityId: entityId,
        entityName: entityName,
        memberIds: members.map((m) => m.id).toList(),
        memberCount: members.length,
        markedAt: DateTime.now(),
      );

      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendance')
          .add(attendance.toMap());
    }
  }

  // ---------------- GET ATTENDANCE FOR EVENT ----------------
  Stream<List<AttendanceModel>> getEventAttendance(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('attendance')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ---------------- GET ATTENDANCE COUNT ----------------
  Future<int> getAttendanceCount(String eventId) async {
    final snapshot = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('attendance')
        .get();
    
    int totalCount = 0;
    for (final doc in snapshot.docs) {
      final count = doc.data()['memberCount'];
      totalCount += (count is int ? count : (count as num).toInt());
    }
    return totalCount;
  }

  // ---------------- GET ATTENDANCE BY TYPE ----------------
  Future<Map<String, int>> getAttendanceByType(String eventId) async {
    final snapshot = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('attendance')
        .get();
    
    final Map<String, int> counts = {
      'family': 0,
      'subfamily': 0,
      'firm': 0,
    };
    
    for (final doc in snapshot.docs) {
      final type = doc.data()['attendanceType'] ?? 'family';
      final count = doc.data()['memberCount'] ?? 0;
      final countInt = count is int ? count : (count as num).toInt();
      counts[type] = (counts[type] ?? 0) + countInt;
    }
    
    return counts;
  }

  // ---------------- DELETE ATTENDANCE ----------------
  Future<void> deleteAttendance(String eventId, String attendanceId) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('attendance')
        .doc(attendanceId)
        .delete();
  }
}
