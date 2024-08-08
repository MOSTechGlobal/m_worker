import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyCalendarView extends StatefulWidget {
  final void Function(DateTime selectedDate) onDateSelected;
  final ColorScheme colorScheme;

  const WeeklyCalendarView(
      {Key? key, required this.onDateSelected, required this.colorScheme})
      : super(key: key);

  @override
  _WeeklyCalendarViewState createState() => _WeeklyCalendarViewState();
}

class _WeeklyCalendarViewState extends State<WeeklyCalendarView> {
  late DateTime _currentDate;
  late DateTime _minDate;
  late DateTime _maxDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _minDate = DateTime.now().subtract(const Duration(days: 365));
    _maxDate = DateTime.now().add(const Duration(days: 365));
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _currentDate = date;
    });
    widget.onDateSelected(date);
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final daysToSubtract = (weekday - DateTime.monday + 7) % 7;
    return date.subtract(Duration(days: daysToSubtract));
  }

  List<Widget> _buildWeekDays(DateTime weekStart) {
    final weekDays = <Widget>[];
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final isToday = day.day == DateTime.now().day &&
          day.month == DateTime.now().month &&
          day.year == DateTime.now().year;
      weekDays.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _updateSelectedDate(day),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: day.day == _currentDate.day &&
                    day.month == _currentDate.month &&
                    day.year == _currentDate.year
                    ? widget.colorScheme.primaryContainer
                    : day.day == DateTime.now().day &&
                    day.month == DateTime.now().month &&
                    day.year == DateTime.now().year
                    ? widget.colorScheme.tertiaryContainer.withOpacity(0.5)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(day),
                    style: TextStyle(color: widget.colorScheme.primary),
                  ),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: widget.colorScheme.primary,
                      fontWeight: day.day == _currentDate.day &&
                          day.month == _currentDate.month &&
                          day.year == _currentDate.year
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return weekDays;
  }

  void _navigateToWeek(DateTime newDate) {
    final newWeekStart = _getWeekStart(newDate);
    final oldWeekStart = _getWeekStart(_currentDate);
    var newSelectedDate = _currentDate.add(newDate.difference(oldWeekStart));

    if (newSelectedDate.isBefore(_minDate)) {
      newSelectedDate = _minDate;
    }
    if (newSelectedDate.isAfter(_maxDate)) {
      newSelectedDate = _maxDate;
    }

    setState(() {
      _currentDate = newSelectedDate;
    });

    widget.onDateSelected(newSelectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _getWeekStart(_currentDate);
    final prevWeek = weekStart.subtract(const Duration(days: 7));
    final nextWeek = weekStart.add(const Duration(days: 7));

    return Card(
      color: widget.colorScheme.secondaryContainer.withOpacity(0.8),
      borderOnForeground: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.colorScheme.primary)),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              DateFormat.yMMMM().format(weekStart),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Row(
              children: _buildWeekDays(weekStart),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios,
                      color: widget.colorScheme.primary),
                  onPressed: () {
                    _navigateToWeek(prevWeek);
                  },
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentDate = DateTime.now();
                    });
                  },
                  style: TextButton.styleFrom(
                      backgroundColor: widget.colorScheme.tertiaryContainer),
                  child: Text('Today',
                      style: TextStyle(color: widget.colorScheme.tertiary)),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios,
                      color: widget.colorScheme.primary),
                  onPressed: () {
                    _navigateToWeek(nextWeek);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
