import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';

/// Widget for selecting sound for tasks
/// Supports 4 built-in sounds and custom sound file picker
class SoundPickerWidget extends StatefulWidget {
  final String? initialSound;
  final Function(String?) onSoundSelected;

  const SoundPickerWidget({
    super.key,
    this.initialSound,
    required this.onSoundSelected,
  });

  @override
  State<SoundPickerWidget> createState() => _SoundPickerWidgetState();
}

class _SoundPickerWidgetState extends State<SoundPickerWidget> {
  static const List<String> _builtInSounds = [
    'Default',
    'Soft Beep',
    'Digital Tone',
    'Classic Alarm',
  ];

  String? _selectedSound;
  String? _customSoundPath;

  @override
  void initState() {
    super.initState();
    // Parse initial sound - can be built-in name or custom path
    if (widget.initialSound != null) {
      if (_builtInSounds.contains(widget.initialSound)) {
        _selectedSound = widget.initialSound;
      } else {
        // It's a custom sound path
        _customSoundPath = widget.initialSound;
        _selectedSound = 'Custom';
      }
    } else {
      _selectedSound = 'Default';
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
          _selectedSound = 'Custom';
        });
        widget.onSoundSelected(_customSoundPath);
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

  void _onBuiltInSoundSelected(String sound) {
    setState(() {
      _selectedSound = sound;
      _customSoundPath = null;
    });
    
    // Map built-in sounds to identifiers
    String soundPath;
    switch (sound) {
      case 'Default':
        soundPath = 'builtin_default';
        break;
      case 'Soft Beep':
        soundPath = 'builtin_soft_beep';
        break;
      case 'Digital Tone':
        soundPath = 'builtin_digital_tone';
        break;
      case 'Classic Alarm':
        soundPath = 'builtin_classic_alarm';
        break;
      default:
        soundPath = 'builtin_default';
    }
    
    widget.onSoundSelected(soundPath);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Sound',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            children: [
              ..._builtInSounds.map((sound) {
                final isSelected = _selectedSound == sound && _customSoundPath == null;
                return Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(
                        sound,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      value: sound,
                      groupValue: _customSoundPath == null ? _selectedSound : null,
                      onChanged: (value) {
                        if (value != null) {
                          _onBuiltInSoundSelected(value);
                        }
                      },
                      activeColor: AppTheme.netflixRed,
                      selected: isSelected,
                    ),
                    if (sound != _builtInSounds.last)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[800],
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
              // Custom Sound Option
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey[800],
                indent: 16,
                endIndent: 16,
              ),
              RadioListTile<String>(
                title: Text(
                  _customSoundPath != null
                      ? 'Custom: ${_customSoundPath!.split('/').last}'
                      : 'Custom Sound',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: _customSoundPath != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                value: 'Custom',
                groupValue: _customSoundPath != null ? 'Custom' : null,
                onChanged: (value) async {
                  await _pickCustomSound();
                },
                activeColor: AppTheme.netflixRed,
                selected: _customSoundPath != null,
                secondary: _customSoundPath != null
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[400]),
                        onPressed: () {
                          setState(() {
                            _customSoundPath = null;
                            _selectedSound = 'Default';
                          });
                          widget.onSoundSelected('builtin_default');
                        },
                      )
                    : null,
              ),
            ],
          ),
        ),
        if (_customSoundPath != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: _pickCustomSound,
              icon: const Icon(Icons.audiotrack, size: 20),
              label: const Text('Change Custom Sound'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.netflixRed,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
