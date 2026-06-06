import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:badr/core/constants/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider(String saved) : _themeMode = _fromString(saved);

  ThemeMode get themeMode => _themeMode;

  static ThemeMode _fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(String value) async {
    _themeMode = _fromString(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, value);
    notifyListeners();
  }
}
