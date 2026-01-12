import 'package:flutter/material.dart';

class AppTheme {
  // Netflix-style red color
  static const Color netflixRed = Color(0xFFE50914);
  static const Color black = Color(0xFF000000);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: netflixRed,
      scaffoldBackgroundColor: black,
      colorScheme: const ColorScheme.dark(
        primary: netflixRed,
        surface: black,
      ),
      fontFamily: 'Roboto',
    );
  }
}
