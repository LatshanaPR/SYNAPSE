import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import 'sound_settings_screen.dart';
import 'edit_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppTheme.netflixRed;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SoundSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Task List',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance the left menu icon
                ],
              ),
            ),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.netflixRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: 'To Do'),
                  Tab(text: 'Complete'),
                  Tab(text: 'Review'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Task List with StreamBuilder
            Expanded(
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

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        Center(
                          child: Text(
                            'No tasks yet',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                        Center(
                          child: Text(
                            'No tasks yet',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                        Center(
                          child: Text(
                            'No tasks yet',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      ],
                    );
                  }

                  final allDocs = snapshot.data!.docs
                      .where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        // Filter out deleted tasks
                        return data['isDeleted'] != true;
                      })
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['status'] == 'ToDo';
                      }).toList()),
                      _buildTaskList(allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['status'] == 'Complete';
                      }).toList()),
                      _buildTaskList(allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['status'] == 'Review';
                      }).toList()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          'No tasks yet',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildTaskCard(data, doc.id);
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, String taskId) {
    final priorityColor = _getPriorityColor(task['priority'] ?? 'Medium');
    
    // Format dateTime from Firestore Timestamp
    String formattedDate = 'No date';
    if (task['dateTime'] != null) {
      final timestamp = task['dateTime'] as Timestamp;
      final date = timestamp.toDate();
      formattedDate = DateFormat('dd MMM yyyy').format(date);
    }

    // Get status display name
    String statusDisplay = task['status'] ?? 'ToDo';
    Color statusColor = Colors.grey[700]!;
    if (statusDisplay == 'Complete') {
      statusColor = Colors.green;
    } else if (statusDisplay == 'Review') {
      statusColor = AppTheme.netflixRed;
    } else if (statusDisplay == 'ToDo') {
      statusColor = Colors.blue;
    }

    return GestureDetector(
      onLongPress: () => _showTaskOptions(context, task, taskId),
      child: Dismissible(
        key: Key(taskId),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 30,
          ),
        ),
        confirmDismiss: (direction) async {
          return await _confirmDelete(context, taskId);
        },
        onDismissed: (direction) {
          _deleteTask(taskId);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task['title'] ?? 'Untitled Task',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.netflixRed, size: 20),
                    onPressed: () {
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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit Task',
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () async {
                      final confirmed = await _confirmDelete(context, taskId);
                      if (confirmed == true) {
                        _deleteTask(taskId);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete Task',
                  ),
                ],
              ),
              if (task['description'] != null && task['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildBadge(task['priority'] ?? 'Medium', priorityColor),
                  const SizedBox(width: 8),
                  _buildBadge(statusDisplay, statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const Spacer(),
                  // Status Update Actions
                  if (statusDisplay != 'Complete')
                    TextButton.icon(
                      onPressed: () => _updateTaskStatus(taskId, 'Complete'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      label: Text(
                        'Complete',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (statusDisplay != 'Review')
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: TextButton.icon(
                        onPressed: () => _updateTaskStatus(taskId, 'Review'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.rate_review, size: 16, color: AppTheme.netflixRed),
                        label: Text(
                          'Review',
                          style: TextStyle(
                            color: AppTheme.netflixRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _taskService.updateTaskStatus(taskId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task moved to $newStatus'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTaskOptions(BuildContext context, Map<String, dynamic> task, String taskId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.netflixRed),
              title: const Text('Edit Task', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
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
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Task', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, taskId).then((confirmed) {
                  if (confirmed == true) {
                    _deleteTask(taskId);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String taskId) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Delete Task',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _taskService.softDeleteTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
