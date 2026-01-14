import 'package:firebase_auth/firebase_auth.dart';

/// Authentication service for handling Firebase Authentication
/// This service provides methods for user sign up, login, logout, password reset,
/// and getting the current user.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current authenticated user
  /// Returns null if no user is currently signed in
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign up a new user with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password (should be at least 6 characters)
  /// 
  /// Returns the [User] object if sign up is successful
  /// Throws an exception with a readable error message if sign up fails
  Future<User?> signUp(String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign in an existing user with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// 
  /// Returns the [User] object if login is successful
  /// Throws an exception with a readable error message if login fails
  Future<User?> login(String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign out the current user
  /// 
  /// Throws an exception with a readable error message if logout fails
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An error occurred while signing out. Please try again.';
    }
  }

  /// Send a password reset email to the user
  /// 
  /// [email] - User's email address
  /// 
  /// Throws an exception with a readable error message if sending fails
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An error occurred while sending password reset email. Please try again.';
    }
  }

  /// Handle Firebase Authentication exceptions and convert them to readable messages
  /// 
  /// [e] - The FirebaseAuthException to handle
  /// 
  /// Returns a user-friendly error message string
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please use a different email or sign in.';
      case 'invalid-email':
        return 'The email address is invalid. Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }
}
