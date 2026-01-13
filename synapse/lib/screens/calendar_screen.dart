import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime(2026, 1, 11);
  DateTime _currentMonth = DateTime(2026, 1);

  final List<Map<String, dynamic>> _reminders = [
    {
      'title': 'Team standup meeting',
      'time': '9:00 AM',
      'isSoon': true,
    },
    {
      'title': 'Design review with stakeholders',
      'time': '11:30 AM',
      'isSoon': true,
    },
    {
      'title': 'Submit weekly report',
      'time': '3:00 PM',
      'isSoon': false,
    },
    {
      'title': 'One-on-one with manager',
      'time': '4:30 PM',
      'isSoon': false,
    },
  ];

  List<DateTime> _getDatesWithEvents() {
    return [
      DateTime(2026, 1, 12),
      DateTime(2026, 1, 15),
      DateTime(2026, 1, 18),
      DateTime(2026, 1, 22),
    ];
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
              // Calendar Card
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
                    _buildCalendar(),
                  ],
                ),
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
              ..._reminders.map((r) => _buildReminderCard(r)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7;
    final datesWithEvents = _getDatesWithEvents();

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
