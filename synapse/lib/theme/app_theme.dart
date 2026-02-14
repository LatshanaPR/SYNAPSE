import 'package:flutter/material.dart';

class AppTheme {
  // Netflix-style red color
  static const Color netflixRed = Color(0xFFE50914);

  static const Color _darkBackground = Color(0xFF0B0B0B);
  static const Color _darkSurface = Color(0xFF141414);
  static const Color _lightBackground = Color(0xFFF5F5F5);
  static const Color _lightSurface = Color(0xFFFAFAFA);

  static ThemeData get darkTheme {
    final base = ColorScheme.fromSeed(
      seedColor: netflixRed,
      brightness: Brightness.dark,
    );
    final scheme = base.copyWith(
      primary: netflixRed,
      background: _darkBackground,
      surface: _darkSurface,
    );

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: netflixRed,
      scaffoldBackgroundColor: scheme.background,
      colorScheme: scheme,
      fontFamily: 'Roboto',
    );
  }

  static ThemeData get lightTheme {
    final base = ColorScheme.fromSeed(
      seedColor: netflixRed,
      brightness: Brightness.light,
    );
    final scheme = base.copyWith(
      primary: netflixRed,
      background: _lightBackground,
      surface: _lightSurface,
    );

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: netflixRed,
      scaffoldBackgroundColor: scheme.background,
      colorScheme: scheme,
      fontFamily: 'Roboto',
    );
  }
}
