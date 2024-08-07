import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/components/timesheet/calendar_view.dart';
import '../bloc/theme_bloc.dart';

class Timesheets extends StatefulWidget {
  const Timesheets({super.key});

  @override
  State<Timesheets> createState() => _TimesheetsState();
}

class _TimesheetsState extends State<Timesheets> {
  DateTime selectedDate = DateTime.now();

  // Example shifts data
  List<Map<String, dynamic>> shifts = [
    {
      'ShiftDate': DateTime.now(),
      'Hours': 8,
      'PayRate': 25.0,
    },
    {
      'ShiftDate': DateTime.now().add(Duration(days: 1)),
      'Hours': 8,
      'PayRate': 25.0,
    },
    {
      'ShiftDate': DateTime.now().add(Duration(days: 2)),
      'Hours': 8,
      'PayRate': 25.0,
    },
    {
      'ShiftDate': DateTime.now().add(Duration(days: 3)),
      'Hours': 8,
      'PayRate': 25.0,
    },
    {
      'ShiftDate': DateTime.now().add(Duration(days: 4)),
      'Hours': 8,
      'PayRate': 25.0,
    },
    {
      'ShiftDate': DateTime.now().add(Duration(days: 5)),
      'Hours': 8,
      'PayRate': 25.0,
    },
    {
      'ShiftDate': DateTime.now().add(Duration(days: 6)),
      'Hours': 8,
      'PayRate': 25.0,
    },
  ];

  // Get shifts for the selected date
  List<Map<String, dynamic>> get filteredShifts {
    return shifts.where((shift) => isSameDay(shift['ShiftDate'], selectedDate)).toList();
  }

  // Get shifts for the selected week
  List<Map<String, dynamic>> get weeklyShifts {
    final weekStart = getWeekStart(selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    return shifts.where((shift) =>
    shift['ShiftDate'].isAfter(weekStart.subtract(const Duration(days: 1))) &&
        shift['ShiftDate'].isBefore(weekEnd.add(const Duration(days: 1)))
    ).toList();
  }

  // Calculate total pay for the week
  double get weeklyTotal {
    return weeklyShifts.fold<double>(0, (sum, shift) => sum + (shift['Hours'] * shift['PayRate']));
  }

  // Helper function to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  // Get the start of the week for a given date (Monday)
  DateTime getWeekStart(DateTime date) {
    // Week starts on Monday
    final weekday = date.weekday;
    final daysToSubtract = (weekday - DateTime.monday + 7) % 7;
    return date.subtract(Duration(days: daysToSubtract));
  }

  // Callback to handle date selection
  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Timesheets'),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: WeeklyCalenderView(onDateSelected: _onDateSelected),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Text(
                        DateFormat('EE dd/MM').format(selectedDate),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Hrs.',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Pay Rate',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredShifts.length,
                  itemBuilder: (context, index) {
                    final shift = filteredShifts[index];
                    return Card(
                      color: colorScheme.tertiaryContainer,
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Text(
                                textAlign: TextAlign.left,
                                DateFormat('EE dd/MM').format(shift['ShiftDate']),
                                style: TextStyle(
                                    fontSize: 16, color: colorScheme.primary),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Card(
                                color: colorScheme.secondaryContainer,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: 16, color: colorScheme.primary
                                  ),
                                  controller: TextEditingController(
                                      text: shift['Hours'].toString()
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      shift['Hours'] = double.tryParse(value) ?? shift['Hours'];
                                    });
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                textAlign: TextAlign.right,
                                '\$${(shift['PayRate']).toStringAsFixed(2)} /hr',
                                style: TextStyle(
                                    fontSize: 16, color: colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Card(
                color: colorScheme.secondaryContainer,
                margin: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          textAlign: TextAlign.left,
                          'Weekly Total: ',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          textAlign: TextAlign.right,
                          '\$${weeklyTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
