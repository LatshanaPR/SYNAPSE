import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// Service for managing user profile data in Firestore
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _getCurrentUserId() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'User must be signed in to access profile.';
    }
    return user.uid;
  }

  /// Get profile document reference (users/{uid}/profile/info)
  DocumentReference getProfileRef() {
    final String userId = _getCurrentUserId();
    return _firestore.collection('users').doc(userId).collection('profile').doc('info');
  }

  /// Get profile data stream
  Stream<Map<String, dynamic>> getProfileStream() {
    return getProfileRef().snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return <String, dynamic>{};
    });
  }

  /// Get profile data once
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final doc = await getProfileRef().get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return <String, dynamic>{};
    } catch (e) {
      throw 'Failed to get profile: ${e.toString()}';
    }
  }

  /// Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      final userId = _getCurrentUserId();
      final user = _auth.currentUser;
      await getProfileRef().set({
        'displayName': displayName,
        'email': user?.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update display name: ${e.toString()}';
    }
  }

  /// Upload profile photo and update photoUrl
  Future<String> uploadProfilePhoto(File imageFile) async {
    try {
      final userId = _getCurrentUserId();
      final ref = _storage.ref().child('users/$userId/profile.jpg');
      
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      await getProfileRef().set({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload photo: ${e.toString()}';
    }
  }

  /// Update both display name and photo URL
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) {
        updates['displayName'] = displayName;
      }
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }
      await getProfileRef().set(updates, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update profile: ${e.toString()}';
    }
  }
}
