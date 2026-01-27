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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.black : Colors.white,
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
                                color: AppTheme.netflixRed,
                                borderRadius: BorderRadius.circular(12),
                                image: photoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(photoUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: photoUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
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
                                  color: Colors.grey[700],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? AppTheme.black : Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
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
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                    backgroundColor: AppTheme.netflixRed,
                    foregroundColor: Colors.white,
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
                          isDark ? Colors.white : Colors.black,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          inProgress.toString(),
                          'In Progress',
                          AppTheme.netflixRed,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          dayStreak.toString(),
                          'Day Streak',
                          isDark ? Colors.white : Colors.black,
                          isDark,
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
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                        activeColor: AppTheme.netflixRed,
                      ),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSettingItem(
                      icon: Icons.settings_outlined,
                      title: 'Sound Settings',
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SoundSettingsScreen()),
                        );
                      },
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSettingItem(
                      icon: Icons.lock_outline,
                      title: 'Privacy & Security',
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                        );
                      },
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSettingItem(
                      icon: Icons.note_outlined,
                      title: 'My Notes',
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotesScreen()),
                        );
                      },
                      isDark: isDark,
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
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: AppTheme.netflixRed.withOpacity(0.5),
                      width: 1.5,
                    ),
                    backgroundColor: AppTheme.netflixRed.withOpacity(0.1),
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

  Widget _buildStatCard(String number, String label, Color numberColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              color: isDark ? Colors.grey[400] : Colors.grey[600],
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
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isDark ? Colors.white : Colors.black, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.grey[800] : Colors.grey[300],
      indent: 60,
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        title: Text(
          'Log Out',
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppTheme.netflixRed),
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
