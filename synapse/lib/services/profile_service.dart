import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;

/// Service for managing user profile data in Firestore
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  /// Compress image and convert to Base64 string
  Future<String> _compressImageToBase64(File imageFile) async {
    try {
      // Read image file
      final bytes = await imageFile.readAsBytes();
      
      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw 'Failed to decode image';
      }

      // Resize image to max 400x400 while maintaining aspect ratio
      if (image.width > 400 || image.height > 400) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 400 : null,
          height: image.height > image.width ? 400 : null,
        );
      }

      // Compress as JPEG with quality 70
      final compressedBytes = img.encodeJpg(image, quality: 70);
      
      // Check size (limit to ~350KB after Base64 encoding)
      // Base64 increases size by ~33%, so 350KB * 0.75 = ~262KB raw
      if (compressedBytes.length > 262000) {
        throw 'Image too large even after compression. Please use a smaller image.';
      }

      // Convert to Base64
      final base64String = base64Encode(compressedBytes);
      return base64String;
    } catch (e) {
      throw 'Failed to process image: ${e.toString()}';
    }
  }

  /// Save profile photo as Base64 in Firestore
  Future<void> saveProfilePhoto(File imageFile) async {
    try {
      final base64String = await _compressImageToBase64(imageFile);
      
      await getProfileRef().set({
        'photoBase64': base64String,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save photo: ${e.toString()}';
    }
  }

  /// Update both display name and photo Base64
  Future<void> updateProfile({
    String? displayName,
    String? photoBase64,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) {
        updates['displayName'] = displayName;
      }
      if (photoBase64 != null) {
        updates['photoBase64'] = photoBase64;
      }
      await getProfileRef().set(updates, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update profile: ${e.toString()}';
    }
  }
}
