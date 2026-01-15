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
    required String loginId,
    required String password,
  }) async {
    try {
      final id = loginId.trim();
      final pwd = password.trim();

      // ---------------- VALIDATION ----------------
      if (id.isEmpty || pwd.isEmpty) {
        return LoginResponse(
          success: false,
          message: 'ID and password required',
          isAdmin: false,
        );
      }

      // ---------------- ADMIN LOGIN (ADM-83288) ----------------
      if (id.startsWith('ADM-')) {
        final adminId = id.substring(4); // Remove 'ADM-'
        if (adminId == ADMIN_ID) {
          final adminSnap = await _firestore
              .collection('families')
              .doc(ADMIN_ID)
              .get();

          if (!adminSnap.exists || (adminSnap.data()?['password'] ?? '') != pwd) {
            return LoginResponse(
              success: false,
              message: 'Invalid admin credentials',
              isAdmin: false,
            );
          }

          await SessionManager.saveSession(
            familyDocId: adminSnap.id,
            familyId: adminSnap.data()?['familyId'] ?? 0,
            isAdmin: true,
            role: 'admin',
            familyName: adminSnap.data()?['familyName'] ?? 'Admin',
          );

          return LoginResponse(
            success: true,
            message: 'Admin login successful',
            isAdmin: true,
            role: 'admin',
          );
        }
      }

      // ---------------- MEMBER/MANAGER LOGIN (MID) ----------------
      // Use collectionGroup to find the member by MID across all families/subfamilies
      final memberQuery = await _firestore
          .collectionGroup('members')
          .where('mid', isEqualTo: id)
          .limit(1)
          .get();

      if (memberQuery.docs.isEmpty) {
        return LoginResponse(
          success: false,
          message: 'Member not found with this MID',
          isAdmin: false,
        );
      }

      final memberDoc = memberQuery.docs.first;
      final memberData = memberDoc.data();
      
      if (memberData['password'] != pwd) {
        return LoginResponse(
          success: false,
          message: 'Incorrect password',
          isAdmin: false,
        );
      }

      final role = memberData['role'] ?? 'member';
      final isAdmin = role == 'admin'; // Should rarely happen via MID but safety first

      // Save session with detailed member info
      await SessionManager.saveSession(
        familyDocId: memberData['familyDocId'] ?? '',
        familyId: int.tryParse(memberData['familyId']?.toString() ?? '0') ?? 0,
        isAdmin: isAdmin,
        role: role,
        familyName: memberData['familyName'] ?? '',
        memberId: memberData['mid'] ?? '',
      );

      // Also save member-specific session info
      await SessionManager.saveMemberSession(
        mainFamilyDocId: memberData['familyDocId'] ?? '',
        subFamilyDocId: memberData['subFamilyDocId'] ?? '',
        memberDocId: memberDoc.id,
      );

      return LoginResponse(
        success: true,
        message: 'Login successful as ${role.toUpperCase()}',
        isAdmin: isAdmin,
        role: role,
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
