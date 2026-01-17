import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';
import '../widgets/sound_picker_widget.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  String? _selectedNotificationSound;
  String? _selectedAlarmSound;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _settingsService.getSettingsRef().get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _selectedNotificationSound = data['notificationSound'] ?? 'builtin_default';
          _selectedAlarmSound = data['alarmSound'] ?? 'builtin_default';
          _isLoading = false;
        });
      } else {
        setState(() {
          _selectedNotificationSound = 'builtin_default';
          _selectedAlarmSound = 'builtin_default';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedNotificationSound = 'builtin_default';
        _selectedAlarmSound = 'builtin_default';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationSound(String? soundPath) async {
    try {
      await _settingsService.getSettingsRef().set({
        'notificationSound': soundPath ?? 'builtin_default',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() {
        _selectedNotificationSound = soundPath ?? 'builtin_default';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving notification sound: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAlarmSound(String? soundPath) async {
    try {
      await _settingsService.getSettingsRef().set({
        'alarmSound': soundPath ?? 'builtin_default',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() {
        _selectedAlarmSound = soundPath ?? 'builtin_default';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving alarm sound: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.black,
        appBar: AppBar(
          backgroundColor: AppTheme.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Sound Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sound Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Sound Section
              _buildSectionTitle('Notification Sound', 'For normal priority tasks'),
              const SizedBox(height: 12),
              SoundPickerWidget(
                initialSound: _selectedNotificationSound,
                onSoundSelected: _saveNotificationSound,
              ),
              const SizedBox(height: 32),
              // Alarm Sound Section
              _buildSectionTitle('Alarm Sound', 'For high priority tasks'),
              const SizedBox(height: 12),
              SoundPickerWidget(
                initialSound: _selectedAlarmSound,
                onSoundSelected: _saveAlarmSound,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
