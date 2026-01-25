import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import 'edit_task_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _taskService.runOverdueCheck();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _taskService.getTasks(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.netflixRed,
                ),
              );
            }

            // Process tasks from Firestore
            final allDocs = snapshot.data?.docs ?? [];
            final tasks = allDocs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null) return null;
                  return {'id': doc.id, 'data': data};
                })
                .whereType<Map<String, dynamic>>()
                .where((task) {
                  final data = task['data'] as Map<String, dynamic>?;
                  return data != null && data['isDeleted'] != true;
                })
                .toList();

            // Calculate statistics
            final totalTasks = tasks.length;
            final completedTasks = tasks
                .where((task) {
                  final data = task['data'] as Map<String, dynamic>?;
                  return data?['status'] == 'Complete';
                })
                .length;
            final pendingTasks = tasks
                .where((task) {
                  final data = task['data'] as Map<String, dynamic>?;
                  return data?['status'] == 'ToDo';
                })
                .length;
            final notDoneTasks = tasks
                .where((task) {
                  final data = task['data'] as Map<String, dynamic>?;
                  final s = data?['status'] as String?;
                  return s == 'notDone' || s == 'Review';
                })
                .length;

            // Get weekly chart data
            final weeklyData = _calculateWeeklyData(tasks);

            // Get 4 nearest upcoming tasks
            final upcomingTasks = _getUpcomingTasks(tasks);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Project Summary',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 24),
                  // Summary Cards 2x2
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          Icons.calendar_today,
                          pendingTasks.toString(),
                          'Pending',
                          AppTheme.netflixRed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          Icons.access_time,
                          notDoneTasks.toString(),
                          'Not Done',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          Icons.warning_rounded,
                          totalTasks.toString(),
                          'Total Tasks',
                          AppTheme.netflixRed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          Icons.check_circle,
                          completedTasks.toString(),
                          'Completed',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Project Statistics Chart
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Project Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildBarGroup('S', weeklyData['S'] ?? const [0.0, 0.0, 0.0]),
                              _buildBarGroup('M', weeklyData['M'] ?? const [0.0, 0.0, 0.0]),
                              _buildBarGroup('T', weeklyData['T'] ?? const [0.0, 0.0, 0.0]),
                              _buildBarGroup('W', weeklyData['W'] ?? const [0.0, 0.0, 0.0]),
                              _buildBarGroup('T', weeklyData['T2'] ?? const [0.0, 0.0, 0.0]),
                              _buildBarGroup('F', weeklyData['F'] ?? const [0.0, 0.0, 0.0]),
                              _buildBarGroup('S', weeklyData['S2'] ?? const [0.0, 0.0, 0.0]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(Colors.purple, 'Progress'),
                            const SizedBox(width: 20),
                            _buildLegendItem(Colors.pink, 'Not Done'),
                            const SizedBox(width: 20),
                            _buildLegendItem(Colors.green, 'Complete'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Upcoming Tasks Section
                  const Text(
                    'Upcoming Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (upcomingTasks.isNotEmpty) ...[
                    ...upcomingTasks.take(4).map((task) => _buildUpcomingTaskCard(
                          task['id'] as String,
                          task['data'] as Map<String, dynamic>,
                        )),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'No upcoming tasks',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Bottom Metrics
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Tasks',
                          totalTasks.toString(),
                          '',
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Completed',
                          completedTasks.toString(),
                          totalTasks > 0
                              ? '${((completedTasks / totalTasks) * 100).toStringAsFixed(0)}%'
                              : '0%',
                          true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Calculate weekly statistics from tasks
  Map<String, List<double>> _calculateWeeklyData(List<Map<String, dynamic>> tasks) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    
    // Group tasks by day of week for the current week
    final Map<String, List<Map<String, dynamic>>> tasksByDay = {
      'S': [], // Sunday
      'M': [],
      'T': [],
      'W': [],
      'T2': [], // Thursday
      'F': [],
      'S2': [], // Saturday
    };

    for (var task in tasks) {
      final data = task['data'] as Map<String, dynamic>;
      final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
      
      if (dateTime != null) {
        // Check if task is within current week
        final daysDiff = dateTime.difference(weekStart).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          final dayOfWeek = dateTime.weekday;
          String dayKey;
          switch (dayOfWeek) {
            case 1: dayKey = 'M'; break;
            case 2: dayKey = 'T'; break;
            case 3: dayKey = 'W'; break;
            case 4: dayKey = 'T2'; break;
            case 5: dayKey = 'F'; break;
            case 6: dayKey = 'S2'; break;
            case 7: dayKey = 'S'; break;
            default: continue;
          }
          tasksByDay[dayKey]?.add(data);
        }
      }
    }

    // Calculate heights for each day: [Progress, Not Done, Complete]
    final Map<String, List<double>> result = {};
    for (var entry in tasksByDay.entries) {
      final dayTasks = entry.value;
      final progress = dayTasks.where((t) => t['status'] == 'ToDo').length.toDouble();
      final notDone = dayTasks
          .where((t) => t['status'] == 'notDone' || t['status'] == 'Review')
          .length
          .toDouble();
      final complete = dayTasks.where((t) => t['status'] == 'Complete').length.toDouble();
      
      // Normalize to 0-150 range for chart display
      final max = [progress, notDone, complete].reduce((a, b) => a > b ? a : b);
      final scale = max > 0 ? 150.0 / max : 1.0;
      
      result[entry.key] = [
        progress * scale,
        notDone * scale,
        complete * scale,
      ];
    }

    return result;
  }

  /// Get upcoming tasks (next 4 tasks by effectiveDueTime)
  List<Map<String, dynamic>> _getUpcomingTasks(List<Map<String, dynamic>> tasks) {
    final now = DateTime.now();
    
    final upcoming = tasks
        .where((task) {
          final data = task['data'] as Map<String, dynamic>;
          final status = data['status'] as String?;
          final effectiveDue = TaskService.getEffectiveDueTime(data);
          if (effectiveDue == null) return false;
          return status != 'Complete' &&
                 status != 'notDone' &&
                 status != 'Review' &&
                 effectiveDue.isAfter(now);
        })
        .toList();

    // Sort by effectiveDueTime (ascending)
    upcoming.sort((a, b) {
      final dueA = TaskService.getEffectiveDueTime(a['data'] as Map<String, dynamic>);
      final dueB = TaskService.getEffectiveDueTime(b['data'] as Map<String, dynamic>);
      if (dueA == null && dueB == null) return 0;
      if (dueA == null) return 1;
      if (dueB == null) return -1;
      return dueA.compareTo(dueB);
    });

    return upcoming.take(4).toList();
  }

  /// Build upcoming task card
  Widget _buildUpcomingTaskCard(String taskId, Map<String, dynamic> task) {
    final title = task['title'] as String? ?? 'Untitled';
    final dateTime = TaskService.getEffectiveDueTime(task);
    final priority = task['priority'] as String? ?? 'Medium';
    
    String dateStr = 'No date';
    if (dateTime != null) {
      final now = DateTime.now();
      final daysDiff = dateTime.difference(now).inDays;
      if (daysDiff == 0) {
        dateStr = 'Today';
      } else if (daysDiff == 1) {
        dateStr = 'Tomorrow';
      } else {
        dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    }

    Color priorityColor = Colors.orange;
    if (priority == 'High') {
      priorityColor = AppTheme.netflixRed;
    } else if (priority == 'Low' || priority == 'Medium') {
      priorityColor = Colors.green;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTaskScreen(
              taskId: taskId,
              taskData: task,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: priorityColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String number, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            number,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildBarGroup(String label, List<double> heights) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 8,
                height: heights[0],
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 8,
                height: heights[1],
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 8,
                height: heights[2],
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String change, bool isPositive) {
    final showChange = change.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showChange)
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: isPositive ? Colors.green : AppTheme.netflixRed,
                    ),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : AppTheme.netflixRed,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
