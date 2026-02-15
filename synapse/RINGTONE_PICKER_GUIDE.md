# Ringtone Picker Implementation Guide

## Package Clarification

### flutter_ringtone_manager v1.1.2

**This package DOES NOT provide a ringtone picker!** It only plays system sounds.

#### Correct API:
```dart
// Play default system sounds
FlutterRingtoneManager().playRingtone();      // Play default ringtone
FlutterRingtoneManager().playAlarm();         // Play default alarm  
FlutterRingtoneManager().playNotification();  // Play default notification
FlutterRingtoneManager().playAudioAsset("audio/test.mp3"); // Play custom asset
FlutterRingtoneManager().stop();              // Stop playback
```

#### Methods that DON'T exist:
- ❌ `FlutterRingtoneManager.getRingtone()`
- ❌ `FlutterRingtoneManager.getRingtoneList()`
- ❌ `RingtoneType.alarm`

---

## Solution: Implement Ringtone Picker

For picking ringtones on Android, you have two options:

### Option 1: Use android_intent_plus (Simple but Limited)

```dart
import 'package:android_intent_plus/android_intent.dart';

// Open ringtone picker (cannot get result without platform channels)
const intent = AndroidIntent(
  action: 'android.intent.action.RINGTONE_PICKER',
  arguments: <String, dynamic>{
    'android.intent.extra.ringtone.TYPE': 4, // TYPE_ALARM (4), TYPE_RINGTONE (1), TYPE_NOTIFICATION (2)
    'android.intent.extra.ringtone.TITLE': 'Select Alarm Sound',
    'android.intent.extra.ringtone.SHOW_DEFAULT': true,
    'android.intent.extra.ringtone.SHOW_SILENT': false,
  },
);
await intent.launch();
```

**Limitation:** Cannot receive the selected ringtone URI back without implementing platform channels.

---

### Option 2: Implement Platform Channels (Recommended)

Create a method channel to properly handle the ringtone picker and get the result.

#### Step 1: Create Kotlin code (android/app/src/main/kotlin/.../MainActivity.kt)

```kotlin
package com.yourcompany.synapse

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.yourcompany.synapse/ringtone_picker"
    private val RINGTONE_PICKER_REQUEST = 9999
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickRingtone" -> {
                    val type = call.argument<Int>("type") ?: RingtoneManager.TYPE_ALARM
                    pickRingtone(type, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pickRingtone(type: Int, result: MethodChannel.Result) {
        pendingResult = result
        
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, type)
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select Alarm Sound")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
        }
        
        startActivityForResult(intent, RINGTONE_PICKER_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == RINGTONE_PICKER_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri: Uri? = data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                
                if (uri != null) {
                    // Get ringtone title
                    val ringtone = RingtoneManager.getRingtone(applicationContext, uri)
                    val title = ringtone.getTitle(applicationContext)
                    
                    pendingResult?.success(mapOf(
                        "uri" to uri.toString(),
                        "title" to title
                    ))
                } else {
                    pendingResult?.success(null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }
}
```

#### Step 2: Create Dart service (lib/services/ringtone_picker_service.dart)

```dart
import 'package:flutter/services.dart';
import 'dart:io';

class RingtonePickerService {
  static const platform = MethodChannel('com.yourcompany.synapse/ringtone_picker');

  /// Ringtone types for Android
  static const int TYPE_RINGTONE = 1;
  static const int TYPE_NOTIFICATION = 2;
  static const int TYPE_ALARM = 4;
  static const int TYPE_ALL = 7;

  /// Pick a ringtone using the Android system picker
  /// Returns a map with 'uri' and 'title' keys, or null if cancelled
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
      return null;
    } on PlatformException catch (e) {
      print("Failed to pick ringtone: ${e.message}");
      return null;
    }
  }
}
```

#### Step 3: Use in your widget

```dart
import '../services/ringtone_picker_service.dart';

Future<void> _pickDeviceRingtone() async {
  if (!Platform.isAndroid) {
    // Show error
    return;
  }

  try {
    final result = await RingtonePickerService.pickRingtone(
      type: RingtonePickerService.TYPE_ALARM,
    );

    if (result != null) {
      setState(() {
        _ringtoneUri = result['uri'];
        _ringtoneName = result['title'];
        _customSoundPath = null;
        _selectedSound = 'DeviceRingtone';
      });
      widget.onSoundSelected(result['uri']);
      
      // Play preview
      _playPreview(result['uri']!);
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
```

---

## Alternative: Use file_picker for Custom Sounds Only

If you don't need system ringtones, just use `file_picker` for custom audio files:

```dart
import 'package:file_picker/file_picker.dart';

Future<void> _pickCustomSound() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      // Use the custom sound path
      widget.onSoundSelected(path);
    }
  } catch (e) {
    print('Error picking sound: $e');
  }
}
```

---

## Playing Selected Ringtones

To play the selected ringtone/sound:

### For built-in sounds:
```dart
// Use flutter_ringtone_manager
FlutterRingtoneManager().playAlarm();
```

### For system ringtone URIs (content://...):
```dart
// Use flutter_ringtone_player
await FlutterRingtonePlayer().play(
  android: AndroidSounds.ringtone,
  fromAsset: ringtoneUri, // The content:// URI
  looping: false,
  volume: 0.7,
);
```

### For custom file paths:
```dart
// Use audioplayers
final audioPlayer = AudioPlayer();
await audioPlayer.play(DeviceFileSource(customSoundPath));
```

---

## Summary

1. **flutter_ringtone_manager** = Play default system sounds only
2. **android_intent_plus** = Launch picker but can't get result
3. **Platform Channels** = Full ringtone picker with result (recommended)
4. **file_picker** = Pick custom audio files

Choose the approach that best fits your needs!
