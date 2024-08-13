import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/components/timesheet/calendar_view.dart';
import 'package:m_worker/utils/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/theme_bloc.dart';

class Timesheets extends StatefulWidget {
  const Timesheets({super.key});

  @override
  State<Timesheets> createState() => _TimesheetsState();
}

class _TimesheetsState extends State<Timesheets> {
  DateTime selectedDate = DateTime.now();

  bool _isLoading = false;

  // Example shifts data
  List<Map<String, dynamic>> shifts = [];

  // Controllers for editable fields
  final Map<int, TextEditingController> _hrControllers = {};
  final Map<int, TextEditingController> _kmControllers = {};

  Future<void> _fetchShifts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final workerID = prefs.getString('workerID');
      final res = await Api.get('getShiftMainDataByWorkerID/$workerID');
      log('res: $res');
      if (res['success']) {
        setState(() {
          shifts = List<Map<String, dynamic>>.from(res['data']);
          _initializeControllers();
        });
      }
    } catch (e) {
      log('Error fetching shifts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeControllers() {
    // Initialize controllers for each shift
    _hrControllers.clear(); // Clear existing controllers
    for (int i = 0; i < shifts.length; i++) {
      _hrControllers[i] = TextEditingController(
        text: calculateShiftHours(shifts[i]).toStringAsFixed(2),
      );
      setState(() {
        shifts[i]['Hours'] = calculateShiftHours(shifts[i]);
      });
    }

    _kmControllers.clear(); // Clear existing controllers
    for (int i = 0; i < shifts.length; i++) {
      _kmControllers[i] = TextEditingController(
        text: shifts[i]['Km']?.toStringAsFixed(2) ?? '0',
      );
      setState(() {
        shifts[i]['Km'] = shifts[i]['Km'] ?? 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  @override
  void dispose() {
    // Dispose controllers when no longer needed
    for (var controller in _hrControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double calculateShiftHours(Map<String, dynamic> shift) {
    final start = DateTime.parse(shift['ShiftStart']);
    final end = DateTime.parse(shift['ShiftEnd']);
    return end.difference(start).inMinutes / 60;
  }

  // Calculate total pay for the week
  double get weeklyTotal {
    return weeklyShifts.fold<double>(
        0, (sum, shift) => sum + ((shift['Hours'] ?? calculateShiftHours(shift)) * (shift['PayRate'] ?? 0)));
  }

  double get dailyTotal {
    return filteredShifts.fold<double>(
        0, (sum, shift) => sum + ((shift['Hours'] ?? calculateShiftHours(shift)) * (shift['PayRate'] ?? 0)));
  }

  // Get shifts for the selected date
  List<Map<String, dynamic>> get filteredShifts {
    return shifts
        .where((shift) => isSameDay(DateTime.parse(shift['ShiftStart']), selectedDate))
        .toList();
  }

  // Get shifts for the selected week
  List<Map<String, dynamic>> get weeklyShifts {
    final weekStart = getWeekStart(selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 6)); // End of the week
    return shifts
        .where((shift) {
      final shiftDate = DateTime.parse(shift['ShiftStart']);
      return shiftDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          shiftDate.isBefore(weekEnd.add(const Duration(days: 1)));
    })
        .toList();
  }

  // Helper function to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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

  void _onHoursChanged(String value, int index) {
    final hours = double.tryParse(value) ?? 0;
    setState(() {
      shifts[index]['Hours'] = hours;
      _hrControllers[index]?.text = hours.toStringAsFixed(2); // Update controller text
    });
  }

  // TODO: what to do with modification of hours?

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Timesheets'),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: colorScheme.primary),
                color: colorScheme.onPrimary,
                onPressed: () {
                  setState(() {
                    final newShift = {
                      'ShiftStart': DateTime.now().toIso8601String(),
                      'ShiftEnd': DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
                      'ClientFirstName': 'New',
                      'ClientLastName': 'Client',
                      'PayRate': 25.0,
                      'Hours': 8,
                    };
                    shifts.add(newShift);
                    _hrControllers[shifts.length - 1] = TextEditingController(text: '8');
                  });
                },
              ),
            ],
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
                          child: WeeklyCalendarView(
                              onDateSelected: _onDateSelected,
                              colorScheme: colorScheme),
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
                                  'Km.',
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
                            child: _isLoading ?
                                const Center(child: CircularProgressIndicator()) :
                            ListView.builder(
                              itemCount: filteredShifts.length,
                              itemBuilder: (context, index) {
                                final shift = filteredShifts[index];
                                final shiftIndex = shifts.indexOf(shift);
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/shift_details', arguments: shift);
                                  },
                                  child: Card(
                                    color: colorScheme.tertiaryContainer,
                                    margin: const EdgeInsets.all(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  textAlign: TextAlign.left,
                                                  '${DateFormat('HH:mm').format(DateTime.parse(shift['ShiftStart']))} - ${DateFormat('HH:mm').format(DateTime.parse(shift['ShiftEnd']))}',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: colorScheme.primary),
                                                ),
                                                Text(
                                                  textAlign: TextAlign.left,
                                                  '${shift['ClientFirstName']} ${shift['ClientLastName']}',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: colorScheme.primary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Card(
                                              elevation: 0,
                                              child: TextField(
                                                controller: _kmControllers[shiftIndex],
                                                onChanged: (value) {
                                                  _onHoursChanged(value, shiftIndex);
                                                  setState(() {
                                                    _kmControllers[shiftIndex]?.text = value;
                                                  });
                                                },
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  hintText: 'KMs',
                                                  hintStyle: TextStyle(
                                                      color: colorScheme.primary),
                                                  border: const UnderlineInputBorder(
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: colorScheme.primary),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Card(
                                              elevation: 0,
                                              child: TextField(
                                                controller: _hrControllers[shiftIndex],
                                                onChanged: (value) {
                                                  _onHoursChanged(value, shiftIndex);
                                                  setState(() {
                                                    _hrControllers[shiftIndex]?.text = value;
                                                  });
                                                },
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  hintText: 'Hours',
                                                  hintStyle: TextStyle(
                                                      color: colorScheme.primary),
                                                  border: const UnderlineInputBorder(
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: colorScheme.primary),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              textAlign: TextAlign.right,
                                              '\$${(shift['PayRate'] ?? 0).toStringAsFixed(2)} /hr',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: colorScheme.primary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Show daily total
                        Card(
                          color: colorScheme.secondaryContainer.withOpacity(0.8),
                          elevation: 0,
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
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    textAlign: TextAlign.right,
                                    '\$${dailyTotal.toStringAsFixed(2)}',
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
                        // Show weekly total
                        Card(
                          color: Colors.transparent,
                          elevation: 0,
                          margin: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info, color: colorScheme.primary.withOpacity(.5)),
                            const SizedBox(width: 8),
                            Text('KMs travelled are not included in the total.', style: TextStyle(color: colorScheme.primary.withOpacity(.5))),
                          ],
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
                        onPressed: () {},
                        child: const Text(
                          'Save',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          fixedSize: const Size(96, 48),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
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
