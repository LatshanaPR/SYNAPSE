import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme provider that manages dark/light mode using SharedPreferences
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_themeModeKey);
      if (modeIndex != null && modeIndex >= 0 && modeIndex <= 2) {
        _themeMode = ThemeMode.values[modeIndex];
      } else {
        _themeMode = ThemeMode.dark;
      }
      notifyListeners();
    } catch (e) {
      _themeMode = ThemeMode.dark;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (e) {
      // Revert on error
      _themeMode = ThemeMode.dark;
      notifyListeners();
    }
  }

  /// Toggle between light/dark/system theme modes in order: system -> light -> dark -> system ...
  Future<void> toggleThemeMode() async {
    ThemeMode nextMode;
    switch (_themeMode) {
      case ThemeMode.system:
        nextMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        nextMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        nextMode = ThemeMode.system;
        break;
    }
    await setThemeMode(nextMode);
  }

  bool get isDarkMode {
    // This is only for legacy code, prefer using Theme.of(context).brightness
    return _themeMode == ThemeMode.dark;
  }
}
