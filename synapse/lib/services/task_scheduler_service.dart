import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';
import 'alarm_service.dart';
import 'settings_service.dart';
import 'task_service.dart';

/// Service that monitors tasks and triggers notifications/alarms at their scheduled times
class TaskSchedulerService {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  final AlarmService _alarmService = AlarmService();
  final SettingsService _settingsService = SettingsService();
  
  StreamSubscription<QuerySnapshot>? _tasksSubscription;
  BuildContext? _context;
  final Map<String, Timer> _activeTimers = {};
  bool _isRunning = false;

  /// Start monitoring tasks
  /// [context] - BuildContext for showing alarms
  Future<void> startMonitoring(BuildContext? context) async {
    if (_isRunning) return;
    
    _context = context;
    _isRunning = true;

    // Initialize notification service
    await _notificationService.initialize();
    await _notificationService.requestPermissions();

    // Listen to tasks stream
    _tasksSubscription = _taskService.getTasks().listen(
      (snapshot) => _processTasks(snapshot),
      onError: (error) => print('Task scheduler error: $error'),
    );
  }

  /// Stop monitoring tasks
  void stopMonitoring() {
    _isRunning = false;
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
    
    // Cancel all active timers
    for (var timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  /// Process tasks from Firestore stream
  Future<void> _processTasks(QuerySnapshot snapshot) async {
    // Cancel all existing timers
    for (var timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();

    // Check settings
    final notificationsEnabled = await _settingsService.getNotificationsEnabled();
    final alarmsEnabled = await _settingsService.getAlarmsEnabled();

    if (!notificationsEnabled && !alarmsEnabled) {
      return; // Both disabled, no need to schedule
    }

    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Skip deleted or completed tasks
      if (data['isDeleted'] == true || data['status'] == 'Complete') {
        continue;
      }

      final taskId = doc.id;
      final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
      final snoozedUntil = (data['snoozedUntil'] as Timestamp?)?.toDate();
      final priority = data['priority'] as String?;
      final title = data['title'] as String? ?? 'Task';
      final description = data['description'] as String?;
      final soundPath = data['soundPath'] as String?;

      // Use snoozedUntil if it exists and is in the future, otherwise use dateTime
      DateTime? reminderTime;
      bool isSnoozed = false;
      String? snoozedUntilText;
      
      if (snoozedUntil != null && snoozedUntil.isAfter(now)) {
        reminderTime = snoozedUntil;
        isSnoozed = true;
        // Format snooze text for display
        final timeFormat = DateFormat('dd MMM, HH:mm');
        snoozedUntilText = 'Snoozed until ${timeFormat.format(snoozedUntil)}';
      } else if (dateTime != null && dateTime.isAfter(now)) {
        reminderTime = dateTime;
        // Clear snoozedUntil and isSnoozed if snoozedUntil is in the past
        if (snoozedUntil != null && snoozedUntil.isBefore(now)) {
          await _taskService.updateTask(taskId, {
            'snoozedUntil': null,
            'isSnoozed': false,
          });
          print('Cleared expired snooze state for task $taskId');
        }
      } else {
        // No future reminder time, but clear snooze state if present
        if (snoozedUntil != null && snoozedUntil.isBefore(now)) {
          await _taskService.updateTask(taskId, {
            'snoozedUntil': null,
            'isSnoozed': false,
          });
          print('Cleared expired snooze state for task $taskId (no future dateTime)');
        }
      }

      if (reminderTime == null) continue;

      // Only schedule tasks in the future
      if (reminderTime.isAfter(now)) {
        final duration = reminderTime.difference(now);
        
        // Schedule the notification/alarm
        final timer = Timer(duration, () async {
          // If this is a snoozed reminder, clear snoozedUntil and isSnoozed after firing
          if (isSnoozed) {
            try {
              await _taskService.updateTask(taskId, {
                'snoozedUntil': null,
                'isSnoozed': false,
              });
            } catch (e) {
              print('Error clearing snoozedUntil: $e');
            }
          }
          
          await _triggerTaskReminder(
            taskId: taskId,
            title: title,
            description: description,
            priority: priority ?? 'Medium',
            soundPath: soundPath,
            notificationsEnabled: notificationsEnabled,
            alarmsEnabled: alarmsEnabled,
            snoozedUntilText: isSnoozed ? snoozedUntilText : null,
          );
          _activeTimers.remove(taskId);
        });

        _activeTimers[taskId] = timer;
      } else if (dateTime != null && !dateTime.isAfter(now)) {
        // Task is in the past, trigger immediately if not too old (within last hour)
        final timeDiff = now.difference(dateTime);
        if (timeDiff.inHours < 1 && _activeTimers.containsKey(taskId) == false) {
          await _triggerTaskReminder(
            taskId: taskId,
            title: title,
            description: description,
            priority: priority ?? 'Medium',
            soundPath: soundPath,
            notificationsEnabled: notificationsEnabled,
            alarmsEnabled: alarmsEnabled,
          );
        }
      }
    }
  }

  /// Trigger a task reminder based on priority
  Future<void> _triggerTaskReminder({
    required String taskId,
    required String title,
    String? description,
    required String priority,
    String? soundPath,
    required bool notificationsEnabled,
    required bool alarmsEnabled,
    String? snoozedUntilText,
  }) async {
    // High priority → full-screen alarm
    if (priority == 'High' && alarmsEnabled && _context != null) {
        String? alarmDescription = description;
        if (snoozedUntilText != null) {
          alarmDescription = snoozedUntilText;
          if (description != null && description.isNotEmpty) {
            alarmDescription = '$snoozedUntilText\n\n$description';
          }
        }
        
        await _alarmService.showAlarm(
          context: _context!,
          taskId: taskId,
          title: title,
          description: alarmDescription,
          soundPath: soundPath,
          onSnooze: (duration) => handleSnooze(
            taskId: taskId,
            title: title,
            description: description,
            priority: priority,
            soundPath: soundPath,
            duration: duration,
            isAlarm: true,
            context: _context,
          ),
          onDismiss: () {
            // Alarm dismissed - do nothing
          },
        );
    }
    // Normal/Medium priority → notification
    else if ((priority == 'Medium' || priority == 'Low' || priority == 'Normal') && notificationsEnabled) {
      final body = snoozedUntilText != null
          ? snoozedUntilText
          : (description?.isNotEmpty == true ? description : 'Task reminder');
      
      await _notificationService.showTaskNotification(
        taskId: taskId,
        title: title,
        body: body,
        soundPath: soundPath,
        onSnooze: (duration) => handleSnooze(
          taskId: taskId,
          title: title,
          description: description,
          priority: priority,
          soundPath: soundPath,
          duration: duration,
          isAlarm: false,
          context: _context,
        ),
      );
    }
  }


  /// Handle snooze for both notifications and alarms
  /// Works offline - reschedules immediately, Firestore update is non-blocking
  /// Shows error if max snooze limit (5) reached
  Future<void> handleSnooze({
    required String taskId,
    required String title,
    String? description,
    required String priority,
    String? soundPath,
    required Duration duration,
    required bool isAlarm,
    BuildContext? context,
  }) async {
    final now = DateTime.now();
    final snoozedUntil = now.add(duration);

    try {
      // 1. Cancel current notification/alarm FIRST (local operation, always works)
      if (isAlarm) {
        await _alarmService.stopCurrentAlarm();
      } else {
        await _notificationService.cancelNotification(taskId);
      }
      print('[SNOOZE] ✓ Cancelled current ${isAlarm ? "alarm" : "notification"}');

      // 2. Try to get task data from Firestore (non-blocking, with timeout)
      Map<String, dynamic>? currentData;
      int currentSnoozeCount = 0;

      try {
        final taskDoc = await _taskService.getTasks().first
            .timeout(const Duration(seconds: 3), onTimeout: () => throw 'Timeout getting tasks');
        
        final currentTask = taskDoc.docs.firstWhere(
          (doc) => doc.id == taskId,
          orElse: () => throw 'Task not found: $taskId',
        );
        
        currentData = currentTask.data() as Map<String, dynamic>;
        currentSnoozeCount = (currentData['snoozeCount'] as int?) ?? 0;
        print('[SNOOZE] ✓ Got task data from Firestore - snoozeCount: $currentSnoozeCount');
      } catch (e) {
        print('[WARN] Could not get task data from Firestore (offline?): $e');
        print('[SNOOZE] Continuing with snooze anyway - will use fallback timer');
        // Continue without Firestore data - use fallback timer-based snooze
      }

      // 3. Check snooze limit (max 5 snoozes) - only if we got data from Firestore
      if (currentData != null && currentSnoozeCount >= 5) {
        print('Snooze limit reached for task $taskId (snoozeCount: $currentSnoozeCount)');
        
        // Show error message
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This task cannot be snoozed anymore (max 5 snoozes)'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Show notification with error message
        if (!isAlarm) {
          await _notificationService.showTaskNotification(
            taskId: taskId,
            title: title,
            body: 'Cannot snooze: Max limit reached (5 snoozes)',
            soundPath: null,
            onSnooze: null, // No snooze actions when limit reached
          );
        }
        
        return; // Exit without rescheduling
      }

      final newSnoozeCount = currentSnoozeCount + 1;
      
      print('Snoozing task $taskId:');
      print('  - Current snoozeCount: $currentSnoozeCount');
      print('  - New snoozedUntil: $snoozedUntil');
      print('  - New snoozeCount: $newSnoozeCount');

      // 4. Reschedule immediately using timer-based approach (works offline)
      // This ensures snooze works even if Firestore is unavailable
      _scheduleSnoozeTimer(taskId, title, description, priority, soundPath, duration, isAlarm);
      print('[SNOOZE] ✓ Rescheduled reminder for $snoozedUntil (works offline)');

      // 5. Update Firestore in background (non-blocking, fire-and-forget)
      // This is for UI updates and history - failure won't stop snooze
      if (currentData != null) {
        _updateFirestoreSnoozeStateBackground(taskId, snoozedUntil, newSnoozeCount);
      } else {
        print('[WARN] Skipping Firestore update - no task data available, using timer fallback');
      }

    } catch (e) {
      print('Error handling snooze: $e');
      print('Stack trace: ${StackTrace.current}');
      // Fallback: Use timer-based snooze if anything fails
      _scheduleSnoozeTimer(taskId, title, description, priority, soundPath, duration, isAlarm);
    }
  }

  /// Update Firestore snooze state in background (non-blocking, fire-and-forget)
  /// This is wrapped in try-catch and won't stop snooze if it fails
  void _updateFirestoreSnoozeStateBackground(String taskId, DateTime snoozedUntil, int newSnoozeCount) {
    // Fire-and-forget: don't await, wrap in try-catch
    Future.microtask(() async {
      try {
        await _taskService.updateTask(taskId, {
          'snoozedUntil': Timestamp.fromDate(snoozedUntil),
          'snoozeCount': newSnoozeCount,
          'isSnoozed': true,
        });
        print('[SNOOZE] ✓ Firestore updated (background) - snoozedUntil: $snoozedUntil, snoozeCount: $newSnoozeCount');
      } catch (e, stackTrace) {
        // Log error but don't throw - snooze already worked locally
        print('[WARN] Firestore update failed (offline?) - snooze still works: $e');
        print('[WARN] Stack trace: $stackTrace');
        // Reminder was already rescheduled via timer, so this is just for UI/history
      }
    });
  }

  /// Fallback timer-based snooze (used if Firestore update fails)
  void _scheduleSnoozeTimer(
    String taskId,
    String title,
    String? description,
    String priority,
    String? soundPath,
    Duration duration,
    bool isAlarm,
  ) {
    final timer = Timer(duration, () async {
      final notificationsEnabled = await _settingsService.getNotificationsEnabled();
      final alarmsEnabled = await _settingsService.getAlarmsEnabled();

      if (isAlarm && alarmsEnabled && _context != null) {
        await _alarmService.showAlarm(
          context: _context!,
          taskId: taskId,
          title: title,
          description: description,
          soundPath: soundPath,
          onSnooze: (duration) => handleSnooze(
            taskId: taskId,
            title: title,
            description: description,
            priority: priority,
            soundPath: soundPath,
            duration: duration,
            isAlarm: true,
            context: _context,
          ),
          onDismiss: () {
            // Alarm dismissed - do nothing
          },
        );
      } else if (!isAlarm && notificationsEnabled) {
        await _notificationService.showTaskNotification(
          taskId: taskId,
          title: title,
          body: description?.isNotEmpty == true ? description : 'Task reminder',
          soundPath: soundPath,
          onSnooze: (duration) => handleSnooze(
            taskId: taskId,
            title: title,
            description: description,
            priority: priority,
            soundPath: soundPath,
            duration: duration,
            isAlarm: false,
            context: _context,
          ),
        );
      }
      _activeTimers.remove('snooze_$taskId');
    });

    _activeTimers['snooze_$taskId'] = timer;
  }

  /// Update context (called when navigation changes)
  void updateContext(BuildContext? context) {
    _context = context;
  }
}
