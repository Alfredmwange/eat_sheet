import 'package:flutter/material.dart';
import 'package:eat_sheet/models/user_model.dart';
import 'package:eat_sheet/services/database.dart';
import 'package:eat_sheet/models/weight_entry.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class UserProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  User? _user;
  bool _isLoading = false;
  String? _error;
  List<WeightEntry> _weightEntries = [];

  List<WeightEntry> get weightEntries => _weightEntries;

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
        await loadWeightEntries(userId);
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

  Future<void> loadWeightEntries(String userId) async {
    try {
      final raw = await _databaseService.getWeightEntries(userId);
      _weightEntries = raw
          .map((e) => WeightEntry.fromJson(e))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
    } catch (e) {
      print('Error loading weight entries: $e');
    }
  }

  Future<void> addWeightEntry(String userId, double weight) async {
    final entry = WeightEntry(date: DateTime.now(), weight: weight);
    _weightEntries.add(entry);
    _weightEntries.sort((a, b) => a.date.compareTo(b.date));

    // Also update user's current weight in profile
    if (_user != null) {
      _user = _user!.copyWith(weight: weight, updatedAt: DateTime.now());
    }
    notifyListeners();

    await _databaseService.addWeightEntry(userId, entry.toJson());
    if (_user != null) {
      await _databaseService.updateUserData(userId, {'weight': weight});
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}