// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFoodEntry(Map<String, dynamic> foodData) async {
    try {
      await _firestore.collection('foodEntries').add(foodData);
    } catch (e) {
      print('Error adding food entry: $e');
    }
  }

  Stream<QuerySnapshot> getFoodEntries() {
    return _firestore.collection('foodEntries').snapshots();
  }

  // User data management
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  // ── Meal logs ────────────────────────────────

  /// Save today's full meal log for a user (overwrites the day's doc)
  Future<void> saveMealLog(String userId, Map<String, dynamic> logData) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '\${today.year}-\${today.month.toString().padLeft(2,';0;')}-\${today.day.toString().padLeft(2,';0;')}';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mealLogs')
          .doc(dateKey)
          .set(logData, SetOptions(merge: false));
    } catch (e) {
      print('Error saving meal log: \$e');
    }
  }

  /// Get today's meal log for a user
  Future<Map<String, dynamic>?> getTodayMealLog(String userId) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '\${today.year}-\${today.month.toString().padLeft(2,';0;')}-\${today.day.toString().padLeft(2,';0;')}';
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mealLogs')
          .doc(dateKey)
          .get();
      return doc.data();
    } catch (e) {
      print('Error fetching meal log: \$e');
      return null;
    }
  }

  // ── Weight entries ───────────────────────────

  Future<void> addWeightEntry(String userId, Map<String, dynamic> entry) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weightEntries')
          .add(entry);
    } catch (e) {
      print('Error adding weight entry: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWeightEntries(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weightEntries')
          .orderBy('date', descending: false)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('Error fetching weight entries: $e');
      return [];
    }
  }

  Future<void> deleteUserData(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user data: $e');
    }
  }
}