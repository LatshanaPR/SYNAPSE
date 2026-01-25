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
      // Note: We filter out deleted tasks in the UI layer to avoid index requirements
      return tasksRef.orderBy('dateTime', descending: false).snapshots();
    } catch (e) {
      throw 'Failed to get tasks: ${e.toString()}';
    }
  }

  /// One-time fetch of tasks (for overdue check). Uses same ordering as getTasks().
  Future<QuerySnapshot> _getTasksSnapshot() async {
    final String userId = _getCurrentUserId();
    final tasksRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks');
    return tasksRef.orderBy('dateTime', descending: false).get();
  }

  /// effectiveDueTime = snoozedUntil ?? dateTime. Returns null if both missing.
  static DateTime? getEffectiveDueTime(Map<String, dynamic> data) {
    final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
    final snoozedUntil = (data['snoozedUntil'] as Timestamp?)?.toDate();
    if (snoozedUntil != null) return snoozedUntil;
    return dateTime;
  }

  /// Run overdue check: if status != Complete and now > effectiveDueTime, set status = notDone.
  /// Call on app start, when opening task list/dashboard, and when tasks are fetched.
  Future<void> runOverdueCheck() async {
    try {
      final snapshot = await _getTasksSnapshot();
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isDeleted'] == true) continue;

        final status = data['status'] as String? ?? 'ToDo';
        if (status == 'Complete') continue;

        final effectiveDue = getEffectiveDueTime(data);
        if (effectiveDue == null) continue;
        if (now.isBefore(effectiveDue) || now.isAtSameMomentAs(effectiveDue)) continue;

        await updateTask(doc.id, {'status': 'notDone'});
      }
    } catch (e) {
      // Non-blocking; log and continue
      print('[TaskService] runOverdueCheck error: $e');
    }
  }

  /// Add a new task to Firestore.
  /// Returns the new document ID.
  Future<String> addTask(Map<String, dynamic> taskData) async {
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
      if (status != 'ToDo' && status != 'Complete' && status != 'Review' && status != 'notDone') {
        throw 'Status must be one of: ToDo, Complete, Review, or notDone.';
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
      
      // Set initial updatedAt
      taskData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Set isDeleted to false by default
      taskData['isDeleted'] = false;
      
      // Get reference to the tasks collection for the current user
      final CollectionReference tasksRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks');
      
      // Add the task to Firestore (document ID will be auto-generated)
      final docRef = await tasksRef.add(taskData);
      return docRef.id;
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
      if (status != 'ToDo' && status != 'Complete' && status != 'Review' && status != 'notDone') {
        throw 'Status must be one of: ToDo, Complete, Review, or notDone.';
      }
      
      // Get reference to the specific task document
      final DocumentReference taskRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId);
      
      // Update status and updatedAt fields
      await taskRef.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update task status: ${e.toString()}';
    }
  }

  /// Update an existing task with new field values
  /// 
  /// [taskId] - The document ID of the task to update
  /// [updatedFields] - A map of fields to update (title, description, priority, dateTime, etc.)
  /// 
  /// Throws an exception if:
  ///   - User is not signed in
  ///   - Task update fails
  Future<void> updateTask(String taskId, Map<String, dynamic> updatedFields) async {
    try {
      final String userId = _getCurrentUserId();
      
      // Validate updated fields if they're provided
      if (updatedFields.containsKey('title') && 
          (updatedFields['title'] == null || (updatedFields['title'] as String).trim().isEmpty)) {
        throw 'Task title cannot be empty.';
      }
      
      if (updatedFields.containsKey('priority')) {
        final String priority = updatedFields['priority'];
        if (priority != 'High' && priority != 'Medium' && priority != 'Low') {
          throw 'Priority must be one of: High, Medium, or Low.';
        }
      }
      
      if (updatedFields.containsKey('status')) {
        final String status = updatedFields['status'];
        if (status != 'ToDo' && status != 'Complete' && status != 'Review' && status != 'notDone') {
          throw 'Status must be one of: ToDo, Complete, Review, or notDone.';
        }
      }
      
      // Get reference to the specific task document
      final DocumentReference taskRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId);
      
      // Add updatedAt timestamp
      updatedFields['updatedAt'] = FieldValue.serverTimestamp();
      
      // Update the task
      await taskRef.update(updatedFields);
    } catch (e) {
      throw 'Failed to update task: ${e.toString()}';
    }
  }

  /// Soft delete a task by setting isDeleted to true
  /// 
  /// [taskId] - The document ID of the task to delete
  /// 
  /// Throws an exception if:
  ///   - User is not signed in
  ///   - Task deletion fails
  Future<void> softDeleteTask(String taskId) async {
    try {
      final String userId = _getCurrentUserId();
      
      // Get reference to the specific task document
      final DocumentReference taskRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId);
      
      // Soft delete by setting isDeleted to true
      await taskRef.update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to delete task: ${e.toString()}';
    }
  }
}
