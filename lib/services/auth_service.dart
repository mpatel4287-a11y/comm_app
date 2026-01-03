// lib/services/auth_service.dart
// Phase 2: Family ID + Password authentication

// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/login_response.dart';
import 'session_manager.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String ADMIN_ID = '83288';

  Future<LoginResponse> login({
    required String familyId,
    required String password,
  }) async {
    try {
      final fid = familyId.trim();
      final pwd = password.trim();

      // ---------------- VALIDATION ----------------
      if (fid.isEmpty || pwd.isEmpty) {
        return LoginResponse(
          success: false,
          message: 'Family ID and password required',
          isAdmin: false,
        );
      }

      // ---------------- ADMIN LOGIN ----------------
      if (fid == ADMIN_ID) {
        final adminSnap = await _firestore
            .collection('families')
            .doc(ADMIN_ID)
            .get();

        if (!adminSnap.exists || adminSnap['password'] != pwd) {
          return LoginResponse(
            success: false,
            message: 'Invalid admin credentials',
            isAdmin: false,
          );
        }

        await SessionManager.saveSession(
          familyDocId: adminSnap.id,
          familyId: 0,
          isAdmin: true,
          role: 'admin',
          familyName: adminSnap['familyName'] ?? 'Admin',
        );

        return LoginResponse(
          success: true,
          message: 'Admin login successful',
          isAdmin: true,
        );
      }

      // ---------------- FAMILY LOGIN ----------------
      if (fid.length != 6 || int.tryParse(fid) == null) {
        return LoginResponse(
          success: false,
          message: 'Family ID must be 6 digits',
          isAdmin: false,
        );
      }

      final query = await _firestore
          .collection('families')
          .where('familyId', isEqualTo: int.parse(fid))
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return LoginResponse(
          success: false,
          message: 'Family not found',
          isAdmin: false,
        );
      }

      final doc = query.docs.first;
      final data = doc.data();

      if (data['password'] != pwd) {
        return LoginResponse(
          success: false,
          message: 'Incorrect password',
          isAdmin: false,
        );
      }

      await SessionManager.saveSession(
        familyDocId: doc.id,
        familyId: data['familyId'],
        isAdmin: false,
        role: 'member',
        familyName: data['familyName'] ?? '',
      );

      return LoginResponse(
        success: true,
        message: 'Login successful',
        isAdmin: false,
      );
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Auth error: $e',
        isAdmin: false,
      );
    }
  }

  Future<void> logout() async {
    await SessionManager.clear();
  }
}
