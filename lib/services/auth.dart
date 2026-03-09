import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser {
    return _auth.currentUser;
  }

  // Stream to listen to authentication state changes
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Register with email and password
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}
