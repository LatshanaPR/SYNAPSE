import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

/// Service for handling full-screen alarms for high priority tasks
class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmActive = false;

  /// Show a full-screen alarm
  /// [context] - BuildContext to show the alarm screen
  /// [taskId] - The task document ID
  /// [title] - Task title
  /// [description] - Task description
  /// [soundPath] - Path to custom sound file, or built-in sound name
  /// [onSnooze] - Callback when snooze is pressed with duration
  /// [onDismiss] - Callback when alarm is dismissed
  Future<void> showAlarm({
    required BuildContext context,
    required String taskId,
    required String title,
    String? description,
    String? soundPath,
    required Function(Duration) onSnooze,
    required VoidCallback onDismiss,
  }) async {
    if (_isAlarmActive) return;

    _isAlarmActive = true;

    // Play alarm sound
    if (soundPath != null) {
      await _playAlarmSound(soundPath);
    }

    // Show full-screen alarm dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AlarmDialog(
        taskId: taskId,
        title: title,
        description: description,
        onSnooze: (duration) {
          _stopAlarm();
          onSnooze(duration);
          Navigator.of(context).pop();
        },
        onDismiss: () {
          _stopAlarm();
          onDismiss();
          Navigator.of(context).pop();
        },
      ),
      );

    _isAlarmActive = false;
  }

  /// Play alarm sound
  Future<void> _playAlarmSound(String? soundPath) async {
    if (soundPath == null || soundPath.isEmpty) return;
    
    try {
      if (soundPath.startsWith('builtin_')) {
        // Built-in sounds - would need actual audio files
        // For now, loop a default sound
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sounds/default.mp3'), volume: 1.0);
      } else {
        // Custom sound file - check if exists and loop it
        final file = File(soundPath);
        if (await file.exists()) {
          await _audioPlayer.setReleaseMode(ReleaseMode.loop);
          await _audioPlayer.play(DeviceFileSource(soundPath), volume: 1.0);
        }
      }
    } catch (e) {
      print('Error playing alarm sound: $e');
    }
  }

  /// Stop the alarm sound
  Future<void> _stopAlarm() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping alarm: $e');
    }
  }

  /// Stop current alarm (called externally)
  Future<void> stopCurrentAlarm() async {
    await _stopAlarm();
    _isAlarmActive = false;
  }

  /// Check if alarm is currently active
  bool get isAlarmActive => _isAlarmActive;
}

/// Full-screen alarm dialog widget
class _AlarmDialog extends StatefulWidget {
  final String taskId;
  final String title;
  final String? description;
  final Function(Duration) onSnooze;
  final VoidCallback onDismiss;

  const _AlarmDialog({
    required this.taskId,
    required this.title,
    this.description,
    required this.onSnooze,
    required this.onDismiss,
  });

  @override
  State<_AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends State<_AlarmDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button from dismissing
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                const Color(0xFFE50914).withOpacity(0.3),
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Alarm Icon with pulse animation
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE50914).withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Task Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Task Description (if available)
                  if (widget.description != null && widget.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        widget.description!,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[300],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 60),
                  // Snooze Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSnoozeButton('5 min', const Duration(minutes: 5)),
                      const SizedBox(width: 16),
                      _buildSnoozeButton('10 min', const Duration(minutes: 10)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Dismiss Button
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSnoozeButton(String label, Duration duration) {
    return ElevatedButton(
      onPressed: () {
        widget.onSnooze(duration);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[900],
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[700]!),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
