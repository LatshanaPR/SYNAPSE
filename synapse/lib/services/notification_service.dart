import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'task_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'app_messenger.dart';

/// Background notification response handler
/// This top-level function handles notification actions when app is backgrounded or terminated
/// MANDATORY: Must be top-level, annotated with @pragma('vm:entry-point'), and not depend on Firestore
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  print('═══════════════════════════════════════════════════════════');
  print('🔥 BACKGROUND HANDLER TRIGGERED - notificationTapBackground 🔥');
  print('═══════════════════════════════════════════════════════════');
  print('[DEBUG] ActionId: ${response.actionId}');
  print('[DEBUG] Payload: ${response.payload}');
  print('[DEBUG] Id: ${response.id}');
  print('[DEBUG] NotificationType: ${response.notificationResponseType}');
  print('═══════════════════════════════════════════════════════════');

  final taskId = response.payload;
  if (taskId == null || taskId.isEmpty) {
    print('[ERROR] Background handler: taskId is null or empty');
    return;
  }

  final actionId = response.actionId;
  if (actionId == null || actionId.isEmpty) {
    print('[INFO] Background: Notification tapped (no action) - taskId: $taskId');
    return; // Regular tap, no action
  }

  print('[SNOOZE] 🔔 Background: Action detected: $actionId for taskId: $taskId');

  try {
    // Handle snooze actions - match action IDs: SNOOZE_10, SNOOZE_30, and SNOOZE_60
    // IMPORTANT: This reschedules notification locally WITHOUT Firestore dependency
    Duration? snoozeDuration;
    
    if (actionId == 'SNOOZE_10') {
      print('[SNOOZE] 🔔 Background: Processing SNOOZE_10 for taskId: $taskId');
      snoozeDuration = const Duration(minutes: 10);
    } else if (actionId == 'SNOOZE_30') {
      print('[SNOOZE] 🔔 Background: Processing SNOOZE_30 for taskId: $taskId');
      snoozeDuration = const Duration(minutes: 30);
    } else if (actionId == 'SNOOZE_60') {
      print('[SNOOZE] 🔔 Background: Processing SNOOZE_60 for taskId: $taskId');
      snoozeDuration = const Duration(minutes: 60);
    } else {
      print('[WARN] Background: Unknown actionId: $actionId');
      return;
    }

    // Reschedule notification directly without Firestore dependency
    await _rescheduleNotificationInBackground(taskId, snoozeDuration);
    print('[SNOOZE] ✅ Background: SNOOZE completed successfully for taskId: $taskId');
  } catch (e, stackTrace) {
    print('[ERROR] ❌ Background: CRITICAL ERROR handling snooze action: $e');
    print('[ERROR] Stack trace: $stackTrace');
  }
  
  print('═══════════════════════════════════════════════════════════');
}

/// Reschedule notification in background WITHOUT Firestore dependency
/// This works even when app is closed/terminated
Future<void> _rescheduleNotificationInBackground(String taskId, Duration snoozeDuration) async {
  print('[SNOOZE] Background: === STARTING BACKGROUND RESCHEDULE ===');
  print('[SNOOZE] Background: taskId: $taskId, duration: ${snoozeDuration.inMinutes} minutes');
  
  try {
    // CRITICAL: Initialize timezone database in background isolate
    // This must happen before any timezone operations
    try {
      tz_data.initializeTimeZones();
      print('[SNOOZE] Background: ✓✓✓ Timezone database initialized ✓✓✓');
    } catch (e) {
      // If already initialized, this is fine
      print('[SNOOZE] Background: Timezone already initialized or error: $e');
    }
    
    // Create notification service instance
    final notificationService = NotificationService();
    print('[SNOOZE] Background: ✓ Created NotificationService instance');
    
    // Initialize notification service (required for scheduling)
    await notificationService.initialize();
    print('[SNOOZE] Background: ✓ NotificationService initialized');
    
    // Cancel existing notification
    await notificationService.cancelNotification(taskId);
    print('[SNOOZE] Background: ✓ Cancelled existing notification');
    
    // Calculate new scheduled time
    final nowTime = DateTime.now();
    final scheduledTimeNew = nowTime.add(snoozeDuration);
    print('[SNOOZE] Background: Current time: $nowTime');
    print('[SNOOZE] Background: Scheduled time: $scheduledTimeNew');
    
    // Get notification plugin - must access from service instance
    final notifications = FlutterLocalNotificationsPlugin();

    // IMPORTANT: initialize this instance before scheduling
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await notifications.initialize(initSettings);
      print('[SNOOZE] Background: ✓ Local notifications plugin initialized (background instance)');
    } catch (e) {
      // Best-effort; scheduling may still work on some devices, but do not crash.
      print('[WARN] Background: Failed to initialize local notifications instance: $e');
    }
    
    // Create snooze actions for rescheduled notification
    final actions = [
      const AndroidNotificationAction(
        'SNOOZE_10',
        'Snooze 10 min',
        showsUserInterface: true,
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        'SNOOZE_30',
        'Snooze 30 min',
        showsUserInterface: true,
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        'SNOOZE_60',
        'Snooze 1 hour',
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ];

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      channelDescription: 'Notifications for normal priority tasks',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: actions,
      fullScreenIntent: false, // Normal tasks should not use full screen
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = taskId.hashCode;
    
    // Convert to TZDateTime
    final location = tz.local;
    final tzScheduledTime = tz.TZDateTime.from(scheduledTimeNew, location);
    
    // Use zonedSchedule to schedule notification at specific time
    try {
      await notifications.zonedSchedule(
        notificationId,
        'Task Reminder',
        'Task reminder (snoozed)',
        tzScheduledTime,
        details,
        payload: taskId,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException catch (e, stackTrace) {
      if (e.code == 'exact_alarms_not_permitted') {
        print('[WARN] Background: exact alarms not permitted; falling back to inexact schedule');
        print('[WARN] Background: PlatformException: ${e.code} - ${e.message}');
        await notifications.zonedSchedule(
          notificationId,
          'Task Reminder',
          'Task reminder (snoozed)',
          tzScheduledTime,
          details,
          payload: taskId,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        print('[ERROR] Background: PlatformException scheduling notification: ${e.code} - ${e.message}');
        print('[ERROR] Background: Stack trace: $stackTrace');
        rethrow;
      }
    }
    
    print('[SNOOZE] Background: ✅✅✅ NOTIFICATION RESCHEDULED ✅✅✅');
    print('[SNOOZE] Background: Notification will appear at $scheduledTimeNew');
    print('[SNOOZE] Background: This works even if app is closed!');
  } catch (e, stackTrace) {
    print('[ERROR] Background: ❌❌❌ FAILED TO RESCHEDULE ❌❌❌');
    print('[ERROR] Background: Error: $e');
    print('[ERROR] Background: Stack trace: $stackTrace');
    // Do not crash the background handler.
    return;
  }
}


/// Service for handling local notifications for normal priority tasks
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Create notification channel for Android (required for actions)
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Delete existing channel first to ensure fresh setup
        await androidImplementation.deleteNotificationChannel('task_notifications');
        
        // Create channel with proper settings for actions
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_notifications',
            'Task Notifications',
            description: 'Notifications for normal priority tasks',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          ),
        );
        print('✓ Notification channel created/recreated: task_notifications');
      }
    }

    // Initialize with BOTH foreground and background handlers
    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    print('NotificationService initialized: $initialized');
    print('Background notification handler registered: notificationTapBackground');
    _initialized = true;
  }

  // Store snooze callbacks by task ID
  final Map<String, Function(Duration)> _snoozeCallbacks = {};

  /// Handle notification response (tap or action)
  /// Uses ONLY response.actionId and response.payload
  void _onNotificationResponse(NotificationResponse response) async {
    print('═══════════════════════════════════════════════════════════');
    print('🔥 FOREGROUND NOTIFICATION RESPONSE HANDLER TRIGGERED 🔥');
    print('═══════════════════════════════════════════════════════════');
    print('[DEBUG] ACTION RECEIVED: ${response.actionId}');
    print('[DEBUG] PAYLOAD: ${response.payload}');
    print('[DEBUG] ID: ${response.id}');
    print('[DEBUG] NotificationType: ${response.notificationResponseType}');
    print('═══════════════════════════════════════════════════════════');

    final taskId = response.payload;
    if (taskId == null || taskId.isEmpty) {
      print('[ERROR] taskId is null or empty in notification response');
      return;
    }

    final actionId = response.actionId;
    if (actionId == null || actionId.isEmpty) {
      print('[INFO] Notification tapped (no action) - taskId: $taskId');
      return; // Regular tap, no action
    }

    print('[SNOOZE] Action detected: $actionId for taskId: $taskId');

    try {
      if (actionId == 'SNOOZE_10') {
        print('[SNOOZE] Processing SNOOZE_10 for taskId: $taskId');
        await handleTaskSnooze(taskId, 10);
        print('[SNOOZE] ✓ SNOOZE_10 completed for taskId: $taskId');
      } else if (actionId == 'SNOOZE_30') {
        print('[SNOOZE] Processing SNOOZE_30 for taskId: $taskId');
        await handleTaskSnooze(taskId, 30);
        print('[SNOOZE] ✓ SNOOZE_30 completed for taskId: $taskId');
      } else if (actionId == 'SNOOZE_60') {
        print('[SNOOZE] Processing SNOOZE_60 for taskId: $taskId');
        await handleTaskSnooze(taskId, 60);
        print('[SNOOZE] ✓ SNOOZE_60 completed for taskId: $taskId');
      } else {
        print('[WARN] Unknown actionId: $actionId');
      }
    } catch (e, stackTrace) {
      print('[ERROR] Error handling snooze action: $e');
      print('[ERROR] Stack trace: $stackTrace');
    }
  }

  /// Handle task snooze - Works offline, reschedules immediately
  /// Increments snoozeCount (max 5), saves snoozedUntil, cancels notification, schedules new one
  Future<void> handleTaskSnooze(String taskId, int minutes) async {
    print('[SNOOZE] handleTaskSnooze called - taskId: $taskId, minutes: $minutes');
    final now = DateTime.now();
    final snoozedUntil = now.add(Duration(minutes: minutes));

    try {
      // 1. Cancel existing notification FIRST (always works, local operation)
      await cancelNotification(taskId);
      print('[SNOOZE] ✓ Cancelled existing notification for taskId: $taskId');

      // 2. Try to get task data from Firestore (non-blocking, with timeout)
      print('[SNOOZE] Step 2: Getting task data from Firestore...');
      Map<String, dynamic>? currentData;
      int currentSnoozeCount = 0;
      String title = 'Task';
      String? description;
      String? soundPath;

      try {
        final taskService = TaskService();
        print('[SNOOZE] Created TaskService instance');
        print('[SNOOZE] Fetching tasks from Firestore...');
        
        final taskDoc = await taskService.getTasks().first
            .timeout(const Duration(seconds: 3), onTimeout: () => throw 'Timeout getting tasks');
        
        print('[SNOOZE] Got tasks from Firestore, searching for taskId: $taskId');
        final currentTask = taskDoc.docs.firstWhere(
          (doc) => doc.id == taskId,
          orElse: () => throw 'Task not found: $taskId',
        );
        
        currentData = currentTask.data() as Map<String, dynamic>;
        currentSnoozeCount = (currentData['snoozeCount'] as int?) ?? 0;
        title = currentData['title'] as String? ?? 'Task';
        description = currentData['description'] as String?;
        soundPath = currentData['soundPath'] as String?;

        print('[SNOOZE] ✓ Step 2 DONE: Got task data from Firestore');
        print('[SNOOZE]   - title: $title');
        print('[SNOOZE]   - snoozeCount: $currentSnoozeCount');
      } catch (e) {
        print('[WARN] Step 2 FAILED: Could not get task data from Firestore (offline?): $e');
        print('[SNOOZE] Continuing with snooze anyway - will use cached/default values');
        // Continue without Firestore data - snooze will still work
      }

      // 3. Check snooze limit and show warning if >= 5 (but don't prevent snoozing)
      print('[SNOOZE] Step 3: Checking snooze limit...');
      final newSnoozeCount = currentSnoozeCount + 1;
      
      // Show warning if snoozeCount >= 5, but still allow snoozing
      if (currentData != null && currentSnoozeCount >= 5) {
        print('[SNOOZE] ⚠️⚠️⚠️ WARNING: Task snoozed $currentSnoozeCount times (max 5) ⚠️⚠️⚠️');
        print('[SNOOZE] Showing warning but allowing snooze - suggest rescheduling task');
        
        // Show a non-blocking warning notification
        try {
          await showTaskNotification(
            taskId: '${taskId}_warning',
            title: 'Snooze Limit Warning',
            body: 'Task "$title" has been snoozed $currentSnoozeCount times. Consider rescheduling this task.',
          );
          print('[SNOOZE] ✓ Warning notification shown');
        } catch (e) {
          print('[WARN] Failed to show warning notification: $e');
        }
      }
      
      print('[SNOOZE] ✓ Step 3 DONE: Snooze allowed');
      print('[SNOOZE]   - currentCount: $currentSnoozeCount');
      print('[SNOOZE]   - newCount: $newSnoozeCount');

      // 4. RESCHEDULE NOTIFICATION IMMEDIATELY (works offline, local operation)
      // This must happen BEFORE Firestore update so snooze works offline
      print('[SNOOZE] Step 4: Rescheduling notification for $snoozedUntil...');
      try {
        await _scheduleNotificationAtTime(
          taskId: taskId,
          title: title,
          description: description,
          soundPath: soundPath,
          scheduledTime: snoozedUntil,
        );
        print('[SNOOZE] ✓✓✓ Step 4 DONE: Notification rescheduled for $snoozedUntil (works offline) ✓✓✓');
      } catch (scheduleError, scheduleStack) {
        print('[ERROR] ✗✗✗ Step 4 FAILED: Failed to schedule notification ✗✗✗');
        print('[ERROR] Error: $scheduleError');
        print('[ERROR] Stack trace: $scheduleStack');
        rethrow; // Re-throw if scheduling fails - this is critical
      }

      // 5. Update Firestore in background (non-blocking, fire-and-forget)
      // This is wrapped in try-catch and won't block snooze if it fails
      if (currentData != null) {
        _updateFirestoreSnoozeState(taskId, snoozedUntil, newSnoozeCount);
      } else {
        print('[WARN] Skipping Firestore update - no task data available');
      }

      print('[SNOOZE] ✓ Snooze complete - notification will reappear at $snoozedUntil');
    } catch (e, stackTrace) {
      print('[SNOOZE] ✗ Critical error in handleTaskSnooze: $e');
      print('[SNOOZE] Stack trace: $stackTrace');
      rethrow; // Only rethrow if rescheduling failed
    }
  }

  /// Update Firestore snooze state in background (non-blocking, fire-and-forget)
  /// This is wrapped in try-catch and won't stop snooze if it fails
  void _updateFirestoreSnoozeState(String taskId, DateTime snoozedUntil, int newSnoozeCount) {
    // Fire-and-forget: don't await, wrap in try-catch
    Future.microtask(() async {
      try {
        final taskService = TaskService();
        await taskService.updateTask(taskId, {
          'snoozedUntil': Timestamp.fromDate(snoozedUntil),
          'snoozeCount': newSnoozeCount,
          'isSnoozed': true,
        });
        print('[SNOOZE] ✓ Firestore updated (background) - snoozedUntil: $snoozedUntil, snoozeCount: $newSnoozeCount');
      } catch (e, stackTrace) {
        // Log error but don't throw - snooze already worked locally
        print('[WARN] Firestore update failed (offline?) - snooze still works: $e');
        print('[WARN] Stack trace: $stackTrace');
        // Notification was already rescheduled, so this is just for UI/history
      }
    });
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ requires notification permission
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      return true;
    } else if (Platform.isIOS) {
      // iOS permissions are requested during initialization
      final settings = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return settings ?? false;
    }
    return true;
  }

  /// Show a notification for a task
  /// [taskId] - The task document ID
  /// [title] - Task title
  /// [body] - Task description or custom message
  /// [soundPath] - Path to custom sound file, or built-in sound name
  /// [onSnooze] - Optional callback when snooze is pressed with duration
  Future<void> showTaskNotification({
    required String taskId,
    required String title,
    String? body,
    String? soundPath,
    Function(Duration)? onSnooze,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Play sound if provided
    if (soundPath != null) {
      await _playSound(soundPath);
    }

    // Always create snooze actions - 10 min, 30 min, and 1 hour
    // These work even when app is closed via background handler
    final actions = [
      AndroidNotificationAction(
        'SNOOZE_10',  // actionId - MUST match what we check in handler
        'Snooze 10 min',  // title
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        'SNOOZE_30',  // actionId - MUST match what we check in handler
        'Snooze 30 min',  // title
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        'SNOOZE_60',  // actionId - MUST match what we check in handler
        'Snooze 1 hour',  // title
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ];
    print('✓ Created ${actions.length} snooze actions for taskId: $taskId');
    print('  - Action 1: id="SNOOZE_10", title="Snooze 10 min"');
    print('  - Action 2: id="SNOOZE_30", title="Snooze 30 min"');
    print('  - Action 3: id="SNOOZE_60", title="Snooze 1 hour"');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      channelDescription: 'Notifications for normal priority tasks',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: actions,
      fullScreenIntent: false, // Normal tasks should not use full screen
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Store snooze callback if provided
    if (onSnooze != null) {
      _snoozeCallbacks[taskId] = onSnooze;
      print('Stored snooze callback for taskId: $taskId, total callbacks: ${_snoozeCallbacks.length}');
    } else {
      print('No snooze callback provided for taskId: $taskId');
    }

    final notificationId = taskId.hashCode;
    print('Showing notification: id=$notificationId, taskId=$taskId, payload=$taskId, hasActions=true');
    
    await _notifications.show(
      notificationId,
      title,
      body ?? 'Task reminder',
      details,
      payload: taskId,
    );
    
    print('Notification shown successfully with ID: $notificationId');
  }

  /// Play a sound file
  /// [soundPath] - Can be a built-in sound name or a file path
  Future<void> _playSound(String? soundPath) async {
    if (soundPath == null || soundPath.isEmpty) return;
    
    try {
      // Handle built-in sounds (we'll create placeholder audio files)
      // For now, we'll just play a system sound
      // In production, you'd have actual audio files in assets
      if (soundPath.startsWith('builtin_')) {
        // Built-in sounds - would need actual audio files
        // For now, just play a default sound
        await _audioPlayer.play(AssetSource('sounds/default.mp3'), volume: 0.5);
      } else {
        // Custom sound file - check if exists
        final file = File(soundPath);
        if (await file.exists()) {
          await _audioPlayer.play(DeviceFileSource(soundPath), volume: 0.5);
        }
      }
    } catch (e) {
      // Ignore sound playback errors
      print('Error playing sound: $e');
    }
  }

  /// Cancel a notification by task ID
  Future<void> cancelNotification(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel pre-reminder notification for a task
  Future<void> cancelPreReminder(String taskId) async {
    await _notifications.cancel(taskId.hashCode + 2);
  }

  /// Schedule a "2 days before" pre-reminder notification.
  /// Uses separate notification ID (taskId.hashCode + 2) to avoid conflicts.
  /// Does NOT include snooze actions - this is just a heads-up reminder.
  /// Only schedules if dueDateTime is at least 2 days in the future.
  Future<void> schedulePreReminder({
    required String taskId,
    required String title,
    String? description,
    required DateTime dueDateTime,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final preReminderTime = dueDateTime.subtract(const Duration(days: 2));
    final now = DateTime.now();

    // Only schedule if pre-reminder time is in the future
    if (!preReminderTime.isAfter(now)) {
      print('[PRE-REMINDER] Skipping: due time is less than 2 days away');
      return;
    }

    // Cancel any existing pre-reminder for this task
    await cancelPreReminder(taskId);

    // Use separate notification ID: taskId.hashCode + 2
    final notificationId = taskId.hashCode + 2;

    // Simple notification details WITHOUT snooze actions
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pre_reminders',
      'Pre-Reminders',
      channelDescription: 'Reminder notifications 2 days before task deadline',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      // NO actions - this is just a heads-up, not a snooze-able notification
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        notificationId,
        '2 days left: $title',
        description ?? 'Your task is due in 2 days',
        _convertToTZDateTime(preReminderTime),
        details,
        payload: '$taskId|preReminder', // Mark as pre-reminder in payload
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('[PRE-REMINDER] Scheduled for taskId=$taskId at $preReminderTime');
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        // Fallback to inexact
        await _notifications.zonedSchedule(
          notificationId,
          '2 days left: $title',
          description ?? 'Your task is due in 2 days',
          _convertToTZDateTime(preReminderTime),
          details,
          payload: '$taskId|preReminder',
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('[PRE-REMINDER] Scheduled (inexact) for taskId=$taskId');
      } else {
        print('[PRE-REMINDER] Error: ${e.code} - ${e.message}');
      }
    }
  }

  /// Schedule a notification at a specific time
  Future<void> _scheduleNotificationAtTime({
    required String taskId,
    required String title,
    String? description,
    String? soundPath,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Create snooze actions for rescheduled notifications
    // 10 min, 30 min, and 1 hour options
    final actions = [
      AndroidNotificationAction(
        'SNOOZE_10',
        'Snooze 10 min',
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        'SNOOZE_30',
        'Snooze 30 min',
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        'SNOOZE_60',
        'Snooze 1 hour',
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ];

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      channelDescription: 'Notifications for normal priority tasks',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: actions,
      fullScreenIntent: false, // Normal tasks should not use full screen
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = taskId.hashCode;
    
    // Use zonedSchedule to schedule notification at specific time
    try {
      await _notifications.zonedSchedule(
        notificationId,
        title,
        description ?? 'Task reminder',
        _convertToTZDateTime(scheduledTime),
        details,
        payload: taskId,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException catch (e, stackTrace) {
      if (e.code == 'exact_alarms_not_permitted') {
        print('[WARN] exact_alarms_not_permitted while scheduling. Falling back to inexact schedule.');
        print('[WARN] PlatformException: ${e.code} - ${e.message}');

        // User-facing hint (best-effort; requires Scaffold to exist)
        AppMessenger.showSnackBar(
          'For exact reminder timing, enable "Alarms & reminders" permission in Settings.',
          backgroundColor: Colors.orange,
        );

        // Fallback: inexact scheduling (approximate)
        await _notifications.zonedSchedule(
          notificationId,
          title,
          description ?? 'Task reminder',
          _convertToTZDateTime(scheduledTime),
          details,
          payload: taskId,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        print('[ERROR] PlatformException scheduling notification: ${e.code} - ${e.message}');
        print('[ERROR] Stack trace: $stackTrace');
        rethrow;
      }
    }
    
    print('[SCHEDULE] Notification scheduled: id=$notificationId, taskId=$taskId, time=$scheduledTime');
  }

  /// Convert DateTime to TZDateTime (required for zonedSchedule)
  /// Safely handles timezone initialization
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    try {
      // Ensure timezone database is initialized
      try {
        tz_data.initializeTimeZones();
      } catch (e) {
        // If already initialized, this is fine
        print('[DEBUG] Timezone already initialized or error: $e');
      }
      
      final location = tz.local;
      return tz.TZDateTime.from(dateTime, location);
    } catch (e) {
      print('[ERROR] Timezone conversion failed: $e');
      // Fallback: use UTC if local timezone fails
      try {
        final utc = tz.getLocation('UTC');
        return tz.TZDateTime.from(dateTime.toUtc(), utc);
      } catch (e2) {
        print('[ERROR] UTC fallback also failed: $e2');
        // Last resort: create TZDateTime directly
        return tz.TZDateTime.from(dateTime, tz.local);
      }
    }
  }
}
