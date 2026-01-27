import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing notes in Firestore
class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _getCurrentUserId() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'User must be signed in to access notes.';
    }
    return user.uid;
  }

  /// Get notes collection reference
  CollectionReference getNotesRef() {
    final userId = _getCurrentUserId();
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  /// Get stream of active notes (not deleted)
  /// Ordered by createdAt desc (updatedAt requires composite index)
  Stream<QuerySnapshot> getNotesStream() {
    try {
      final userId = _getCurrentUserId();
      print('[NotesService] Getting notes stream for user: $userId');
      
      final stream = _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots();
      
      return stream.map((snapshot) {
        print('[NotesService] Received ${snapshot.docs.length} notes');
        return snapshot;
      }).handleError((error) {
        print('[NotesService] Stream error: $error');
        throw Exception(error);
      });
    } catch (e) {
      print('[NotesService] Error creating stream: $e');
      rethrow;
    }
  }

  /// Get stream of deleted notes (trash)
  Stream<QuerySnapshot> getTrashStream() {
    try {
      final userId = _getCurrentUserId();
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .where('isDeleted', isEqualTo: true)
          .orderBy('deletedAt', descending: true)
          .snapshots();
    } catch (e) {
      print('[NotesService] Error getting trash stream: $e');
      final userId = _getCurrentUserId();
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .where('isDeleted', isEqualTo: true)
          .snapshots();
    }
  }

  /// Create a new note
  Future<String> createNote({
    required String title,
    required String content,
    bool isLocked = false,
    String? passwordHash,
  }) async {
    try {
      final userId = _getCurrentUserId();
      final noteData = <String, dynamic>{
        'title': title,
        'content': content,
        'isDeleted': false,
        'isLocked': isLocked,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Only add passwordHash if note is locked and hash is provided
      if (isLocked && passwordHash != null && passwordHash.isNotEmpty) {
        noteData['passwordHash'] = passwordHash;
      }
      
      final ref = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .add(noteData);
      
      print('[NotesService] Created note: ${ref.id}');
      return ref.id;
    } catch (e) {
      print('[NotesService] Error creating note: $e');
      throw 'Failed to create note: ${e.toString()}';
    }
  }

  /// Update an existing note
  Future<void> updateNote({
    required String noteId,
    required String title,
    required String content,
    bool? isLocked,
    String? passwordHash,
  }) async {
    try {
      final Map<String, dynamic> updates = <String, dynamic>{
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (isLocked != null) {
        updates['isLocked'] = isLocked;
        if (isLocked && passwordHash != null) {
          updates['passwordHash'] = passwordHash;
        } else if (!isLocked) {
          // Use FieldValue.delete() to remove the field from Firestore
          updates['passwordHash'] = FieldValue.delete();
        }
      }
      await getNotesRef().doc(noteId).update(updates);
    } catch (e) {
      throw 'Failed to update note: ${e.toString()}';
    }
  }

  /// Soft delete a note (move to trash)
  Future<void> deleteNote(String noteId) async {
    try {
      await getNotesRef().doc(noteId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to delete note: ${e.toString()}';
    }
  }

  /// Restore a note from trash
  Future<void> restoreNote(String noteId) async {
    try {
      await getNotesRef().doc(noteId).update({
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to restore note: ${e.toString()}';
    }
  }

  /// Permanently delete a note
  Future<void> permanentlyDeleteNote(String noteId) async {
    try {
      await getNotesRef().doc(noteId).delete();
    } catch (e) {
      throw 'Failed to permanently delete note: ${e.toString()}';
    }
  }
}
