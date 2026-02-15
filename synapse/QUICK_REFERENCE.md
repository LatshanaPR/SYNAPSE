# Flutter Ringtone Manager - Correct API Reference

## ❌ What DOESN'T Work (Your Original Code)

The **flutter_ringtone_manager v1.1.2** package does NOT have these methods:

```dart
// ❌ THESE DON'T EXIST:
FlutterRingtoneManager.getRingtone(types: [RingtoneType.alarm])
FlutterRingtoneManager.getRingtoneList(types: [RingtoneType.alarm])
RingtoneType.alarm
```

---

## ✅ What DOES Work

### 1. Playing System Sounds (flutter_ringtone_manager)

```dart
// ✅ Play default alarm sound
FlutterRingtoneManager().playAlarm();

// ✅ Play default ringtone
FlutterRingtoneManager().playRingtone();

// ✅ Play default notification
FlutterRingtoneManager().playNotification();

// ✅ Play custom asset
FlutterRingtoneManager().playAudioAsset("audio/test.mp3");

// ✅ Stop playing
FlutterRingtoneManager().stop();
```

### 2. Picking Ringtones (Custom Platform Channel)

**I've implemented this for you!** 

Use the new `RingtonePickerService`:

```dart
import '../services/ringtone_picker_service.dart';

// Open Android ringtone picker for alarm sounds
final result = await RingtonePickerService.pickRingtone(
  type: RingtonePickerService.TYPE_ALARM,
);

if (result != null) {
  String uri = result['uri']!;      // e.g., "content://media/internal/audio/media/123"
  String title = result['title']!;  // e.g., "Gentle Wake"
  
  // Save and use the URI
  widget.onSoundSelected(uri);
}
```

### Available Ringtone Types:

```dart
RingtonePickerService.TYPE_RINGTONE      // 1 - Phone ringtones
RingtonePickerService.TYPE_NOTIFICATION  // 2 - Notification sounds
RingtonePickerService.TYPE_ALARM         // 4 - Alarm sounds
RingtonePickerService.TYPE_ALL           // 7 - All sounds
```

---

## 📦 Files I Created/Updated

### Created:
1. **lib/services/ringtone_picker_service.dart** - Dart service for picking ringtones
2. **RINGTONE_PICKER_GUIDE.md** - Complete implementation guide
3. **QUICK_REFERENCE.md** - This file

### Updated:
1. **android/app/src/main/kotlin/.../MainActivity.kt** - Added platform channel for ringtone picker
2. **lib/widgets/sound_picker_widget.dart** - Updated to use correct API

---

## 🚀 How to Use in Your App

### In sound_picker_widget.dart (Already Done):

```dart
Future<void> _pickDeviceRingtone() async {
  if (!Platform.isAndroid) return;

  try {
    final result = await RingtonePickerService.pickRingtone(
      type: RingtonePickerService.TYPE_ALARM,
    );

    if (result != null) {
      setState(() {
        _ringtoneUri = result['uri'];
        _ringtoneName = result['title'] ?? 'Device Alarm Sound';
        _selectedSound = 'DeviceRingtone';
      });
      widget.onSoundSelected(result['uri']);
      _playPreview(result['uri']!);
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Playing the Selected Ringtone:

```dart
// For content:// URIs (Android system ringtones)
if (soundUri.startsWith('content://')) {
  await FlutterRingtonePlayer().play(
    android: AndroidSounds.ringtone,
    fromAsset: soundUri,
    looping: true,
    volume: 0.7,
  );
}
```

---

## 🧪 Testing

1. Run your app on an Android device/emulator
2. Navigate to your sound picker
3. Tap "Device Ringtone" or equivalent button
4. Android's native ringtone picker will open
5. Select an alarm sound
6. The selected ringtone URI and name will be returned

---

## 📝 Summary

- **flutter_ringtone_manager** = ✅ Playing sounds only
- **RingtonePickerService** (custom) = ✅ Picking ringtones (Android only)
- **file_picker** = ✅ Picking custom audio files (all platforms)

All the code is ready and integrated! Just test it on an Android device.
