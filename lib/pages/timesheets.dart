import 'dart:developer';

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
      'ShiftDate': DateTime.now().add(Duration(days: 2)),
      'Hours': 3,
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

  // Controllers for each shift
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each shift
    for (int i = 0; i < shifts.length; i++) {
      _controllers[i] = TextEditingController(text: shifts[i]['Hours'].toString());
    }
  }

  @override
  void dispose() {
    // Dispose controllers when no longer needed
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Get shifts for the selected date
  List<Map<String, dynamic>> get filteredShifts {
    return shifts.where((shift) => isSameDay(shift['ShiftDate'], selectedDate)).toList();
  }

  // Get shifts for the selected week
  List<Map<String, dynamic>> get weeklyShifts {
    final weekStart = getWeekStart(selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 5));
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

  DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    log('weekday: $weekday');
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
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(2.0),
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
                                  textAlign: TextAlign.left,
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
                                  textAlign: TextAlign.center,
                                  'Hrs.',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  textAlign: TextAlign.right,
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
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListView.builder(
                              itemCount: filteredShifts.length,
                              itemBuilder: (context, index) {
                                final shift = filteredShifts[index];
                                final shiftIndex = shifts.indexOf(shift);
                                return Card(
                                  color: colorScheme.tertiaryContainer,
                                  margin: const EdgeInsets.all(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Expanded(
                                          flex: 2,
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
                                              controller: _controllers[shiftIndex],
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                              ),
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.number,
                                              style: TextStyle(
                                                  fontSize: 16, color: colorScheme.primary
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
                                          flex: 2,
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
                        ),
                        // show daily total
                        Card(
                          color: colorScheme.secondaryContainer.withOpacity(0.2),
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
                                    'Daily Total: ',
                                    style: TextStyle(
                                        fontSize: 16,
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
                                    '\$${filteredShifts.fold<double>(0, (sum, shift) => sum + (shift['Hours'] * shift['PayRate'])).toStringAsFixed(2)}',
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
                        Card(
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
                                        fontSize: 16,
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
                        Divider(
                          color: colorScheme.primary,
                          indent: 16,
                          endIndent: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          fixedSize: const Size(96, 48),
                        ),
                        onPressed: () {
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: colorScheme.onPrimary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          fixedSize: const Size(48, 48),
                        ),
                        onPressed: () {
                          setState(() {
                            shifts.add({
                              'ShiftDate': selectedDate,
                              'Hours': 8,
                              'PayRate': 25.0,
                            });
                            _controllers[shifts.length - 1] = TextEditingController(text: '8');
                          });
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          fixedSize: const Size(96, 48),
                        ),
                        onPressed: () {
                        },
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
