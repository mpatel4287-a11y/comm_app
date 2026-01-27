// lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _prefKey = 'is_dark_mode';
  static const String _fontScaleKey = 'font_scale';

  bool _isDarkMode = false;
  bool _isInitialized = false;
  double _fontScale = 1.0; // 1.0 = default size

  bool get isDarkMode => _isDarkMode;
  double get textScale => _fontScale;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_prefKey) ?? false;
    _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
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
    // Clamp to a reasonable range for readability
    _fontScale = scale.clamp(0.8, 1.4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, _fontScale);
    notifyListeners();
  }

  ThemeData getTheme() {
    final baseTheme = _isDarkMode ? _darkTheme : _lightTheme;

    final scaledTextTheme = _scaleTextTheme(baseTheme.textTheme, _fontScale);

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      primaryTextTheme: scaledTextTheme,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        titleTextStyle: (baseTheme.appBarTheme.titleTextStyle ??
                baseTheme.textTheme.titleLarge ??
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))
            .copyWith(
          fontSize:
              (baseTheme.textTheme.titleLarge?.fontSize ?? 20) * _fontScale,
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

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF122C4F),
      primary: const Color(0xFF122C4F),
      secondary: const Color(0xFF5B88B2),
      tertiary: const Color(0xFFFBF9E4),
      surface: Colors.white, 
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF122C4F),
      foregroundColor: Color(0xFFFBF9E4),
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF122C4F),
        foregroundColor: const Color(0xFFFBF9E4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF122C4F),
      primary: const Color(0xFF5B88B2),
      secondary: const Color(0xFF122C4F),
      tertiary: const Color(0xFFFBF9E4),
      surface: const Color(0xFF121212),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000), // Noir
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
  );
}
