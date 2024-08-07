import 'dart:developer';

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
        final colorScheme = Theme
            .of(context)
            .colorScheme;

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
                decorations: [
                  DecorationItem(
                    decorationAlignment: FractionalOffset.bottomCenter,
                    date: DateTime.now(),
                    decoration: Icon(
                      Icons.circle,
                      size: 6,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
                dayOfWeek: const [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun'
                ],
                backgroundColor: Colors.transparent,
                dayOfWeekStyle: _buildTextStyle(colorScheme.primary),
                todayDateStyle: _buildTextStyle(colorScheme.primary),
                controller: weekController,
                height: 120,
                showMonth: true,
                minDate: DateTime.now().subtract(const Duration(days: 365)),
                maxDate: DateTime.now().add(const Duration(days: 365)),
                onDatePressed: (DateTime datetime) {
                  _updateSelectedDate(datetime);
                },
                onDateLongPressed: (DateTime datetime) {
                  _updateSelectedDate(datetime);
                },
                onWeekChanged: () {
                  _updateSelectedDate(
                      getWeekStart(weekController.selectedDate));
                },
                dateStyle: _buildTextStyle(colorScheme.tertiary),
                weekendsStyle: _buildTextStyle(colorScheme.tertiary),
                weekendsIndexes: const [],
                monthViewBuilder: (DateTime time) =>
                    Align(
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
                pressedDateBackgroundColor: colorScheme.primary.withOpacity(
                    0.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        final today = DateTime.now();
                        weekController.jumpToDate(today);
                        _updateSelectedDate(today);
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: colorScheme.tertiaryContainer.withOpacity(0.2),
                      fixedSize: const Size(80, 30),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                            Icons.arrow_back_ios, color: colorScheme.secondary),
                        onPressed: () {
                          setState(() {
                            final prevWeek = weekController.selectedDate.subtract(
                                const Duration(days: 7));
                            weekController.jumpToDate(prevWeek);
                            _updateSelectedDate(getWeekStart(prevWeek));
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios,
                            color: colorScheme.secondary),
                        onPressed: () {
                          setState(() {
                            final nextWeek = weekController.selectedDate.add(
                                const Duration(days: 7));
                            weekController.jumpToDate(nextWeek);
                            _updateSelectedDate(getWeekStart(nextWeek));
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
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
    final weekday = date.weekday;
    final daysToSubtract = (weekday - DateTime.monday + 7) % 7;
    return date.subtract(Duration(days: daysToSubtract));
  }
}