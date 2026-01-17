import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  String _selectedNotificationSound = 'Default';
  String _selectedAlarmSound = 'Default';

  final List<String> _soundOptions = [
    'Default',
    'Soft Beep',
    'Digital Tone',
    'Classic Alarm',
  ];

  @override
  Widget build(BuildContext context) {
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
              _buildSoundOptionsSection(_soundOptions, _selectedNotificationSound, (value) {
                setState(() {
                  _selectedNotificationSound = value;
                });
              }),
              const SizedBox(height: 32),
              // Alarm Sound Section
              _buildSectionTitle('Alarm Sound', 'For high priority tasks'),
              const SizedBox(height: 12),
              _buildSoundOptionsSection(_soundOptions, _selectedAlarmSound, (value) {
                setState(() {
                  _selectedAlarmSound = value;
                });
              }),
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

  Widget _buildSoundOptionsSection(
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final sound = entry.value;
          final isSelected = sound == selectedValue;
          final isLast = index == options.length - 1;
          
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
                groupValue: selectedValue,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
                activeColor: AppTheme.netflixRed,
                selected: isSelected,
                selectedTileColor: Colors.grey[800]?.withOpacity(0.5),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey[800],
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
