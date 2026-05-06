// lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeService extends ChangeNotifier {
  static const String _prefKey = 'is_dark_mode';
  static const String _fontScaleKey = 'font_scale';

  bool _isDarkMode = false;
  bool _isInitialized = false;
  double _fontScale = 0.9;

  bool get isDarkMode => _isDarkMode;
  double get textScale => _fontScale;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_prefKey) ?? false;
    _fontScale = prefs.getDouble(_fontScaleKey) ?? 0.9;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    _fontScale = scale.clamp(0.8, 1.4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, _fontScale);
    notifyListeners();
  }

  ThemeData getTheme() {
    final baseTheme = _isDarkMode ? _darkTheme : _lightTheme;

    // Apply Hind Vadodara to guarantee modern, clean Gujarati & English text
    final TextTheme googleTextTheme = GoogleFonts.hindVadodaraTextTheme(baseTheme.textTheme);
    final scaledTextTheme = _scaleTextTheme(googleTextTheme, _fontScale);

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      primaryTextTheme: scaledTextTheme,
      // Ensure fontFamily is set globally so all TextStyle() inherit it
      appBarTheme: baseTheme.appBarTheme.copyWith(
        titleTextStyle: (baseTheme.appBarTheme.titleTextStyle ??
                scaledTextTheme.titleLarge ??
                GoogleFonts.hindVadodara(fontSize: 20, fontWeight: FontWeight.w600))
            .copyWith(
          fontSize: (scaledTextTheme.titleLarge?.fontSize ?? 20) * _fontScale,
        ),
      ),
    );
  }

  TextTheme _scaleTextTheme(TextTheme textTheme, double scale) {
    return textTheme.copyWith(
      displayLarge: _scaleTextStyle(textTheme.displayLarge, scale),
      displayMedium: _scaleTextStyle(textTheme.displayMedium, scale),
      displaySmall: _scaleTextStyle(textTheme.displaySmall, scale),
      headlineLarge: _scaleTextStyle(textTheme.headlineLarge, scale),
      headlineMedium: _scaleTextStyle(textTheme.headlineMedium, scale),
      headlineSmall: _scaleTextStyle(textTheme.headlineSmall, scale),
      titleLarge: _scaleTextStyle(textTheme.titleLarge, scale),
      titleMedium: _scaleTextStyle(textTheme.titleMedium, scale),
      titleSmall: _scaleTextStyle(textTheme.titleSmall, scale),
      bodyLarge: _scaleTextStyle(textTheme.bodyLarge, scale),
      bodyMedium: _scaleTextStyle(textTheme.bodyMedium, scale),
      bodySmall: _scaleTextStyle(textTheme.bodySmall, scale),
      labelLarge: _scaleTextStyle(textTheme.labelLarge, scale),
      labelMedium: _scaleTextStyle(textTheme.labelMedium, scale),
      labelSmall: _scaleTextStyle(textTheme.labelSmall, scale),
    );
  }

  TextStyle? _scaleTextStyle(TextStyle? style, double scale) {
    if (style == null) return null;
    if (style.fontSize == null) return style;
    return style.copyWith(fontSize: style.fontSize! * scale);
  }

  // Midnight Indigo Palette - Light
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.hindVadodara().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5), // Indigo Primary
      primary: const Color(0xFF4F46E5),
      secondary: const Color(0xFF14B8A6), // Vibrant Teal
      tertiary: const Color(0xFFF59E0B), // Amber accent
      surface: const Color(0xFFFFFFFF), // Pure White cards
      surfaceContainerHighest: const Color(0xFFF1F5F9), // Slate 100
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50 Background
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF0F172A), // Slate 900
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2, 
      shadowColor: Colors.black.withOpacity(0.05),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // Slate 200 border
      ),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFF4F46E5).withOpacity(0.1),
      elevation: 0,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
    ),
  );

  // Midnight Indigo Palette - Dark
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.hindVadodara().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF818CF8), // Light Indigo for dark mode
      primary: const Color(0xFF818CF8),
      secondary: const Color(0xFF2DD4BF), // Light Teal
      tertiary: const Color(0xFFFCD34D), // Light Amber
      surface: const Color(0xFF1E293B), // Slate 800 (Premium Dark Cards)
      surfaceContainerHighest: const Color(0xFF334155), // Slate 700
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900 Background (Midnight)
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF818CF8),
        foregroundColor: const Color(0xFF0F172A),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155), width: 1), // Slate 700 border
      ),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1E293B),
      indicatorColor: const Color(0xFF818CF8).withOpacity(0.15),
      elevation: 0,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
      ),
    ),
  );
}
