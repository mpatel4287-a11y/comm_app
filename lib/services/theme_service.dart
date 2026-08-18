// lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Remove GoogleFonts override to allow system default (SF Pro on iOS / Roboto on Android)
    final textTheme = baseTheme.textTheme;
    final scaledTextTheme = _scaleTextTheme(textTheme, _fontScale);

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      primaryTextTheme: scaledTextTheme,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        titleTextStyle: (baseTheme.appBarTheme.titleTextStyle ??
                scaledTextTheme.titleLarge ??
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5))
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

  // iOS Glassmorphic Palette - Light
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF), // iOS System Blue
      primary: const Color(0xFF007AFF),
      secondary: const Color(0xFF5856D6), // iOS Indigo
      tertiary: const Color(0xFFFF9500), // iOS Orange
      surface: const Color(0xFFFFFFFF).withOpacity(0.7), // Translucent white for glassmorphism
      surfaceContainerHighest: const Color(0xFFF2F2F7), // iOS System Gray 6
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.transparent, // Transparent to show mesh gradient
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF000000), 
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF007AFF)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withOpacity(0.6), // Translucent card base
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5), 
      ),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withOpacity(0.75), // Translucent nav bar
      indicatorColor: const Color(0xFF007AFF).withOpacity(0.15),
      elevation: 0,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
      ),
    ),
  );

  // iOS Glassmorphic Palette - Dark
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A84FF), // iOS Dark Mode Blue
      primary: const Color(0xFF0A84FF),
      secondary: const Color(0xFF5E5CE6), // iOS Dark Mode Indigo
      tertiary: const Color(0xFFFF9F0A), // iOS Dark Mode Orange
      surface: const Color(0xFF1C1C1E).withOpacity(0.6), // Translucent black/gray
      surfaceContainerHighest: const Color(0xFF2C2C2E), // iOS System Gray 5
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.transparent, // Transparent to show mesh gradient
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF0A84FF)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0A84FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E).withOpacity(0.6),
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5), 
      ),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.75),
      indicatorColor: const Color(0xFF0A84FF).withOpacity(0.2),
      elevation: 0,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1C1E).withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 2),
      ),
    ),
  );
}
