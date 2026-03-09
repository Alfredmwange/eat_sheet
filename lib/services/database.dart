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

  Future<void> deleteUserData(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user data: $e');
    }
  }
}
