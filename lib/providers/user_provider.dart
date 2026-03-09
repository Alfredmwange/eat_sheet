import 'package:flutter/material.dart';
import 'package:eat_sheet/models/user_model.dart';
import 'package:eat_sheet/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class UserProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userData = await _databaseService.getUserData(userId);
      if (userData != null) {
        _user = User.fromJson(userData);
      }
    } catch (e) {
      _error = 'Failed to load user data: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserData(User updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _databaseService.updateUserData(
        updatedUser.id,
        updatedUser.toJson(),
      );
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update user data: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      // Delete user data from Firestore
      if (_user != null) {
        await _databaseService.deleteUserData(_user!.id);
      }

      // Delete Firebase Auth user
      await fb.FirebaseAuth.instance.currentUser?.delete();
      _user = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete account: $e';
      print(_error);
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
