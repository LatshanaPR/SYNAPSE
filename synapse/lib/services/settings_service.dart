import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing user settings in Firestore
class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current authenticated user ID
  String _getCurrentUserId() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'User must be signed in to access settings.';
    }
    return user.uid;
  }

  /// Get user settings document reference
  DocumentReference getSettingsRef() {
    final String userId = _getCurrentUserId();
    return _firestore.collection('users').doc(userId).collection('settings').doc('preferences');
  }

  /// Internal method for accessing settings ref (kept for backward compatibility)
  DocumentReference _getSettingsRef() => getSettingsRef();

  /// Get notification enabled status
  /// Returns true by default if not set
  Future<bool> getNotificationsEnabled() async {
    try {
      final doc = await _getSettingsRef().get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['notificationsEnabled'] ?? true;
      }
      return true; // Default to enabled
    } catch (e) {
      return true; // Default to enabled on error
    }
  }

  /// Set notification enabled status
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await _getSettingsRef().set({
        'notificationsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update notification settings: ${e.toString()}';
    }
  }

  /// Get alarm enabled status
  /// Returns true by default if not set
  Future<bool> getAlarmsEnabled() async {
    try {
      final doc = await _getSettingsRef().get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['alarmsEnabled'] ?? true;
      }
      return true; // Default to enabled
    } catch (e) {
      return true; // Default to enabled on error
    }
  }

  /// Set alarm enabled status
  Future<void> setAlarmsEnabled(bool enabled) async {
    try {
      await _getSettingsRef().set({
        'alarmsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update alarm settings: ${e.toString()}';
    }
  }

  /// Get dark mode enabled status
  /// Returns true by default if not set
  Future<bool> getDarkModeEnabled() async {
    try {
      final doc = await _getSettingsRef().get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['darkModeEnabled'] ?? true;
      }
      return true; // Default to dark mode
    } catch (e) {
      return true; // Default to dark mode on error
    }
  }

  /// Set dark mode enabled status
  Future<void> setDarkModeEnabled(bool enabled) async {
    try {
      await _getSettingsRef().set({
        'darkModeEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update dark mode settings: ${e.toString()}';
    }
  }

  /// Get stream of settings changes
  Stream<Map<String, dynamic>> getSettingsStream() {
    return _getSettingsRef().snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return <String, dynamic>{
        'notificationsEnabled': true,
        'alarmsEnabled': true,
        'darkModeEnabled': true,
      };
    });
  }
}
