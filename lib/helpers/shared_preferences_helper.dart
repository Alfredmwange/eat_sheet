import 'dart:convert';
import 'dart:developer';
import 'package:eat_sheet/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _userDataKey = 'user_data';
  static const String _themeKey = 'is_dark_mode';
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  // First time user check
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstTimeKey) ?? true;
  }

  static Future<void> setFirstTimeComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, false);
  }

  // User data storage
  static Future<void> setUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userDataKey, userJson);
  }

  /// Get user data
  static Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString(_userDataKey);

    if (userJsonString == null) {
      return null;
    }

    try {
      final userJson = jsonDecode(userJsonString) as Map<String, dynamic>;
      return User.fromJson(userJson);
    } catch (e) {
      log('Error decoding user data: $e');
      return null;
    }
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    final user = await getUserData();
    return user?.email;
  }

  // Theme management
  static Future<bool?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey);
  }

  static Future<void> setTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  // Remember-me credentials
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  static Future<void> setRememberMe(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, remember);
  }

  static Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedEmailKey, email);
    await prefs.setString(_savedPasswordKey, password);
  }

  static Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_savedEmailKey);
    final password = prefs.getString(_savedPasswordKey);
    if (email == null || password == null) return null;
    return {'email': email, 'password': password};
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
    await prefs.setBool(_rememberMeKey, false);
  }

  // Logout - clears token and user data but preserves isFirstTime
  static Future<void> clearAll() async {
    await clearUserData();
  }
}
