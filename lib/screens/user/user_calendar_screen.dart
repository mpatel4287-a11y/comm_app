// lib/screens/user/user_calendar_screen.dart

// ignore_for_file: use_build_context_synchronously, prefer_final_fields, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/language_service.dart';
import '../../services/theme_service.dart';

class UserCalendarScreen extends StatefulWidget {
  const UserCalendarScreen({super.key});

  @override
  State<UserCalendarScreen> createState() => _UserCalendarScreenState();
}

class _UserCalendarScreenState extends State<UserCalendarScreen> {
  final EventService _eventService = EventService();
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  List<EventModel> _selectedDayEvents = [];

  // Advanced options
  bool _showPastEvents = true;
  String? _selectedEventType;
  bool _enableReminders = true;

  // Month range: -12 to +12 months from current
  DateTime get _minMonth {
    final now = DateTime.now();
    return DateTime(now.year - 1, now.month);
  }

  DateTime get _maxMonth {
    final now = DateTime.now();
    return DateTime(now.year + 1, now.month);
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  void _loadEvents() {
    _eventService.streamAllEvents().listen((events) {
      setState(() {
        _allEvents = events;
        _applyFilters();
        _updateSelectedDayEvents();
      });
    });
  }

  void _applyFilters() {
    final now = DateTime.now();
    _filteredEvents = _allEvents.where((event) {
      // Filter by past events
      if (!_showPastEvents && event.date.isBefore(now)) {
        return false;
      }
      // Filter by event type
      if (_selectedEventType != null &&
          _selectedEventType!.isNotEmpty &&
          event.type != _selectedEventType) {
        return false;
      }
      return true;
    }).toList();
  }

  void _updateSelectedDayEvents() {
    if (_selectedDay == null) {
      _selectedDayEvents = [];
      return;
    }
    _selectedDayEvents = _filteredEvents.where((event) {
      return _isSameDay(event.date, _selectedDay!);
    }).toList();
  }

  Color _getEventTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'meeting':
        return Colors.blue;
      case 'celebration':
        return Colors.orange;
      case 'reminder':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  IconData _getEventTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'meeting':
        return Icons.business;
      case 'celebration':
        return Icons.celebration;
      case 'reminder':
        return Icons.notifications;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(lang.translate('calendar')),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: lang.translate('filter_events'),
            onPressed: () => _showFilterDialog(context, lang),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: lang.translate('today'),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime.now();
                _selectedDay = DateTime.now();
                _updateSelectedDayEvents();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: lang.translate('settings'),
            onPressed: () => _showAdvancedOptions(context, lang),
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern Month Header
          _buildModernMonthHeader(lang, isDark),

          // Calendar Grid
          Expanded(flex: 3, child: _buildModernCalendarGrid(lang, isDark)),

          // Events List for Selected Day
          Expanded(flex: 2, child: _buildEventsList(lang, isDark)),
        ],
      ),
    );
  }

  Widget _buildModernMonthHeader(LanguageService lang, bool isDark) {
    final monthNames = [
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
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: _canGoBack ? Colors.blue.shade900 : Colors.grey,
            ),
            onPressed: _canGoBack ? _goToPreviousMonth : null,
          ),
          GestureDetector(
            onTap: () => _showMonthYearPicker(context, lang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: _canGoForward ? Colors.blue.shade900 : Colors.grey,
            ),
            onPressed: _canGoForward ? _goToNextMonth : null,
          ),
        ],
      ),
    );
  }

  Widget _buildModernCalendarGrid(LanguageService lang, bool isDark) {
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
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Day headers
            Row(
              children: daysOfWeek.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Calendar days
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 42, // 6 weeks * 7 days
                itemBuilder: (context, index) {
                  final dayOffset = index - startingWeekday;
                  if (dayOffset < 0 || dayOffset >= daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final dayNumber = dayOffset + 1;
                  final currentDay = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month,
                    dayNumber,
                  );

                  final dayEvents = _getEventsForDay(currentDay);
                  final isSelected =
                      _selectedDay != null &&
                      _isSameDay(currentDay, _selectedDay!);
                  final isToday = _isSameDay(currentDay, DateTime.now());
                  final hasEvents = dayEvents.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = currentDay;
                        _updateSelectedDayEvents();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade900
                            : isToday
                            ? Colors.blue.shade50
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected
                            ? Border.all(color: Colors.blue.shade300, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                  ? Colors.blue.shade900
                                  : isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          if (hasEvents)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              height: 4,
                              width: 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : _getEventTypeColor(dayEvents.first.type),
                                shape: BoxShape.circle,
                              ),
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
    );
  }

  Widget _buildEventsList(LanguageService lang, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.event_note, color: Colors.blue.shade900, size: 20),
                const SizedBox(width: 8),
                Text(
                  _selectedDay != null
                      ? '${lang.translate('events_for')} ${_formatDate(_selectedDay!)}'
                      : lang.translate('select_date'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_selectedDayEvents.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedDayEvents.length}',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _selectedDayEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang.translate('no_events_today'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _selectedDayEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedDayEvents[index];
                      final eventColor = _getEventTypeColor(event.type);
                      final isPast = event.date.isBefore(DateTime.now());

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700
                              : eventColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: eventColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: eventColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getEventTypeIcon(event.type),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            event.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                              decoration: isPast
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.time.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      event.time,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (event.location.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        event.location,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (event.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  event.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: isPast
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                )
                              : null,
                          onTap: () => _showEventDetails(context, event, lang),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context, LanguageService lang) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('select_date')),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      final newYear = DateTime(
                        _focusedMonth.year - 1,
                        _focusedMonth.month,
                      );
                      if (newYear.isAfter(_minMonth) ||
                          newYear.isAtSameMomentAs(_minMonth)) {
                        setState(() => _focusedMonth = newYear);
                      }
                    },
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      _focusedMonth.year.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final newYear = DateTime(
                        _focusedMonth.year + 1,
                        _focusedMonth.month,
                      );
                      if (newYear.isBefore(_maxMonth) ||
                          newYear.isAtSameMomentAs(_maxMonth)) {
                        setState(() => _focusedMonth = newYear);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Month grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final isSelected = _focusedMonth.month - 1 == index;
                  final isCurrentMonth =
                      DateTime.now().month - 1 == index &&
                      DateTime.now().year == _focusedMonth.year;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, index + 1);
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade900
                            : isCurrentMonth
                            ? Colors.blue.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          monthNames[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected || isCurrentMonth
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime.now();
                _selectedDay = DateTime.now();
                _updateSelectedDayEvents();
              });
              Navigator.pop(context);
            },
            child: Text(lang.translate('today')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel')),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('filter_events')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text(lang.translate('show_past_events')),
              value: _showPastEvents,
              onChanged: (value) {
                setState(() {
                  _showPastEvents = value;
                  _applyFilters();
                  _updateSelectedDayEvents();
                });
              },
            ),
            const Divider(),
            ListTile(
              title: Text(lang.translate('event_type')),
              subtitle: DropdownButton<String>(
                value: _selectedEventType,
                isExpanded: true,
                hint: Text(lang.translate('all_events')),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(lang.translate('all_events')),
                  ),
                  DropdownMenuItem(
                    value: 'general',
                    child: Text(lang.translate('general')),
                  ),
                  DropdownMenuItem(
                    value: 'meeting',
                    child: Text(lang.translate('meeting')),
                  ),
                  DropdownMenuItem(
                    value: 'celebration',
                    child: Text(lang.translate('celebration')),
                  ),
                  DropdownMenuItem(
                    value: 'reminder',
                    child: Text(lang.translate('reminder')),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value;
                    _applyFilters();
                    _updateSelectedDayEvents();
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showPastEvents = true;
                _selectedEventType = null;
                _applyFilters();
                _updateSelectedDayEvents();
              });
              Navigator.pop(context);
            },
            child: Text(lang.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('save')),
          ),
        ],
      ),
    );
  }

  void _showAdvancedOptions(BuildContext context, LanguageService lang) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('advanced'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(lang.translate('enable_reminders')),
              subtitle: Text(lang.translate('event_reminders')),
              value: _enableReminders,
              onChanged: (value) {
                setState(() => _enableReminders = value);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(lang.translate('export_calendar')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${lang.translate('export_calendar')} - Coming soon',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(
    BuildContext context,
    EventModel event,
    LanguageService lang,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getEventTypeColor(event.type),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getEventTypeIcon(event.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(event.title, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.time.isNotEmpty) ...[
              _buildDetailRow(
                Icons.access_time,
                lang.translate('time'),
                event.time,
              ),
              const SizedBox(height: 8),
            ],
            if (event.location.isNotEmpty) ...[
              _buildDetailRow(
                Icons.location_on,
                lang.translate('location'),
                event.location,
              ),
              const SizedBox(height: 8),
            ],
            if (event.description.isNotEmpty) ...[
              Text(
                lang.translate('description'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(event.description),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return _filteredEvents.where((event) {
      return _isSameDay(event.date, day);
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
}
