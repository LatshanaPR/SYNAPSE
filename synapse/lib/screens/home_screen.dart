import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/task_scheduler_service.dart';
import '../services/task_service.dart';
import 'task_list_screen.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TaskSchedulerService _schedulerService = TaskSchedulerService();
  final TaskService _taskService = TaskService();

  final List<Widget> _screens = [
    const TaskListScreen(),
    const DashboardScreen(),
    const CalendarScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _taskService.runOverdueCheck();
    // Start monitoring tasks for notifications/alarms
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulerService.startMonitoring(context);
    });
  }

  @override
  void dispose() {
    _schedulerService.stopMonitoring();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update context for alarm service when navigating
    _schedulerService.updateContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTaskScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.netflixRed,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0 || index == 1) _taskService.runOverdueCheck();
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[900],
        selectedItemColor: AppTheme.netflixRed,
        unselectedItemColor: Colors.grey[500],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          _buildNavItem(Icons.checklist, 'Tasks', 0),
          _buildNavItem(Icons.dashboard, 'Dashboard', 1),
          _buildNavItem(Icons.calendar_today, 'Calendar', 2),
          _buildNavItem(Icons.search, 'Search', 3),
          _buildNavItem(Icons.person, 'Profile', 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: isSelected
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.netflixRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            )
          : Icon(icon),
      label: label,
    );
  }
}
