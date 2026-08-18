// lib/services/role_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organizational_role_model.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'organizational_roles';

  // Categories as requested by the user
  static const List<String> defaultCategories = [
    'Samaj',
    'Yuvak Mandal',
    'Mahila Mandal',
  ];

  // ---------------- CREATE ROLE ----------------
  Future<void> createRole(OrganizationalRoleModel role) async {
    final docRef = _firestore.collection(_collectionName).doc();
    await docRef.set(role.copyWith().toMap()..['id'] = docRef.id);
  }

  // ---------------- UPDATE ROLE ----------------
  Future<void> updateRole(String roleId, Map<String, dynamic> updates) async {
    await _firestore.collection(_collectionName).doc(roleId).update(updates);
  }

  // ---------------- DELETE ROLE ----------------
  Future<void> deleteRole(String roleId) async {
    await _firestore.collection(_collectionName).doc(roleId).delete();
  }

  // ---------------- STREAM ROLES BY CATEGORY ----------------
  Stream<List<OrganizationalRoleModel>> streamRolesByCategory(String category) {
    return _firestore
        .collection(_collectionName)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => OrganizationalRoleModel.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) {
            final orderComp = a.order.compareTo(b.order);
            if (orderComp != 0) return orderComp;
            return a.createdAt.compareTo(b.createdAt);
          });
          return list;
        });
  }

  // ---------------- GET ALL ROLES (ONE-TIME) ----------------
  Future<List<OrganizationalRoleModel>> getAllRoles() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final list = snapshot.docs
        .map((doc) => OrganizationalRoleModel.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) {
      final catComp = a.category.compareTo(b.category);
      if (catComp != 0) return catComp;
      return a.order.compareTo(b.order);
    });
    return list;
  }

  // ---------------- STREAM ALL ROLES ----------------
  Stream<List<OrganizationalRoleModel>> streamAllRoles() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => OrganizationalRoleModel.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) {
            final catComp = a.category.compareTo(b.category);
            if (catComp != 0) return catComp;
            return a.order.compareTo(b.order);
          });
          return list;
        });
  }

  // ---------------- GET ROLES FOR A SPECIFIC MEMBER ----------------
  Future<List<OrganizationalRoleModel>> getMemberRoles(String memberMid) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('memberMids', arrayContains: memberMid)
        .get();
    return snapshot.docs
        .map((doc) => OrganizationalRoleModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}
