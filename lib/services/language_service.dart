// lib/services/language_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _prefKey = 'language_code';
  Locale _locale = const Locale('en');
  bool _isInitialized = false;

  Locale get locale => _locale;

  // Translations
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // General
      'appName': 'Community App',
      'home': 'Home',
      'explore': 'Explore',
      'calendar': 'Calendar',
      'profile': 'Profile',
      'settings': 'Settings',
      'loading': 'Loading...',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'share': 'Share',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'language': 'Language',
      'english': 'English',
      'gujarati': 'Gujarati',

      // Member
      'memberDetails': 'Member Details',
      'addMember': 'Add Member',
      'fullName': 'Full Name',
      'surname': 'Surname',
      'fatherName': 'Father Name',
      'motherName': 'Mother Name',
      'gotra': 'Gotra',
      'birthDate': 'Birth Date',
      'phone': 'Phone',
      'address': 'Address',
      'bloodGroup': 'Blood Group',
      'marriageStatus': 'Marriage Status',
      'nativeHome': 'Native Home',

      // Family
      'family': 'Family',
      'familyName': 'Family Name',
      'familyId': 'Family ID',
      'familyTree': 'Family Tree',
      'families': 'Families',

      // Analytics
      'analytics': 'Analytics',
      'totalMembers': 'Total Members',
      'totalFamilies': 'Total Families',
      'activeMembers': 'Active Members',
      'unmarried': 'Unmarried',

      // Calendar
      'events': 'Events',
      'noEvents': 'No events',
      'addEvent': 'Add Event',

      // Sharing
      'shareProfile': 'Share Profile',
      'shareViaQR': 'Share via QR',
      'shareNormally': 'Share Normally',
    },
    'gu': {
      // General
      'appName': 'કમ્યુનિટી એપ',
      'home': 'હોમ',
      'explore': 'એક્સપ્લોર',
      'calendar': 'કૅલેન્ડર',
      'profile': 'પ્રોફાઇલ',
      'settings': 'સેટિંગ્સ',
      'loading': 'લોડ થઈ रहा है...',
      'save': 'સાચવો',
      'cancel': 'રદ',
      'delete': 'દરમિયાન',
      'edit': 'સંપાદન',
      'add': 'ઉમ્ર',
      'search': 'શોધ',
      'share': 'શૅર',
      'darkMode': 'ડાર્ક મોડ',
      'lightMode': 'લાઇટ મોડ',
      'language': 'ભાષા',
      'english': 'અંગ્રेज़ी',
      'gujarati': 'ગુજરાતી',

      // Member
      'memberDetails': 'સભ્યની વિગત',
      'addMember': 'સભ્ય ઉમ્ર',
      'fullName': 'પૂરું નામ',
      'surname': 'અટક',
      'fatherName': 'પિતાનું નામ',
      'motherName': 'માતાનું નામ',
      'gotra': 'ગોત્ર',
      'birthDate': 'જન્મ તરીખ',
      'phone': 'ફોન',
      'address': 'સરનામું',
      'bloodGroup': 'બ્લડ ગ્રુપ',
      'marriageStatus': 'લગ્નનी स्थिति',
      'nativeHome': 'મૂળનું घर',

      // Family
      'family': 'પરિવार',
      'familyName': 'પરિવार का नाम',
      'familyId': 'Family ID',
      'familyTree': 'Family Tree',
      'families': 'Families',

      // Analytics
      'analytics': 'Analytics',
      'totalMembers': 'Total Members',
      'totalFamilies': 'Total Families',
      'activeMembers': 'Active Members',
      'unmarried': 'Unmarried',

      // Calendar
      'events': 'Events',
      'noEvents': 'No events',
      'addEvent': 'Add Event',

      // Sharing
      'shareProfile': 'Share Profile',
      'shareViaQR': 'Share via QR',
      'shareNormally': 'Share Normally',
    },
  };

  String translate(String key) {
    return _translations[_locale.languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_prefKey);
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
    notifyListeners();
  }

  String t(String key) => translate(key);
}
