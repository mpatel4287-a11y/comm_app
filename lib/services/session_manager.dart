import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyFamilyDocId = 'family_doc_id';
  static const _keyFamilyId = 'family_id';
  static const _keyIsAdmin = 'is_admin';
  static const _keyRole = 'role';
  static const _keyFamilyName = 'family_name';
  static const _keyMemberId = 'member_id';

  // SAVE SESSION
  static Future<void> saveSession({
    required String familyDocId,
    required int familyId,
    required bool isAdmin,
    String role = 'member',
    String familyName = '',
    String memberId = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFamilyDocId, familyDocId);
    await prefs.setInt(_keyFamilyId, familyId);
    await prefs.setBool(_keyIsAdmin, isAdmin);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyFamilyName, familyName);
    await prefs.setString(_keyMemberId, memberId);
  }

  // GETTERS
  static Future<bool?> getIsAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdmin);
  }

  static Future<String?> getFamilyDocId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFamilyDocId);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<String?> getFamilyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFamilyName);
  }

  static Future<int?> getFamilyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFamilyId);
  }

  static Future<String?> getMemberId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMemberId);
  }

  // CHECK IF SESSION EXISTS
  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFamilyDocId) != null;
  }

  // CLEAR SESSION
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
