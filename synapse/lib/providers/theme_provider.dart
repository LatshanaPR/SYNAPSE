import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme provider that manages dark/light mode using SharedPreferences
class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode_enabled';
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_darkModeKey) ?? true; // Default to dark mode
      notifyListeners();
    } catch (e) {
      // Default to dark mode on error
      _isDarkMode = true;
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    try {
      _isDarkMode = enabled;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, enabled);
    } catch (e) {
      // Revert on error
      _isDarkMode = !enabled;
      notifyListeners();
    }
  }

  /// Toggle the current theme mode and persist the change.
  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }
}
