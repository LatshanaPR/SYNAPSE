import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskService _taskService = TaskService();
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month);
  }

  /// Check if task falls within 14-day window from today and has status 'ToDo'
  bool _isInUpcomingWindow(Map<String, dynamic> data) {
    if (data['isDeleted'] == true) return false;
    final status = data['status'] as String? ?? 'ToDo';
    if (status != 'ToDo') return false;

    final dt = (data['dateTime'] as Timestamp?)?.toDate();
    if (dt == null) return false;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOf14Days = startOfToday.add(const Duration(days: 14, hours: 23, minutes: 59, seconds: 59));

    return !dt.isBefore(startOfToday) && !dt.isAfter(endOf14Days);
  }

  /// Check if due within 24 hours
  bool _isSoon(DateTime dueAt) {
    final now = DateTime.now();
    final in24h = now.add(const Duration(hours: 24));
    return !dueAt.isBefore(now) && !dueAt.isAfter(in24h);
  }

  String _formatTime(DateTime d) {
    return DateFormat('h:mm a').format(d);
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.month - 1];
  }

  String _getDayName(DateTime date) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calendar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Plan your schedule',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              // Calendar Card with StreamBuilder for event dots
              StreamBuilder<QuerySnapshot>(
                stream: _taskService.getTasks(),
                builder: (context, snapshot) {
                  List<DateTime> datesWithEvents = [];
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['isDeleted'] == true) continue;
                      if ((data['status'] as String? ?? 'ToDo') != 'ToDo') continue;
                      final dt = (data['dateTime'] as Timestamp?)?.toDate();
                      if (dt != null) {
                        final d = DateTime(dt.year, dt.month, dt.day);
                        if (!datesWithEvents.any((x) => x.year == d.year && x.month == d.month && x.day == d.day)) {
                          datesWithEvents.add(d);
                        }
                      }
                    }
                  }
                  return Container(
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_getMonthName(_currentMonth)} ${_currentMonth.year}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildCalendar(datesWithEvents),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Reminders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminders',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_getDayName(_selectedDate)}, ${_getMonthName(_selectedDate)} ${_selectedDate.day}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _taskService.getTasks(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Couldn\'t load reminders.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.netflixRed),
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  final reminders = <Map<String, dynamic>>[];
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (!_isInUpcomingWindow(data)) continue;
                    final dt = (data['dateTime'] as Timestamp).toDate();
                    reminders.add({
                      'title': data['title'] as String? ?? 'Untitled',
                      'time': _formatTime(dt),
                      'isSoon': _isSoon(dt),
                      '_dateTime': dt,
                    });
                  }
                  reminders.sort((a, b) => (a['_dateTime'] as DateTime).compareTo(b['_dateTime'] as DateTime));
                  if (reminders.isEmpty) {
                    return Text(
                      'No upcoming reminders',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    );
                  }
                  return Column(
                    children: reminders.map((r) => _buildReminderCard(r)).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(List<DateTime> datesWithEvents) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7;

    final List<Widget> weeks = [];
    List<Widget> currentWeek = [];

    for (int i = 0; i < firstWeekday; i++) {
      currentWeek.add(const Expanded(child: SizedBox()));
    }

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final hasEvent = datesWithEvents.any((d) =>
          d.year == date.year && d.month == date.month && d.day == date.day);

      currentWeek.add(
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.netflixRed : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (hasEvent && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.netflixRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      if (currentWeek.length == 7) {
        weeks.add(Row(children: List.from(currentWeek)));
        currentWeek.clear();
      }
    }

    while (currentWeek.length < 7) {
      currentWeek.add(const Expanded(child: SizedBox()));
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(Row(children: currentWeek));
    }

    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Center(child: Text('Sun', style: TextStyle(fontSize: 12, color: Colors.grey)))),
            Expanded(child: Center(child: Text('Mon', style: TextStyle(fontSize: 12, color: Colors.grey)))),
            Expanded(child: Center(child: Text('Tue', style: TextStyle(fontSize: 12, color: Colors.grey)))),
            Expanded(child: Center(child: Text('Wed', style: TextStyle(fontSize: 12, color: Colors.grey)))),
            Expanded(child: Center(child: Text('Thu', style: TextStyle(fontSize: 12, color: Colors.grey)))),
            Expanded(child: Center(child: Text('Fri', style: TextStyle(fontSize: 12, color: Colors.grey)))),
            Expanded(child: Center(child: Text('Sat', style: TextStyle(fontSize: 12, color: Colors.grey)))),
          ],
        ),
        const SizedBox(height: 12),
        ...weeks,
      ],
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final isSoon = reminder['isSoon'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: isSoon ? Border.all(color: AppTheme.netflixRed.withOpacity(0.5), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSoon ? AppTheme.netflixRed : Colors.grey[700]!,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: isSoon ? AppTheme.netflixRed : Colors.grey[500],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      reminder['time'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.netflixRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Soon',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
