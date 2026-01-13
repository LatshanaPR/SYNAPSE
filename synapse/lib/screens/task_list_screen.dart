import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _selectedFilter = 'To Do'; // Default selected filter

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Dashboard design for admin',
      'priority': 'High',
      'dueDate': '14 Oct 2022',
      'links': 5,
      'comments': 5,
    },
    {
      'title': 'Konom web application',
      'priority': 'Low',
      'dueDate': '14 Nov 2022',
      'links': 2,
      'comments': 4,
    },
    {
      'title': 'Research and development',
      'priority': 'Medium',
      'dueDate': '14 Oct 2022',
      'links': 6,
      'comments': 2,
    },
    {
      'title': 'Event booking application',
      'priority': 'Medium',
      'dueDate': '14 Oct 2022',
      'links': 5,
      'comments': 5,
    },
    {
      'title': 'Mobile app UI/UX design',
      'priority': 'High',
      'dueDate': '20 Oct 2022',
      'links': 3,
      'comments': 8,
    },
    {
      'title': 'API integration testing',
      'priority': 'Low',
      'dueDate': '25 Oct 2022',
      'links': 4,
      'comments': 2,
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
    return Container(
      color: AppTheme.black,
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      // TODO: Open drawer
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Task List',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () {
                      // TODO: Navigate
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {
                      // TODO: Show menu
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildFilterChip('Completed', '65'),
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return _buildTaskCard(_tasks[index]);
                },
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
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.netflixRed : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.grey[800]!, width: 1),
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
    
    return Container(
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
          // Title and Menu
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
                onPressed: () {
                  // TODO: Show task menu
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Priority Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: priorityColor, width: 1),
            ),
            child: Text(
              task['priority'],
              style: TextStyle(
                color: priorityColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Due Date and Icons
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                task['dueDate'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.link, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                '${task['links']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                '${task['comments']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
