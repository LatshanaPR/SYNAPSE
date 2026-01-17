import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

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

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    // You can navigate to task details here
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
  Future<void> showTaskNotification({
    required String taskId,
    required String title,
    String? body,
    String? soundPath,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Play sound if provided
    if (soundPath != null) {
      await _playSound(soundPath);
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      channelDescription: 'Notifications for normal priority tasks',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
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

    await _notifications.show(
      taskId.hashCode,
      title,
      body ?? 'Task reminder',
      details,
      payload: taskId,
    );
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
}
