import 'package:flutter/material.dart';
import 'package:eat_sheet/helpers/shared_preferences_helper.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePreference() async {
    _isDarkMode = await SharedPreferencesHelper.getTheme() ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await SharedPreferencesHelper.setTheme(_isDarkMode);
    notifyListeners();
  }

  ThemeData getThemeData() {
    if (_isDarkMode) {
      // adjust text colors to be brighter for readability
      final base = ThemeData.dark(useMaterial3: true);
      return base.copyWith(
        primaryColor: Colors.blue.shade600,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: base.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        iconTheme: base.iconTheme.copyWith(color: Colors.white),
        appBarTheme: base.appBarTheme.copyWith(
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarTextStyle: base.textTheme
              .apply(bodyColor: Colors.white, displayColor: Colors.white)
              .bodyMedium,
          titleTextStyle: base.textTheme
              .apply(bodyColor: Colors.white, displayColor: Colors.white)
              .titleLarge,
        ),
      );
    } else {
      return ThemeData.light(useMaterial3: true).copyWith(
        primaryColor: Colors.blue.shade600,
        scaffoldBackgroundColor: Colors.white,
      );
    }
  }
}
