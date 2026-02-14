import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';
import '../services/task_service.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_security_screen.dart';
import 'notes_screen.dart';
import 'sound_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final TaskService _taskService = TaskService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header with realtime data
              StreamBuilder<Map<String, dynamic>>(
                stream: _profileService.getProfileStream(),
                builder: (context, profileSnapshot) {
                  final profileData = profileSnapshot.data ?? {};
                  final email = user?.email ?? 'No email';
                  final emailPrefix = email != 'No email' && email.contains('@')
                      ? email.split('@')[0]
                      : 'User';
                  final displayName = profileData['displayName'] as String? ??
                      user?.displayName ??
                      emailPrefix;
                  final photoUrl = profileData['photoUrl'] as String?;

                  return Row(
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                                image: photoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(photoUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: photoUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: colorScheme.onPrimary,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.background,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and Email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onBackground.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              // Edit Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Task Statistics (computed from real-time task snapshots)
              StreamBuilder<QuerySnapshot>(
                stream: _taskService.getTasks(),
                builder: (context, snapshot) {
                  int tasksDone = 0;
                  int inProgress = 0;
                  int dayStreak = 0;

                  if (snapshot.hasData && snapshot.data != null) {
                    final tasks = snapshot.data!.docs;
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    
                    // Track consecutive days with completed tasks
                    final completedDates = <DateTime>{};
                    
                    for (var doc in tasks) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['isDeleted'] == true) continue;
                      
                      final status = data['status'] as String? ?? 'ToDo';
                      
                      // Count completed tasks
                      if (status == 'Complete') {
                        tasksDone++;
                        
                        // Track completion dates for streak calculation
                        final completedAt = (data['updatedAt'] as Timestamp?)?.toDate();
                        if (completedAt != null) {
                          final completedDate = DateTime(
                            completedAt.year,
                            completedAt.month,
                            completedAt.day,
                          );
                          completedDates.add(completedDate);
                        }
                      }
                      
                      // Count in-progress tasks (ToDo status)
                      if (status == 'ToDo') {
                        inProgress++;
                      }
                    }
                    
                    // Calculate day streak
                    if (completedDates.isNotEmpty) {
                      final sortedDates = completedDates.toList()..sort((a, b) => b.compareTo(a));
                      int streak = 0;
                      DateTime checkDate = today;
                      
                      for (final date in sortedDates) {
                        if (date.isAtSameMomentAs(checkDate) || 
                            date.isAtSameMomentAs(checkDate.subtract(const Duration(days: 1)))) {
                          if (date.isAtSameMomentAs(checkDate)) {
                            streak++;
                          } else {
                            streak++;
                            checkDate = date;
                          }
                        } else {
                          break;
                        }
                      }
                      
                      dayStreak = streak;
                    }
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          tasksDone.toString(),
                          'Tasks Done',
                          Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          inProgress.toString(),
                          'In Progress',
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          dayStreak.toString(),
                          'Day Streak',
                          Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              // Settings Section
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme Mode',
                      trailing: IconButton(
                        icon: Icon(
                          Theme.of(context).brightness == Brightness.dark
                              ? Icons.dark_mode
                              : Theme.of(context).brightness == Brightness.light
                                  ? Icons.light_mode
                                  : Icons.brightness_auto,
                          color: colorScheme.primary,
                        ),
                        onPressed: () {
                          Provider.of<ThemeProvider>(context, listen: false).toggleThemeMode();
                        },
                        tooltip: 'Switch Theme Mode',
                      ),
                    ),
                    _buildDivider(colorScheme),
                    _buildSettingItem(
                      icon: Icons.settings_outlined,
                      title: 'Sound Settings',
                      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.5)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SoundSettingsScreen()),
                        );
                      },
                    ),
                    _buildDivider(colorScheme),
                    _buildSettingItem(
                      icon: Icons.lock_outline,
                      title: 'Privacy & Security',
                      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.5)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                        );
                      },
                    ),
                    _buildDivider(colorScheme),
                    _buildSettingItem(
                      icon: Icons.note_outlined,
                      title: 'My Notes',
                      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.5)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotesScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Log Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: colorScheme.error.withOpacity(0.5),
                      width: 1.5,
                    ),
                    backgroundColor: colorScheme.errorContainer.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String label, Color numberColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: numberColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onSurface, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: colorScheme.outline.withOpacity(0.3),
      indent: 60,
    );
  }

  Future<void> _handleLogout() async {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Log Out',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Log Out',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.netflixRed,
            ),
          );
        }
      }
    }
  }
}
