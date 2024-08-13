import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/utils/api.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../../../bloc/theme_bloc.dart';
import '../../../components/shift_detail/shift_detail_3rd_card.dart';

class ShiftDetails extends StatefulWidget {
  final Map<dynamic, dynamic> shift;
  final ValueChanged<String> onStatusChanged;
  const ShiftDetails(
      {super.key, required this.shift, required this.onStatusChanged});

  @override
  State<ShiftDetails> createState() => _ShiftDetailsState();
}

class _ShiftDetailsState extends State<ShiftDetails> {
  Map shift = {};
  Map clientData = {};

  @override
  void initState() {
    super.initState();
    shift.clear();
    shift.addAll(widget.shift);
    _fetchClientData(clientID: shift['ClientID']);
    _fetchShiftData(shift['ShiftID']);
  }

  Future<void> _fetchClientData({required int clientID}) async {
    try {
      log('Fetching client data for ClientID: $clientID');
      final response = await Api.get('/getClientDataForVW/$clientID');

      if (response['data'] != null && response['data'].isNotEmpty) {
        log('Client data fetched successfully: ${response['data'][0]}');
        setState(() {
          clientData.clear();
          clientData.addAll(response['data'][0]);
        });
      } else {
        log('No data found for ClientID: $clientID');
      }
    } catch (e) {
      log('Error fetching client data: $e');
    }
  }

  String calculateShiftDuration(String shiftStart, String shiftEnd) {
    final start =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(shiftStart, true);
    var end = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(shiftEnd, true);

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    final duration = end.difference(start);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0
        ? '$hours hr ${minutes > 0 ? '$minutes min' : ''}'
        : '$minutes min';
  }

  Future<void> _fetchShiftData(shiftID) async {
    Api.get('getShiftMainData/$shiftID').then((response) {
      setState(() {
        shift.clear();
        shift.addAll(response['data'][0]);
      });
      log('Shift data fetched successfully: $shift');
    });
  }

  Future<void> _changeShiftStatus(String type, int shiftID,
      {String? reason}) async {
    String status;
    if (type == 'start') {
      status = 'In Progress';
    } else if (type == 'end') {
      final shiftEnd = DateTime.parse(shift['ShiftEnd']);
      final now = DateTime.now();
      final duration = now.difference(shiftEnd);

      if (now.isBefore(shiftEnd)) {
        status = 'Completed-Early';
        reason = 'Shift ended early by ${duration.inMinutes} minutes';
      } else {
        status = 'Completed-Late';
        reason = 'Shift ended late by ${duration.inMinutes} minutes';
      }
    } else {
      status = 'Cancelled';
    }

    log('STATUS: $status');
    try {
      final response = await Api.put('changeShiftStatus', {
        'ShiftID': shiftID,
        'ShiftStatus': status,
        if (reason != null) 'ShiftStatusReason': reason,
      });

      if (response['success']) {
        log('Shift status changed to $status');
        // Fetch updated shift data
        await _fetchShiftData(shiftID);
        setState(() {
          shift['ShiftStatus'] = status;
        });
        widget.onStatusChanged(status); // Notify ShiftRoot or parent widget
      } else {
        log('Error changing shift status');
      }
    } catch (e) {
      log('Error changing shift status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "${shift['ClientFirstName']} ${shift['ClientLastName']} - ${clientData['PreferredName'] ?? ''}",
                          style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '- (idk)',
                              style: TextStyle(
                                  color: colorScheme.onPrimaryContainer),
                            ),
                            const SizedBox(width: 50),
                            Text(
                              'Age: ${clientData['Age']}',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onPrimaryContainer),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    '${shift['ClientFirstName'][0]}${shift['ClientLastName'][0]}',
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      color:
                          shift['ShiftStatus'].toString().contains('Completed')
                              ? Colors.lightGreen
                              : shift['ShiftStatus'] == 'Cancelled'
                                  ? Colors.red
                                  : shift['ShiftStatus'] == 'In Progress'
                                      ? Colors.amber
                                      : colorScheme.secondaryContainer,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${shift['ShiftStatus']}',
                          style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (shift['ShiftStatus'] == 'Not Started')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 10),
                    child: SlideAction(
                      sliderButtonIcon: Icon(
                        Icons.arrow_forward,
                        color: colorScheme.onPrimary,
                        size: 30,
                      ),
                      borderRadius: 15,
                      innerColor: colorScheme.primary,
                      outerColor: colorScheme.secondaryContainer,
                      textColor: colorScheme.onPrimary,
                      animationDuration: const Duration(milliseconds: 500),
                      submittedIcon: const Icon(
                        Icons.check,
                        color: Colors.lightGreen,
                        size: 30,
                      ),
                      text: 'Slide to Start Shift',
                      textStyle: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      onSubmit: () async {
                        await _changeShiftStatus('start', shift['ShiftID']);
                      },
                    ),
                  ),
                if (shift['ShiftStatus'] == 'In Progress')
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () async {
                        showEndShiftDialog(context, shift, colorScheme);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.done_outline_rounded),
                          SizedBox(width: 10),
                          Text('End Shift'),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Card(
                  color: colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Shift Date: ',
                              style: TextStyle(
                                  color: colorScheme.onSurface, fontSize: 16),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(DateTime.parse(shift['ShiftStart'])),
                              style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Start Time: ',
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16),
                                ),
                                Text(
                                  DateFormat('hh:mm aa').format(
                                      DateTime.parse(shift['ShiftStart'])
                                          .toUtc()),
                                  style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'End Time: ',
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16),
                                ),
                                Text(
                                  DateFormat('hh:mm aa').format(
                                      DateTime.parse(shift['ShiftEnd'])
                                          .toUtc()),
                                  style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Duration',
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16),
                                ),
                                Text(
                                  calculateShiftDuration(
                                      shift['ShiftStart'], shift['ShiftEnd']),
                                  style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShiftDetails3rdCard(
                          title: 'Case Manager: ',
                          subtitle: clientData['CaseManager'] ?? '-',
                        ),
                        ShiftDetails3rdCard(
                          title: 'Tasks Required: ',
                          subtitle: shift['ServiceDescription'] ?? '-',
                        ),
                        ShiftDetails3rdCard(
                          title: 'Location: ',
                          subtitle:
                              '${clientData['AddressLine1'] ?? ''} ${clientData['AddressLine2'] ?? ''} ${clientData['Suburb'] ?? ''} ${clientData['Postcode'] ?? ''}',
                        ),
                        ShiftDetails3rdCard(
                          title: 'DOB: ',
                          subtitle: clientData['DOB'] ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showEndShiftDialog(
      BuildContext context, Map<dynamic, dynamic> shiftData, colorScheme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('End Shift', style: TextStyle(color: colorScheme.error)),
          content: Text('Are you sure you want to end this shift?',
              style: TextStyle(color: colorScheme.primary)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _changeShiftStatus('end', shiftData['ShiftID']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
              ),
              child: Text('End Shift',
                  style: TextStyle(color: colorScheme.onErrorContainer)),
            ),
          ],
        );
      },
    );
  }
}
