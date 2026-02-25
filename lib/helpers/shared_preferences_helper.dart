import 'dart:convert';
import 'dart:developer';
import 'package:eat_sheet/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _userDataKey = 'user_data';

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

  // Logout - clears token and user data but preserves isFirstTime
  static Future<void> clearAll() async {
    await clearUserData();
  }
}