import 'package:flutter/services.dart';
import 'dart:io';

/// Service to pick ringtones using Android's native ringtone picker
/// Requires platform channel implementation in MainActivity.kt
class RingtonePickerService {
  static const platform = MethodChannel('com.yourcompany.synapse/ringtone_picker');

  /// Ringtone types for Android
  /// TYPE_RINGTONE: Phone call ringtones
  static const int TYPE_RINGTONE = 1;
  
  /// TYPE_NOTIFICATION: Notification sounds
  static const int TYPE_NOTIFICATION = 2;
  
  /// TYPE_ALARM: Alarm sounds
  static const int TYPE_ALARM = 4;
  
  /// TYPE_ALL: All sound types
  static const int TYPE_ALL = 7;

  /// Pick a ringtone using the Android system picker
  /// 
  /// [type] specifies which type of sounds to show (default: TYPE_ALARM)
  /// Returns a map with 'uri' and 'title' keys, or null if cancelled
  /// 
  /// Example:
  /// ```dart
  /// final result = await RingtonePickerService.pickRingtone(
  ///   type: RingtonePickerService.TYPE_ALARM,
  /// );
  /// 
  /// if (result != null) {
  ///   print('Selected: ${result['title']}');
  ///   print('URI: ${result['uri']}');
  /// }
  /// ```
  static Future<Map<String, String>?> pickRingtone({int type = TYPE_ALARM}) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Ringtone picker is only supported on Android');
    }

    try {
      final result = await platform.invokeMethod('pickRingtone', {'type': type});
      
      if (result != null && result is Map) {
        return {
          'uri': result['uri'] as String,
          'title': result['title'] as String,
        };
      }
      return null; // User cancelled
    } on PlatformException catch (e) {
      print("Failed to pick ringtone: ${e.message}");
      return null;
    }
  }
}
