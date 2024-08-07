import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_calendar_week/flutter_calendar_week.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/bloc/theme_bloc.dart';

class WeeklyCalenderView extends StatefulWidget {
  final void Function(DateTime selectedDate) onDateSelected;

  const WeeklyCalenderView({super.key, required this.onDateSelected});

  @override
  _WeeklyCalenderViewState createState() => _WeeklyCalenderViewState();
}

class _WeeklyCalenderViewState extends State<WeeklyCalenderView> {
  late CalendarWeekController weekController;

  @override
  void initState() {
    super.initState();
    weekController = CalendarWeekController();
  }

  void _updateSelectedDate(DateTime date) {
    widget.onDateSelected(date);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;

        // Adjust week start and end date calculations
        final weekStartDate = getWeekStart(weekController.selectedDate); // Week starts on Monday
        final weekEndDate = weekStartDate.add(const Duration(days: 6)); // Week ends on Sunday

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.primaryContainer.withOpacity(0.9),
                  width: 1,
                ),
              ),
              borderOnForeground: true,
              child: CalendarWeek(
                dayOfWeek: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                backgroundColor: Colors.transparent,
                dayOfWeekStyle: _buildTextStyle(colorScheme.primary),
                todayDateStyle: _buildTextStyle(colorScheme.primary),
                controller: weekController,
                height: 120,
                showMonth: true,
                minDate: DateTime.now().add(const Duration(days: -365)),
                maxDate: DateTime.now().add(const Duration(days: 365)),
                onDatePressed: (DateTime datetime) {
                  _updateSelectedDate(datetime);
                },
                onDateLongPressed: (DateTime datetime) {
                  _updateSelectedDate(datetime);
                },
                onWeekChanged: () {
                  _updateSelectedDate(weekController.selectedDate);
                },
                dateStyle: _buildTextStyle(colorScheme.tertiary),
                weekendsStyle: _buildTextStyle(colorScheme.tertiary),
                weekendsIndexes: const [6], // Index for Sunday
                monthViewBuilder: (DateTime time) => Align(
                  alignment: FractionalOffset.center,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      DateFormat.yMMMM().format(time),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                dateBackgroundColor: Colors.transparent,
                todayBackgroundColor: colorScheme.primary.withOpacity(0.2),
                pressedDateBackgroundColor: colorScheme.primary.withOpacity(0.4),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: colorScheme.secondary),
                  onPressed: () {
                    setState(() {
                      weekController.jumpToDate(
                        weekStartDate.subtract(const Duration(days: 7)),
                      );
                    });
                    _updateSelectedDate(weekController.selectedDate);
                  },
                ),
                Text(
                  // Display the week start and end date
                  '${DateFormat.yMMMMd().format(weekStartDate)} - ${DateFormat.yMMMMd().format(weekEndDate)}',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: colorScheme.secondary),
                  onPressed: () {
                    setState(() {
                      weekController.jumpToDate(
                        weekStartDate.add(const Duration(days: 7)),
                      );
                    });
                    _updateSelectedDate(weekController.selectedDate);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  TextStyle _buildTextStyle(Color color) {
    return TextStyle(
      color: color,
      fontWeight: FontWeight.w800,
    );
  }

  // Calculate the start of the week (Monday)
  DateTime getWeekStart(DateTime date) {
    // Adjust for the week starting on Monday
    final weekday = date.weekday;
    final daysToSubtract = (weekday - 1 + 7) % 7; // Ensure it's positive
    final weekStart = date.subtract(Duration(days: daysToSubtract));
    return DateTime(weekStart.year, weekStart.month, weekStart.day);
  }
}
