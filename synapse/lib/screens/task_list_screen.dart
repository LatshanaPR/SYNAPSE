import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _selectedFilter = 'Complete';

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Dashboard design for admin',
      'priority': 'High',
      'status': 'On Track',
      'dueDate': '14 oct 2022',
      'links': 5,
      'comments': 5,
      'users': ['JD', 'JS', 'BW'],
    },
    {
      'title': 'Konom web application',
      'priority': 'Low',
      'status': 'Meeting',
      'dueDate': '14 Nov 2022',
      'links': 2,
      'comments': 4,
      'users': ['AE', 'CC', 'EJ'],
    },
    {
      'title': 'Research and development',
      'priority': 'Medium',
      'status': 'At Risk',
      'dueDate': '14 oct 2022',
      'links': 6,
      'comments': 2,
      'users': ['FM', 'GL'],
      'hasBorder': true,
    },
    {
      'title': 'Event booking application',
      'priority': 'Medium',
      'status': 'Meeting',
      'dueDate': '14 oct 2022',
      'links': 5,
      'comments': 5,
      'users': ['HC'],
    },
  ];

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
                    onPressed: () {},
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
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip('Complete', '65'),
                  const SizedBox(width: 12),
                  _buildFilterChip('To Do', '45'),
                  const SizedBox(width: 12),
                  _buildFilterChip('In Review', '3'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Task List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tasks.length,
                itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.netflixRed : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label $count',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final priorityColor = _getPriorityColor(task['priority']);
    final hasBorder = task['hasBorder'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: hasBorder ? Border.all(color: Colors.green, width: 1) : null,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBadge(task['priority'], priorityColor),
              const SizedBox(width: 8),
              _buildBadge(
                task['status'],
                task['status'] == 'On Track'
                    ? Colors.green
                    : task['status'] == 'At Risk'
                        ? AppTheme.netflixRed
                        : Colors.grey[700]!,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                task['dueDate'],
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.link, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                '${task['links']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                '${task['comments']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const Spacer(),
              ...(task['users'] as List<String>).map((user) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey[700],
                      child: Text(
                        user,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
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
