import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      final priority = data['priority'] as String?;
      final title = data['title'] as String? ?? 'Task';
      final description = data['description'] as String?;
      final soundPath = data['soundPath'] as String?;

      if (dateTime == null) continue;

      // Only schedule tasks in the future
      if (dateTime.isAfter(now)) {
        final duration = dateTime.difference(now);
        
        // Schedule the notification/alarm
        final timer = Timer(duration, () async {
          await _triggerTaskReminder(
            taskId: taskId,
            title: title,
            description: description,
            priority: priority ?? 'Medium',
            soundPath: soundPath,
            notificationsEnabled: notificationsEnabled,
            alarmsEnabled: alarmsEnabled,
          );
          _activeTimers.remove(taskId);
        });

        _activeTimers[taskId] = timer;
      } else {
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
  }) async {
    // High priority → full-screen alarm
    if (priority == 'High' && alarmsEnabled && _context != null) {
        await _alarmService.showAlarm(
          context: _context!,
          taskId: taskId,
          title: title,
          description: description,
          soundPath: soundPath,
          onSnooze: (duration) => _scheduleSnooze(taskId, title, description, priority, soundPath, duration),
          onDismiss: () {
            // Alarm dismissed - do nothing
          },
        );
    }
    // Normal/Medium priority → notification
    else if ((priority == 'Medium' || priority == 'Low' || priority == 'Normal') && notificationsEnabled) {
      await _notificationService.showTaskNotification(
        taskId: taskId,
        title: title,
        body: description?.isNotEmpty == true ? description : 'Task reminder',
        soundPath: soundPath,
      );
    }
  }


  /// Schedule a snoozed alarm
  void _scheduleSnooze(
    String taskId,
    String title,
    String? description,
    String priority,
    String? soundPath,
    Duration duration,
  ) {
    if (_context == null) return;

    final timer = Timer(duration, () async {
      final alarmsEnabled = await _settingsService.getAlarmsEnabled();
      if (alarmsEnabled && _context != null) {
        await _alarmService.showAlarm(
          context: _context!,
          taskId: taskId,
          title: title,
          description: description,
          soundPath: soundPath,
          onSnooze: (duration) => _scheduleSnooze(taskId, title, description, priority, soundPath, duration),
          onDismiss: () {
            // Alarm dismissed - do nothing
          },
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
