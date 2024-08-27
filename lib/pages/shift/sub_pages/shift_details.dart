import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/components/shift_detail/shift_extension/extend_request.dart';
import 'package:m_worker/utils/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  void fetchExtensionRequestStatus(int extensionId) {
    _ShiftDetailsState()._fetchExtensionRequestStatus();
  }
}

class _ShiftDetailsState extends State<ShiftDetails> {
  Map shift = {};
  Map clientData = {};
  Map workerData = {};
  bool isBreakActive = false;
  Duration breakDuration = Duration.zero;
  DateTime? breakEndTime;
  late StreamSubscription _alarmSubscription;

  bool showExtensionBtn = false;
  Map extensionData = {};

  late Timer _timer;
  late Timer _extenstionTimer;

  XFile? image0;
  late String doc = '';

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    log('Shift Details: ${widget.shift}');
    shift.clear();
    shift.addAll(widget.shift);
    _fetchClientData(clientID: shift['ClientID']);
    _fetchWorkerData();
    _fetchShiftData(shift['ShiftID']);
    _initAlarm();
    _checkExtensionBtn();
    _fetchExtensionRequestStatus();
    player.setReleaseMode(ReleaseMode.stop);
  }

  void _initAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySubscribed = prefs.getBool('alarmSubscribed') ?? false;
    if (!alreadySubscribed) {
      _alarmSubscription = Alarm.ringStream.stream.listen((event) {
        if (event.id == 42) {
          showBreakEndDialog(context, Theme.of(context).colorScheme);
        }
      });
      prefs.setBool('alarmSubscribed', true);
    }
  }

  Future<bool> _checkExtensionRequestExists() async {
    final response = await Api.get('getShiftExtensionDetailDataByShiftId', {
      'ShiftID': shift['ShiftID'],
    });
    if (response['data'] != null && response['data']) {
      return true;
    } else {
      return false;
    }
  }

  void _checkExtensionBtn() {
    _timer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      final shiftEnd = DateTime.parse(shift['ShiftEnd']);
      final now = DateTime.now();
      final duration = now.difference(shiftEnd);

      if (now.isAfter(shiftEnd) && showExtensionBtn) {
        setState(() {
          showExtensionBtn = false;
        });
        timer.cancel();

        // End shift if no extension request is made
        if (extensionData.isEmpty) {
          await _changeShiftStatus('Completed', shift['ShiftID'],
              reason: 'Shift ended late by ${duration.inMinutes} minutes');
        }
      } else if (now.isAfter(shiftEnd.subtract(const Duration(minutes: 15))) &&
          !showExtensionBtn) {
        setState(() {
          showExtensionBtn = true;
        });
      } else {
        setState(() {
          showExtensionBtn = false;
        });
      }

      final extensionRequestExists = await _checkExtensionRequestExists();
      if (extensionRequestExists) {
        setState(() {
          showExtensionBtn = false;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _alarmSubscription.cancel();
    _timer.cancel();
    _extenstionTimer.cancel();
    player.dispose();
    super.dispose();
  }

  void _playSuccessSound() {
    try {
      player.play(AssetSource('audio/approve.mp3'));
    } catch (e) {
      log('Error playing sound: $e');
    } finally {
      player.stop();
    }
  }

  Future<void> startBreak(colorScheme) async {
    setState(() {
      isBreakActive = true;
      breakEndTime = DateTime.now().add(breakDuration);
    });

    await Api.put('putShiftBreak', {
      'ShiftID': shift['ShiftID'],
      'BreakStart': // time when break started
          DateFormat('HH:mm:ss').format(DateTime.now()),
      'onBreak': 1,
    });

    setAlarm(breakEndTime!);
  }

  Future<void> endBreak() async {
    setState(() {
      isBreakActive = false;
      breakDuration = Duration.zero;
      breakEndTime = null;
    });

    await Api.put('putShiftBreak', {
      'ShiftID': shift['ShiftID'],
      'onBreak': 0,
    });

    await Alarm.stop(42);
    _alarmSubscription.cancel();
  }

  void setAlarm(DateTime dateTime) {
    final alarmSettings = AlarmSettings(
      id: 42,
      dateTime: dateTime,
      assetAudioPath: 'assets/audio/alarm.wav',
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      notificationTitle: 'Break Ended',
      notificationBody: 'Your break has ended.',
      enableNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
    );

    Alarm.set(alarmSettings: alarmSettings);
  }

  void showBreakEndDialog(BuildContext context, colorScheme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text('Break Ended', style: TextStyle(color: colorScheme.error)),
          content: Text('Your break has ended.',
              style: TextStyle(color: colorScheme.primary)),
          actions: [
            ElevatedButton(
              onPressed: () {
                endBreak();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
              ),
              child: Text('OK',
                  style: TextStyle(color: colorScheme.onErrorContainer)),
            ),
          ],
        );
      },
    );
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

  Future<void> _fetchWorkerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workerID = prefs.getString('workerID').toString();

      log('Fetching worker data for WorkerID: $workerID');

      final response = await Api.get('getWorkerDataForVW/$workerID');

      if (response['data'] != null && response['data'].isNotEmpty) {
        log('Worker data fetched successfully: ${response['data'][0]}');
        setState(() {
          workerData.clear();
          workerData.addAll(response['data'][0]);
        });
      } else {
        log('No data found for WorkerID: $workerID');
      }
    } catch (e) {
      log('Error fetching worker data: $e');
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

  int calculateShiftDurationHours(String shiftStart, String shiftEnd) {
    final start =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(shiftStart, true);
    var end = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(shiftEnd, true);

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    final duration = end.difference(start);

    final hours = duration.inHours;
    return hours;
  }

  Future<void> _fetchShiftData(shiftID) async {
    Api.get('getApprovedShifts/$shiftID').then((response) {
      setState(() {
        shift.addAll(response['data'][0]);
      });
      setState(() {
        breakDuration = shift['BreakDuration'] != null
            ? Duration(minutes: shift['BreakDuration'])
            : Duration.zero;
        isBreakActive = shift['onBreak'] == 1;
        if (isBreakActive) {
          final breakStart = DateFormat('HH:mm:ss').parse(shift['BreakStart']);
          final breakEnd =
              breakStart.add(Duration(minutes: breakDuration.inMinutes));
          breakEndTime = breakEnd;
        }
      });
      log('$breakDuration');
      log('Break active: $isBreakActive');
      log('Break end time: $breakEndTime');
      log('Shift data fetched successfully: $shift');
    });
  }

  Future<void> _makeTimeSheetEntry(shift) async {
    final prefs = await SharedPreferences.getInstance();

    final workerID = prefs.getString('workerID').toString();

    final data = {
      'ShiftId': shift['ShiftID'],
      'ServiceCode': shift['ServiceCode'],
      'ClientId': shift['ClientID'],
      'TlId': clientData['CaseManager'],
      'TlRemarks':
          workerID == clientData['CaseManager'] ? 'Worker is TL' : null,
      'TlStatus': workerID == clientData['CaseManager'] ? 'A' : 'P',
      'RmId': clientData['CaseManager2'],
      'RmRemarks': null,
      'RmStatus': 'P',
      'WorkerRemarks': null,
      'ShiftStartDate':
          DateTime.parse(shift['ShiftStart']).toLocal().toString(),
      'ShiftEndDate': DateTime.parse(shift['ShiftEnd']).toLocal().toString(),
      'ActualStartTime': DateTime.now().toLocal().toString(),
      'PayRate': shift['PayRate'],
      'ChargeRate': shift['ChargeRate'],
      'RecStatus': 'O',
      'workerID': workerID,
    };

    try {
      await Api.post('/insertTimesheetDetailData', data);
    } catch (e) {
      log('TS Entry API Error: $e');
    }
  }

  Future<void> _changeShiftStatus(String type, int shiftID,
      {String? reason}) async {
    String status;
    if (type == 'start') {
      status = 'In Progress';
      await _makeTimeSheetEntry(shift);
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

  Future<void> _fetchExtensionRequestStatus() async {
    try {
      String shiftIdUrl =
          'getShiftExtensionDetailDataByShiftId/${shift['ShiftID'].toString()}';
      log('Fetching extension data for ShiftID: ${shift['ShiftID']}');
      final response = await Api.get(shiftIdUrl);

      if (response != null &&
          response['data'] != null &&
          response['data'].isNotEmpty) {
        if (mounted) {
          setState(() {
            extensionData.clear();
            extensionData.addAll(response['data'][0]);
          });
          if (extensionData['Status'] == 'A') {
            _extenstionTimer.cancel(); // Stop polling when status is 'A'
            // todo fix sound
            _playSuccessSound();
          }
        }
      } else {
        log('No extension data found for ShiftID: ${shift['ShiftID']}');
        if (mounted) {
          setState(() {
            _extenstionTimer.cancel();
          });
        }
        log('Extension status polling stopped');
      }
    } catch (e) {
      log('Error fetching extension data: $e');
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
                  elevation: 0,
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
                shift['ClientFirstName'] != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primary,
                        child: Text(
                          '${shift['ClientFirstName'][0] ?? ''}${shift['ClientLastName'][0] ?? ''}',
                          style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary),
                        ),
                      )
                    : const SizedBox.shrink(),
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
                                      ? Colors.amber.withOpacity(0.5)
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
                if ((shift['ShiftStatus'] == 'Not Started' ||
                        shift['ShiftStatus'] == 'Confirmed') &&
                    DateTime.now().day ==
                        DateTime.parse(shift['ShiftStart']).day)
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showExtensionBtn) const SizedBox(width: 60),
                    if (shift['ShiftStatus'] == 'In Progress' &&
                        !DateTime.now()
                            .isAfter(DateTime.parse(shift['ShiftEnd'])))
                      SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: () async {
                            showEndShiftDialog(context, colorScheme);
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
                    if (shift['ShiftStatus'] == 'In Progress' &&
                        showExtensionBtn) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () async {
                          showExtendRequestDialog(
                              context, shift, workerData, colorScheme);
                        },
                        icon: Icon(Icons.more_time,
                            color: colorScheme.error, size: 30),
                      ),
                    ],
                  ],
                ),
                //if extension data exists
                if (extensionData.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    color: colorScheme.tertiaryContainer.withOpacity(0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Extension Request',
                                style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            ' #${extensionData['Id']}',
                            style: TextStyle(
                                color: colorScheme.tertiary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    extensionData['Status'] == 'A'
                                        ? 'Approved'
                                        : 'Pending',
                                    style: TextStyle(
                                        color: extensionData['Status'] == 'A'
                                            ? Colors.lightGreen
                                            : Colors.amber,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: () {
                                  // todo call up the TL
                                  log('Extension request details: $extensionData');
                                },
                                icon: Icon(Icons.phone,
                                    color: colorScheme.onSurface, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (shift['ShiftStatus'] == 'In Progress' &&
                    Duration(minutes: shift['BreakDuration'] ?? 0) >
                        Duration.zero &&
                    !isBreakActive &&
                    (breakEndTime == null ||
                        breakEndTime!.isBefore(DateTime.now())))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    child: SlideAction(
                      onSubmit: () async {
                        await startBreak(colorScheme);
                      },
                      text: 'Start Break',
                      borderRadius: 12,
                      elevation: 0,
                      innerColor: colorScheme.onTertiaryContainer,
                      outerColor: colorScheme.tertiaryContainer,
                      textStyle: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      sliderButtonIconSize: 20,
                      height: 55,
                      sliderButtonIconPadding: 10,
                      sliderButtonIcon: Icon(
                        Icons.arrow_forward,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                if (isBreakActive)
                  Card(
                    color: colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            'Break Until: ${DateFormat('hh:mm aa').format(breakEndTime!)}',
                            style: TextStyle(
                                color: colorScheme.onSurface, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: endBreak,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.errorContainer,
                            ),
                            child: Text('End Break',
                                style: TextStyle(
                                    color: colorScheme.onErrorContainer)),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
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
                              DateFormat('dd/MM/yyyy').format(
                                  DateTime.parse(shift['ShiftStart'])
                                      .toLocal()),
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
                                  'Start Time',
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 14),
                                ),
                                Text(
                                  DateFormat('hh:mm aa').format(
                                      DateTime.parse(shift['ShiftStart'])
                                          .toLocal()),
                                  style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'End Time',
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 14),
                                ),
                                Text(
                                  DateFormat('hh:mm aa').format(
                                      DateTime.parse(shift['ShiftEnd'])
                                          .toLocal()),
                                  style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 16,
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
                                      fontSize: 14),
                                ),
                                Text(
                                  calculateShiftDuration(
                                      shift['ShiftStart'], shift['ShiftEnd']),
                                  style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Break',
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 14),
                                ),
                                Text(
                                  '${shift['BreakDuration'] ?? 0} min',
                                  style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 16,
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
                  elevation: 0,
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

  void showEndShiftDialog(BuildContext context, colorScheme) {
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
                final args = {
                  'shift': shift,
                  'worker': workerData,
                };
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/end_shift', arguments: args);
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

  void showExtendRequestDialog(BuildContext context, Map shiftData,
      Map workerData, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) {
        return ExtendRequestDialog(
          shiftData: shiftData,
          workerData: workerData,
          colorScheme: colorScheme,
          onExtensionRequested: (int insertId) {
            log('Extension requested with InsertID: $insertId');
            _extenstionTimer =
                Timer.periodic(const Duration(seconds: 10), (timer) {
              _fetchExtensionRequestStatus();
            });
          },
        );
      },
    );
  }
}
