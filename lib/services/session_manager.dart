import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyFamilyDocId = 'family_doc_id';
  static const _keyFamilyId = 'family_id';
  static const _keyIsAdmin = 'is_admin';

  // SAVE SESSION
  static Future<void> saveSession({
    required String familyDocId,
    required int familyId,
    required bool isAdmin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFamilyDocId, familyDocId);
    await prefs.setInt(_keyFamilyId, familyId);
    await prefs.setBool(_keyIsAdmin, isAdmin);
  }

  // 🔴 THIS WAS MISSING
  static Future<bool?> getIsAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdmin);
  }

  static Future<String?> getFamilyDocId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFamilyDocId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
