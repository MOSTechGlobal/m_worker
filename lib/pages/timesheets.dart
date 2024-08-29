import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/components/timesheet/calendar_view.dart';
import 'package:m_worker/utils/api.dart';
import 'package:m_worker/utils/prefs.dart';

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
  Map<DateTime, String> shiftStatuses = {};

  bool isEditMode = false;
  int? editingShiftIndex;

  final Map<int, TextEditingController> _hrControllers = {};
  final Map<int, TextEditingController> _kmControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchShifts();
    _exitEditMode();
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
      final workerID = await Prefs.getWorkerID();
      if (workerID == null) {
        log('Worker ID not found');
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
          shiftStatuses = {
            for (var shift in res['data'])
              DateFormat('yyyy-MM-dd').parse(shift['ShiftStartDate']):
                  shift['TlStatus']
          };
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
    log('selectedDate: $selectedDate');
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

  Future<void> _saveShiftData(int shiftIndex) async {
    try {
      final email = await Prefs.getEmail();
      final updatedBy = email ?? 'Unknown User';
      final updateTime = DateTime.now().toIso8601String();

      final shift = shifts[shiftIndex];
      final data = {
        "TsId": shift['TsId'],
        "ShiftId": shift['ShiftId'],
        "ShiftHrs": _hrControllers[shiftIndex]?.text ?? '0',
        "Km": _kmControllers[shiftIndex]?.text ?? '0',
        "UpdateBy": updatedBy,
        "UpdateTime": updateTime,
      };

      log('Saving shift data: $data');

      final res = await Api.put('saveTimesheetDetailsWorkerSide', data);

      if (res['success']) {
        log('Shift data updated successfully');
        const snackBar = SnackBar(
          content: Text('Shift data saved successfully'),
          duration: Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        log('Error updating shift data: ${res['message']}');
        final snackBar = SnackBar(
          content: Text('Error saving shift data: ${res['message']}'),
          duration: const Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      log('Error saving shift data: $e');
    }
  }

  // todo pending implementation week wise and thus indicate the calender
  Future<void> _submitBtn(int shiftIndex) async {
    try {
      final email = await Prefs.getEmail();
      final updatedBy = email ?? 'Unknown User';
      final updateTime = DateTime.now().toIso8601String();

      final shift = shifts[shiftIndex];
      final data = {
        "TsId": shift['TsId'],
        "ShiftId": shift['ShiftId'],
        "ServiceCode": shift['ServiceCode'],
        "ClientId": shift['ClientId'],
        "TlId": shift['TlId'],
        "TlRemarks": shift['TlRemarks'],
        "TlStatus": "P",
        "RmId": shift['RmId'],
        "RmRemarks": shift['RmRemarks'],
        "RmStatus": "P",
        "WorkerRemarks": shift['WorkerRemarks'],
        "ShiftStartDate": shift['ShiftStartDate'],
        "ShiftEndDate": shift['ShiftEndDate'],
        "ExtendedMinutes": shift['ExtendedMinutes'],
        "ShiftHrs": _hrControllers[shiftIndex]?.text ?? '0',
        "Km": _kmControllers[shiftIndex]?.text ?? '0',
        "PayRate": shift['PayRate'],
        "ChargeRate": shift['ChargeRate'],
        "RecStatus": shift['RecStatus'],
        "UpdateBy": updatedBy,
        "UpdateTime": updateTime,
      };

      log('Saving shift data: $data');

      final res = await Api.put('updateTimesheetDetailData', data);

      if (res['success']) {
        log('Shift data updated successfully');
        // Show a success message or update the UI as needed
      } else {
        log('Error updating shift data: ${res['message']}');
        // Handle the error appropriately
      }
    } catch (e) {
      log('Error saving shift data: $e');
    }
  }

  void _enterEditMode(int index) {
    setState(() {
      isEditMode = true;
      editingShiftIndex = index;
    });
  }

  void _exitEditMode() {
    setState(() {
      isEditMode = false;
      editingShiftIndex = null;
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
              // submit button
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  for (int i = 0; i < shifts.length; i++) {
                    _submitBtn(i);
                  }
                },
              ),
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
                            onDateSelected: (date) {
                              setState(() {
                                selectedDate = date;
                              });
                            },
                            colorScheme: colorScheme,
                            shiftStatuses: shiftStatuses,
                          ),
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
                                : filteredShifts.isEmpty
                                    ? const Center(
                                        child: Text('No shifts found',
                                            style:
                                                TextStyle(color: Colors.grey)))
                                    : ListView.builder(
                                        itemCount: filteredShifts.length,
                                        itemBuilder: (context, index) {
                                          final shift = filteredShifts[index];
                                          final shiftIndex =
                                              shifts.indexOf(shift);
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(
                                                  context, '/shift_details',
                                                  arguments: shift['ShiftId']);
                                            },
                                            onLongPress: () {
                                              _enterEditMode(shiftIndex);
                                            },
                                            child: Card(
                                              elevation: 0,
                                              color: shift['TlStatus'] ==
                                                          'P' || // todo U for pending submission
                                                      shift['TlStatus'] == 'U'
                                                  ? colorScheme
                                                      .secondaryContainer
                                                      .withOpacity(0.5)
                                                  : shift['TlStatus'] == 'A'
                                                      ? Colors.green
                                                          .withOpacity(0.5)
                                                      : colorScheme.error
                                                          .withOpacity(0.5),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                        horizontal: 16),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
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
                                                                    TextAlign
                                                                        .left,
                                                                '#${shift['ShiftId']}',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        21,
                                                                    color: colorScheme
                                                                        .tertiary),
                                                              ),
                                                              Text(
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                                '${DateFormat('HH:mm').format(_parseDate(shift['ActualStartTime'])!)} - ${DateFormat('HH:mm').format(_parseDate(shift['ActualEndTime'])!)}',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16,
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
                                                            color: isEditMode &&
                                                                    editingShiftIndex ==
                                                                        shiftIndex
                                                                ? colorScheme
                                                                    .surface
                                                                : Colors
                                                                    .transparent,
                                                            child: isEditMode &&
                                                                    editingShiftIndex ==
                                                                        shiftIndex
                                                                ? TextField(
                                                                    controller:
                                                                        _kmControllers[
                                                                            shiftIndex],
                                                                    onChanged:
                                                                        (value) {
                                                                      shift['Km'] =
                                                                          double.tryParse(value) ??
                                                                              0;
                                                                    },
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .number,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                      border: InputBorder
                                                                          .none,
                                                                      hintText:
                                                                          '0',
                                                                    ),
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        color: colorScheme
                                                                            .primary),
                                                                  )
                                                                : Text(
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    '${shift['Km']?.toStringAsFixed(2) ?? '0'}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        color: colorScheme
                                                                            .primary),
                                                                  ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 1,
                                                          child: Card(
                                                            elevation: 0,
                                                            color: isEditMode &&
                                                                    editingShiftIndex ==
                                                                        shiftIndex
                                                                ? colorScheme
                                                                    .surface
                                                                : Colors
                                                                    .transparent,
                                                            child: isEditMode &&
                                                                    editingShiftIndex ==
                                                                        shiftIndex
                                                                ? TextField(
                                                                    controller:
                                                                        _hrControllers[
                                                                            shiftIndex],
                                                                    onChanged:
                                                                        (value) {
                                                                      _onHoursChanged(
                                                                          value,
                                                                          shiftIndex);
                                                                      shift['ShiftHrs'] =
                                                                          double.tryParse(value) ??
                                                                              0;
                                                                    },
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .number,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                      border: InputBorder
                                                                          .none,
                                                                      hintText:
                                                                          '0',
                                                                    ),
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        color: colorScheme
                                                                            .primary),
                                                                  )
                                                                : Text(
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    '${shift['ShiftHrs']?.toStringAsFixed(2) ?? '0'}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        color: colorScheme
                                                                            .primary),
                                                                  ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 1,
                                                          child: Text(
                                                            textAlign: TextAlign
                                                                .center,
                                                            '\$${(shift['PayRate'] ?? 0).toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                color: colorScheme
                                                                    .primary),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (isEditMode &&
                                                        editingShiftIndex ==
                                                            shiftIndex) ...[
                                                      Divider(
                                                        color: colorScheme
                                                            .primary
                                                            .withOpacity(0.5),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              _saveShiftData(
                                                                  shiftIndex);
                                                              _exitEditMode();
                                                            },
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  colorScheme
                                                                      .primary,
                                                              foregroundColor:
                                                                  colorScheme
                                                                      .onPrimary,
                                                            ),
                                                            child: const Text(
                                                                'Save'),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          ElevatedButton(
                                                            onPressed:
                                                                _exitEditMode,
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  colorScheme
                                                                      .primary,
                                                              foregroundColor:
                                                                  colorScheme
                                                                      .onPrimary,
                                                            ),
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
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
                Divider(
                  color: colorScheme.primary.withOpacity(0.5),
                  indent: 16,
                  endIndent: 16,
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
                const SizedBox(height: 16),
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
