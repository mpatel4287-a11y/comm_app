// lib/screens/user/user_calendar_screen.dart

// ignore_for_file: prefer_final_fields, unused_element

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';

class UserCalendarScreen extends StatefulWidget {
  const UserCalendarScreen({super.key});

  @override
  State<UserCalendarScreen> createState() => _UserCalendarScreenState();
}

class _UserCalendarScreenState extends State<UserCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  List<EventModel> _allEvents = [];
  List<EventModel> _selectedEvents = [];
  final Map<int, List<EventModel>> _monthlyEvents = {};

  // Month range: -6 to +6 months
  DateTime get _minMonth => DateTime.now().subtract(const Duration(days: 180));
  DateTime get _maxMonth => DateTime.now().add(const Duration(days: 180));

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  void _loadEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .get();

    _allEvents = snapshot.docs.map((doc) {
      return EventModel.fromMap(doc.id, doc.data());
    }).toList();

    // Group events by month
    for (var event in _allEvents) {
      final monthKey = event.date.year * 12 + event.date.month;
      if (_monthlyEvents[monthKey] == null) {
        _monthlyEvents[monthKey] = [];
      }
      _monthlyEvents[monthKey]!.add(event);
    }

    setState(() {
      _updateSelectedEvents();
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      final newMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      if (newMonth.isAfter(_minMonth) || newMonth.isAtSameMomentAs(_minMonth)) {
        _focusedMonth = newMonth;
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      final newMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      if (newMonth.isBefore(_maxMonth) ||
          newMonth.isAtSameMomentAs(_maxMonth)) {
        _focusedMonth = newMonth;
      }
    });
  }

  bool get _canGoBack {
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    return prevMonth.isAfter(_minMonth) ||
        prevMonth.isAtSameMomentAs(_minMonth);
  }

  bool get _canGoForward {
    final nextMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    return nextMonth.isBefore(_maxMonth) ||
        nextMonth.isAtSameMomentAs(_maxMonth);
  }

  void _onDaySelected(DateTime selectedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _updateSelectedEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime.now();
                _selectedDay = DateTime.now();
                _updateSelectedEvents();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Navigation
          _buildMonthHeader(),

          // Calendar Grid
          _buildCalendarGrid(),

          // Events for selected day
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDay != null
                        ? 'Events for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                        : 'Select a date',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _selectedEvents.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text('No events on this day'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _selectedEvents.length,
                            itemBuilder: (context, index) {
                              final event = _selectedEvents[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.event,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  title: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (event.description.isNotEmpty)
                                        Text(event.description),
                                      if (event.location.isNotEmpty)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 12,
                                            ),
                                            Text(event.location),
                                          ],
                                        ),
                                      if (event.time.isNotEmpty)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 12,
                                            ),
                                            Text(event.time),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPreviousMonth,
          ),
          Expanded(
            child: Text(
              '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final startingWeekday = firstDayOfMonth.weekday;

    final totalCells = ((daysInMonth + startingWeekday) / 7).ceil() * 7;
    final cells = <Widget>[];

    // Day headers
    for (final day in daysOfWeek) {
      cells.add(
        Center(
          child: Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    // Calendar days
    for (int i = 0; i < totalCells; i++) {
      final dayNumber = i - startingWeekday + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        cells.add(const SizedBox.shrink());
      } else {
        final currentDay = DateTime(
          _focusedMonth.year,
          _focusedMonth.month,
          dayNumber,
        );
        final hasEvent = _getEventsForDay(currentDay).isNotEmpty;
        final isSelected =
            _selectedDay != null && _isSameDay(currentDay, _selectedDay!);
        final isToday = _isSameDay(currentDay, DateTime.now());

        cells.add(
          GestureDetector(
            onTap: () => _onDaySelected(currentDay),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.shade900
                    : isToday
                    ? Colors.blue.shade100
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Center(
                    child: Text(
                      dayNumber.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hasEvent)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              children: cells,
            ),
          ],
        ),
      ),
    );
  }
}
