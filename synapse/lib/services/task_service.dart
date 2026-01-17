import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Task service for handling Firestore operations related to tasks
/// This service provides methods for retrieving, adding, and updating tasks
/// for the currently authenticated user.
class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current authenticated user ID
  /// Throws an exception if no user is currently signed in
  String _getCurrentUserId() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'User must be signed in to perform task operations.';
    }
    return user.uid;
  }

  /// Get a stream of all tasks for the current user
  /// 
  /// Returns a [Stream<QuerySnapshot>] that emits updates whenever tasks change
  /// Tasks are automatically ordered by dateTime (ascending - earliest first)
  /// 
  /// Throws an exception if user is not signed in
  Stream<QuerySnapshot> getTasks() {
    try {
      final String userId = _getCurrentUserId();
      
      // Get reference to the tasks collection for the current user
      final CollectionReference tasksRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks');
      
      // Return a stream that listens to real-time updates
      // Ordered by dateTime timestamp in ascending order (earliest first)
      return tasksRef.orderBy('dateTime', descending: false).snapshots();
    } catch (e) {
      throw 'Failed to get tasks: ${e.toString()}';
    }
  }

  /// Add a new task to Firestore
  /// 
  /// [taskData] - A map containing task information:
  ///   - title (String, required)
  ///   - description (String, required)
  ///   - status (String, required - must be: ToDo, Complete, or Review)
  ///   - priority (String, required - must be: High, Medium, or Low)
  ///   - dateTime (Timestamp, required)
  ///   - createdAt (Timestamp, optional - will be set to current time if not provided)
  /// 
  /// Throws an exception if:
  ///   - User is not signed in
  ///   - Required fields are missing
  ///   - Task creation fails
  Future<void> addTask(Map<String, dynamic> taskData) async {
    try {
      final String userId = _getCurrentUserId();
      
      // Validate required fields
      if (!taskData.containsKey('title') || taskData['title'] == null || (taskData['title'] as String).trim().isEmpty) {
        throw 'Task title is required.';
      }
      // Description is optional - set to empty string if not provided
      if (!taskData.containsKey('description') || taskData['description'] == null) {
        taskData['description'] = '';
      }
      if (!taskData.containsKey('status') || taskData['status'] == null) {
        throw 'Task status is required.';
      }
      if (!taskData.containsKey('priority') || taskData['priority'] == null) {
        throw 'Task priority is required.';
      }
      if (!taskData.containsKey('dateTime') || taskData['dateTime'] == null) {
        throw 'Task dateTime is required.';
      }
      
      // Validate status value
      final String status = taskData['status'];
      if (status != 'ToDo' && status != 'Complete' && status != 'Review') {
        throw 'Status must be one of: ToDo, Complete, or Review.';
      }
      
      // Validate priority value
      final String priority = taskData['priority'];
      if (priority != 'High' && priority != 'Medium' && priority != 'Low') {
        throw 'Priority must be one of: High, Medium, or Low.';
      }
      
      // Ensure createdAt is set (use current time if not provided)
      if (!taskData.containsKey('createdAt') || taskData['createdAt'] == null) {
        taskData['createdAt'] = FieldValue.serverTimestamp();
      }
      
      // Get reference to the tasks collection for the current user
      final CollectionReference tasksRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks');
      
      // Add the task to Firestore (document ID will be auto-generated)
      await tasksRef.add(taskData);
    } catch (e) {
      throw 'Failed to add task: ${e.toString()}';
    }
  }

  /// Update the status of an existing task
  /// 
  /// [taskId] - The document ID of the task to update
  /// [status] - The new status value (must be: ToDo, Complete, or Review)
  /// 
  /// Throws an exception if:
  ///   - User is not signed in
  ///   - Invalid status value
  ///   - Task update fails
  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      final String userId = _getCurrentUserId();
      
      // Validate status value
      if (status != 'ToDo' && status != 'Complete' && status != 'Review') {
        throw 'Status must be one of: ToDo, Complete, or Review.';
      }
      
      // Get reference to the specific task document
      final DocumentReference taskRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId);
      
      // Update only the status field
      await taskRef.update({'status': status});
    } catch (e) {
      throw 'Failed to update task status: ${e.toString()}';
    }
  }
}
