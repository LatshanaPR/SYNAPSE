import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/ringtone_picker_service.dart';

/// Widget for selecting alarm or notification sound
/// Supports Device Ringtone (system ringtone picker) and Custom Sound (file picker)
class SoundPickerWidget extends StatefulWidget {
  final String? initialSound;
  final Function(String?) onSoundSelected;
  final String soundType; // 'notification' or 'alarm'

  const SoundPickerWidget({
    super.key,
    this.initialSound,
    required this.onSoundSelected,
    this.soundType = 'alarm',
  });

  @override
  State<SoundPickerWidget> createState() => _SoundPickerWidgetState();
}

class _SoundPickerWidgetState extends State<SoundPickerWidget> {
  String? _customSoundPath;
  String? _ringtoneUri;
  String? _ringtoneName;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Parse initial sound - can be ringtone URI or custom path
    if (widget.initialSound != null && widget.initialSound!.isNotEmpty) {
      if (widget.initialSound!.startsWith('content://')) {
        // It's a ringtone URI
        _ringtoneUri = widget.initialSound;
        _ringtoneName = widget.soundType == 'notification' 
            ? 'Device Notification' 
            : 'Device Alarm';
      } else {
        // It's a custom sound path
        _customSoundPath = widget.initialSound;
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Stop any currently playing preview
  Future<void> _stopPreview() async {
    try {
      await _audioPlayer.stop();
      await FlutterRingtonePlayer().stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      print('Error stopping preview: $e');
    }
  }

  /// Play sound preview
  Future<void> _playPreview(String soundIdentifier) async {
    try {
      // Stop any currently playing sound
      await _stopPreview();

      setState(() {
        _isPlaying = true;
      });

      // Play based on sound type
      if (soundIdentifier.startsWith('content://')) {
        // Ringtone URI - use flutter_ringtone_player
        await FlutterRingtonePlayer().play(
          android: AndroidSounds.ringtone,
          fromAsset: soundIdentifier,
          looping: false,
          volume: 0.7,
        );
        // Auto-stop after 3 seconds
        await Future.delayed(const Duration(seconds: 3));
        await _stopPreview();
      } else {
        // Custom sound file
        final file = File(soundIdentifier);
        if (await file.exists()) {
          await _audioPlayer.play(DeviceFileSource(soundIdentifier));
          // Auto-stop after playing
          await Future.delayed(const Duration(seconds: 3));
          await _stopPreview();
        } else {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error playing preview: $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _pickCustomSound() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _customSoundPath = result.files.single.path;
          _ringtoneUri = null;
          _ringtoneName = null;
        });
        widget.onSoundSelected(_customSoundPath);
        // Play preview of custom sound
        if (_customSoundPath != null) {
          _playPreview(_customSoundPath!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking sound file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick device ringtone using Android system picker
  Future<void> _pickDeviceRingtone() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device ringtones are only available on Android'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Use platform channel to open Android ringtone picker
      final ringtoneType = widget.soundType == 'notification' 
          ? RingtonePickerService.TYPE_NOTIFICATION 
          : RingtonePickerService.TYPE_ALARM;
      final result = await RingtonePickerService.pickRingtone(
        type: ringtoneType,
      );

      if (result != null) {
        final defaultName = widget.soundType == 'notification' 
            ? 'Device Notification Sound' 
            : 'Device Alarm Sound';
        setState(() {
          _ringtoneUri = result['uri'];
          _ringtoneName = result['title'] ?? defaultName;
          _customSoundPath = null;
        });
        widget.onSoundSelected(result['uri']);
        
        // Play preview of selected ringtone
        if (_ringtoneUri != null) {
          _playPreview(_ringtoneUri!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking ringtone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasDeviceRingtone = _ringtoneUri != null;
    final bool hasCustomSound = _customSoundPath != null;
    
    final isNotification = widget.soundType == 'notification';
    final deviceLabel = isNotification ? 'Device Notification Sound' : 'Device Alarm Sound';
    final deviceSubtitle = isNotification ? 'Use device notification sound' : 'Use device alarm sound';
    final customLabel = isNotification ? 'Custom Notification' : 'Custom';
    final customSubtitle = isNotification ? 'Select notification audio' : 'Select alarm audio';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            children: [
              // Device Alarm Sound Option (Android only)
              if (Platform.isAndroid) ...[
                ListTile(
                  leading: Icon(
                    isNotification ? Icons.notifications : Icons.alarm,
                    color: hasDeviceRingtone ? AppTheme.netflixRed : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    hasDeviceRingtone
                        ? _ringtoneName ?? deviceLabel
                        : deviceLabel,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: hasDeviceRingtone ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: hasDeviceRingtone
                      ? Text('System ${isNotification ? "notification" : "alarm"} sound')
                      : Text(deviceSubtitle),
                  trailing: IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
                    onPressed: _pickDeviceRingtone,
                    tooltip: hasDeviceRingtone ? 'Change' : 'Select',
                  ),
                  onTap: _pickDeviceRingtone,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.surfaceVariant,
                  indent: 16,
                  endIndent: 16,
                ),
              ],
              // Custom Sound Option
              ListTile(
                leading: Icon(
                  Icons.audiotrack,
                  color: hasCustomSound ? AppTheme.netflixRed : colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  customLabel,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: hasCustomSound ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: hasCustomSound
                    ? Text('Custom ${isNotification ? "notification" : "alarm"} audio')
                    : Text(customSubtitle),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
                  onPressed: _pickCustomSound,
                  tooltip: hasCustomSound ? 'Change' : 'Select',
                ),
                onTap: _pickCustomSound,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
