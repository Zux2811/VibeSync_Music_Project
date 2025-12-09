import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.dark;

  AppThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == AppThemeMode.dark;

  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  Future<void> _loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode');
      if (savedTheme != null) {
        _themeMode =
            savedTheme == 'dark' ? AppThemeMode.dark : AppThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  // Preview the theme without saving to preferences
  void previewTheme(AppThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  // Set and save the theme to preferences
  Future<void> setTheme(AppThemeMode mode) async {
    _themeMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'theme_mode',
        mode == AppThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      print('Error saving theme: $e');
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == AppThemeMode.dark
            ? AppThemeMode.light
            : AppThemeMode.dark;
    await setTheme(newMode);
  }
}
