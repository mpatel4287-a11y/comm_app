// lib/services/group_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------- CREATE GROUP ----------------
  Future<void> createGroup({
    required String familyDocId,
    required String name,
    required String createdBy,
    List<String> memberIds = const [],
    List<String> managerMids = const [],
  }) async {
    final groupRef = _firestore
        .collection('families')
        .doc(familyDocId)
        .collection('groups')
        .doc();

    final group = GroupModel(
      id: groupRef.id,
      familyDocId: familyDocId,
      name: name.trim(),
      memberIds: memberIds,
      managerMids: managerMids,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await groupRef.set(group.toMap());
  }

  // ---------------- CREATE GROUP WITH DETAILS ----------------
  Future<void> createGroupWithDetails({
    required String familyDocId,
    required String name,
    required String createdBy,
    String description = '',
    String type = 'community',
    List<String> memberIds = const [],
    List<String> managerMids = const [],
  }) async {
    final groupRef = _firestore
        .collection('families')
        .doc(familyDocId)
        .collection('groups')
        .doc();

    final group = GroupModel(
      id: groupRef.id,
      familyDocId: familyDocId,
      name: name.trim(),
      description: description.trim(),
      type: type,
      memberIds: memberIds,
      managerMids: managerMids,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await groupRef.set(group.toMap());
  }

  // ---------------- UPDATE GROUP ----------------
  Future<void> updateGroup({
    required String familyDocId,
    required String groupId,
    String? name,
    List<String>? memberIds,
    List<String>? managerMids,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (memberIds != null) updates['memberIds'] = memberIds;
    if (managerMids != null) updates['managerMids'] = managerMids;

    if (updates.isNotEmpty) {
      await _firestore
          .collection('families')
          .doc(familyDocId)
          .collection('groups')
          .doc(groupId)
          .update(updates);
    }
  }

  // ---------------- UPDATE GROUP WITH DETAILS ----------------
  Future<void> updateGroupWithDetails({
    required String familyDocId,
    required String groupId,
    String? name,
    String? description,
    String? type,
    List<String>? memberIds,
    List<String>? managerMids,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (type != null) updates['type'] = type;
    if (memberIds != null) updates['memberIds'] = memberIds;
    if (managerMids != null) updates['managerMids'] = managerMids;

    if (updates.isNotEmpty) {
      await _firestore
          .collection('families')
          .doc(familyDocId)
          .collection('groups')
          .doc(groupId)
          .update(updates);
    }
  }

  // ---------------- DELETE GROUP ----------------
  Future<void> deleteGroup(String familyDocId, String groupId) async {
    await _firestore
        .collection('families')
        .doc(familyDocId)
        .collection('groups')
        .doc(groupId)
        .delete();
  }

  // ---------------- ADD MEMBER TO GROUP ----------------
  Future<void> addMemberToGroup({
    required String familyDocId,
    required String groupId,
    required String memberId,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyDocId)
        .collection('groups')
        .doc(groupId)
        .update({
          'memberIds': FieldValue.arrayUnion([memberId]),
        });
  }

  // ---------------- REMOVE MEMBER FROM GROUP ----------------
  Future<void> removeMemberFromGroup({
    required String familyDocId,
    required String groupId,
    required String memberId,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyDocId)
        .collection('groups')
        .doc(groupId)
        .update({
          'memberIds': FieldValue.arrayRemove([memberId]),
        });
  }

  // ---------------- STREAM GROUPS ----------------
  Stream<List<GroupModel>> streamGroups(String familyDocId) {
    return _firestore
        .collection('families')
        .doc(familyDocId)
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ---------------- GET GROUP ----------------
  Future<GroupModel?> getGroup(String familyDocId, String groupId) async {
    final doc = await _firestore
        .collection('families')
        .doc(familyDocId)
        .collection('groups')
        .doc(groupId)
        .get();

    if (doc.exists) {
      return GroupModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
}
