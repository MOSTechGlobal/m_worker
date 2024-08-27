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
  List<Map<String, dynamic>> shifts = [];

  final Map<int, TextEditingController> _hrControllers = {};
  final Map<int, TextEditingController> _kmControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  @override
  void dispose() {
    for (var controller in _hrControllers.values) {
      controller.dispose();
    }
    for (var controller in _kmControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchShifts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final workerID = prefs.getString('workerID');
      log('Retrieved workerID: $workerID');
      if (workerID == null || workerID.isEmpty) {
        log('Error: workerID is null or empty');
        return;
      }

      final data = {
        "workerID": workerID,
        "weekDate": DateFormat('yyyy-MM-dd')
            .format(getWeekStart(selectedDate))
            .toString(),
      };
      log('data: $data');

      final res = await Api.post('getTimesheetDetailDataByWorkerId', data);
      log('res: $res');

      if (res['success']) {
        setState(() {
          shifts = List<Map<String, dynamic>>.from(res['data']);
          _initializeControllers();
        });
      } else {
        log('Error fetching shifts: ${res['message']}');
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
    _hrControllers.clear();
    _kmControllers.clear();
    for (int i = 0; i < shifts.length; i++) {
      _hrControllers[i] = TextEditingController(
        text: calculateShiftHours(shifts[i]).toStringAsFixed(2),
      );
      _kmControllers[i] = TextEditingController(
        text: shifts[i]['Km']?.toStringAsFixed(2) ?? '0',
      );
      setState(() {
        shifts[i]['ShiftHrs'] = calculateShiftHours(shifts[i]);
        shifts[i]['Km'] = shifts[i]['Km'] ?? 0;
      });
    }
  }

  double calculateShiftHours(Map<String, dynamic> shift) {
    if (shift['ActualStartTime'] == null || shift['ActualEndTime'] == null) {
      return 0;
    }
    final start = DateFormat('HH:mm:ss').parse(shift['ActualStartTime']);
    final end = DateFormat('HH:mm:ss').parse(shift['ActualEndTime']);
    return end.difference(start).inMinutes / 60;
  }

  double get weeklyTotal {
    return weeklyShifts.fold<double>(
      0,
      (sum, shift) =>
          sum + (calculateShiftHours(shift) * (shift['PayRate'] ?? 0)),
    );
  }

  double get dailyTotal {
    return filteredShifts.fold<double>(
      0,
      (sum, shift) =>
          sum + (calculateShiftHours(shift) * (shift['PayRate'] ?? 0)),
    );
  }

  List<Map<String, dynamic>> get filteredShifts {
    return shifts
        .where((shift) =>
            isSameDay(DateTime.parse(shift['ShiftStartDate']), selectedDate))
        .toList();
  }

  List<Map<String, dynamic>> get weeklyShifts {
    final weekStart = getWeekStart(selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    return shifts.where((shift) {
      final shiftDate = DateTime.parse(shift['ShiftStartDate']);
      return shiftDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          shiftDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

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

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  void _onHoursChanged(String value, int index) {
    final hours = double.tryParse(value) ?? 0;
    setState(() {
      shifts[index]['ShiftHrs'] = hours;
      _hrControllers[index]?.text = hours.toStringAsFixed(2);
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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchShifts,
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
                                      fontSize: 16,
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
                                      fontSize: 16,
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  textAlign: TextAlign.center,
                                  'Payrate',
                                  style: TextStyle(
                                      fontSize: 16,
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
                            padding: const EdgeInsets.all(4.0),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ListView.builder(
                                    itemCount: filteredShifts.length,
                                    itemBuilder: (context, index) {
                                      final shift = filteredShifts[index];
                                      final shiftIndex = shifts.indexOf(shift);
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/shift_details',
                                              arguments: shift);
                                        },
                                        child: Card(
                                          elevation: 0,
                                          color: shift['TlStatus'] == 'P'
                                              ? colorScheme.secondaryContainer
                                                  .withOpacity(0.5)
                                              : shift['TlStatus'] == 'A'
                                                  ? Colors.green
                                                      .withOpacity(0.5)
                                                  : colorScheme.error
                                                      .withOpacity(0.5),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 16),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Expanded(
                                                  flex: 2,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      Text(
                                                        textAlign:
                                                            TextAlign.left,
                                                        '#${shift['ShiftId']}',
                                                        style: TextStyle(
                                                            fontSize: 21,
                                                            color: colorScheme
                                                                .tertiary),
                                                      ),
                                                      Text(
                                                        textAlign:
                                                            TextAlign.left,
                                                        '${DateFormat('HH:mm').format(_parseDate(shift['ActualStartTime'])!)} - ${DateFormat('HH:mm').format(_parseDate(shift['ActualEndTime'])!)}',
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            color: colorScheme
                                                                .primary),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Card(
                                                    elevation: 0,
                                                    child: TextField(
                                                      controller:
                                                          _kmControllers[
                                                              shiftIndex],
                                                      onChanged: (value) {
                                                        _onHoursChanged(
                                                            value, shiftIndex);
                                                        shift['Km'] =
                                                            double.tryParse(
                                                                    value) ??
                                                                0;
                                                      },
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration:
                                                          const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        hintText: '0',
                                                      ),
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: colorScheme
                                                              .primary),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Card(
                                                    elevation: 0,
                                                    child: TextField(
                                                      controller:
                                                          _hrControllers[
                                                              shiftIndex],
                                                      onChanged: (value) {
                                                        _onHoursChanged(
                                                            value, shiftIndex);
                                                        shift['ShiftHrs'] =
                                                            double.tryParse(
                                                                    value) ??
                                                                0;
                                                      },
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration:
                                                          const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        hintText: '0',
                                                      ),
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: colorScheme
                                                              .primary),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    textAlign: TextAlign.center,
                                                    '\$${(shift['PayRate'] ?? 0).toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        color: colorScheme
                                                            .primary),
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
                      ],
                    ),
                  ),
                ),
                // Show daily total
                Card(
                  color: colorScheme.secondaryContainer.withOpacity(0.3),
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
                    Icon(Icons.info,
                        color: colorScheme.primary.withOpacity(.5)),
                    const SizedBox(width: 8),
                    Text('KMs travelled are not included in the total.',
                        style: TextStyle(
                            color: colorScheme.primary.withOpacity(.5))),
                  ],
                ),
                Divider(
                  color: colorScheme.primary,
                  indent: 16,
                  endIndent: 16,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return null;
    }
    return DateFormat('HH:mm:ss').parse(dateStr);
  }
}
