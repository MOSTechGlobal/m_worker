import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:alarm/alarm.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/components/button.dart';
import 'package:m_worker/components/shift_detail/shift_extension/extend_request.dart';
import 'package:m_worker/utils/api.dart';
import 'package:m_worker/utils/prefs.dart';
import 'package:s3_storage/s3_storage.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../../../bloc/theme_bloc.dart';
import '../../../components/shift_detail/shift_detail_3rd_card.dart';
import '../../../main.dart';

class ShiftDetails extends StatefulWidget {
  final Map<dynamic, dynamic> shift;
  final ValueChanged<String> onStatusChanged;

  const ShiftDetails(
      {super.key, required this.shift, required this.onStatusChanged});

  @override
  State<ShiftDetails> createState() => _ShiftDetailsState();

  // void fetchExtensionRequestStatus(int extensionId) {
  //   _ShiftDetailsState()._fetchExtensionRequestStatus();
  // }
}

class _ShiftDetailsState extends State<ShiftDetails>
    with TickerProviderStateMixin {
  Map shift = {};
  Map clientData = {};
  Map workerData = {};
  bool isBreakActive = false;
  Duration breakDuration = Duration.zero;
  DateTime? breakEndTime;
  DateTime? breakStartTime;
  bool showEndShiftBtn = true;
  int totalBreakDuration = 0;
  StreamSubscription? _alarmSubscription;
  Timer? _alarmStopTimer;

  String? _pfp;

  bool showExtensionBtn = false;
  Map extensionData = {};

  Timer? _timer;
  Timer? _extensionTimer;

  double totalDistanceKm = 0.0;

  XFile? image0;
  late String doc = '';

  final player = AudioPlayer();

  Position? _startPosition;
  Position? _endPosition;
  double _totalDistance = 0.0;
  bool _isTracking = false;

  Future<void> _fetchIsOnBreak() async {
    final response =
        await Api.get('getShiftActiveBreakByShiftID/${shift['ShiftID']}');
    if (response['data'] != null && response['data'].isNotEmpty) {
      final activeBreak = response['data'][0];
      final onBreak = activeBreak['OnBreak'];
      if (onBreak == 1) {
        setState(() {
          isBreakActive = true;
          breakEndTime = DateTime.parse(activeBreak['BreakStartTime'])
              .toLocal()
              .add(Duration(minutes: breakDuration.inMinutes));
        });
      }
    } else {
      setState(() {
        isBreakActive = false;
        breakStartTime = null;
        breakEndTime = null;
      });
    }
  }

  Future<void> startBreak(colorScheme) async {
    final response =
        await Api.get('getTotalBreakTimeByShiftID/${shift['ShiftID']}');
    if (response['data'] != null && response['data'].isNotEmpty) {
      final activeBreak = response['data'][0];
      setState(() {
        totalBreakDuration = activeBreak['TotalBreakTime'] ?? 0;
      });
    }

    final remainingBreakTime =
        breakDuration - Duration(minutes: totalBreakDuration);

    if (remainingBreakTime <= Duration.zero) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('No Break Time Left',
                style: TextStyle(color: colorScheme.error)),
            content: Text('You have used all your break time.',
                style: TextStyle(color: colorScheme.primary)),
            actions: [
              ElevatedButton(
                onPressed: () {
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
      return;
    }

    setState(() {
      isBreakActive = true;
      breakStartTime = DateTime.now();
      breakEndTime = DateTime.now().add(remainingBreakTime);
    });

    await Api.post('insertShiftBreak', {
      'ShiftID': shift['ShiftID'],
      'BreakStartTime': breakStartTime?.toLocal().toString(),
      'OnBreak': 1,
    });

    setAlarm(breakEndTime!);
  }

  Future<void> endBreak() async {
    DateTime currentBreakEndTime = DateTime.now();

    final response =
        await Api.get('getShiftActiveBreakByShiftID/${shift['ShiftID']}');
    if (response['data'] != null && response['data'].isNotEmpty) {
      final activeBreak = response['data'][0];
      final breakID = activeBreak['ID'];

      await Api.put('updateShiftBreak', {
        'ID': breakID,
        'BreakEndTime': currentBreakEndTime.toLocal().toString(),
        'ShiftID': shift['ShiftID'],
      });
    }

    setState(() {
      isBreakActive = false;
      breakStartTime = null;
      breakEndTime = null;
    });

    await Alarm.stop(42);
    player.stop();
    _alarmSubscription?.cancel();
    _alarmStopTimer?.cancel();
  }

  // Function to get current location
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, return an error.
      return Future.error('Location services are disabled.');
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, return an error.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, return an error.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // If permissions are granted, return current position
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Function to start tracking
  void _startTracking() async {
    setState(() {
      _isTracking = true;
      _totalDistance = 0.0;
    });

    _startPosition = await _determinePosition();
  }

  // Function to stop tracking
  Future<void> _stopTracking() async {
    if (!mounted) return;

    setState(() {
      _isTracking = false;
    });

    _endPosition = await _determinePosition();

    if (_startPosition != null && _endPosition != null) {
      _totalDistance = Geolocator.distanceBetween(
        _startPosition!.latitude,
        _startPosition!.longitude,
        _endPosition!.latitude,
        _endPosition!.longitude,
      );

      if (mounted) {
        setState(() {
          totalDistanceKm = _totalDistance / 1000;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (mounted) {
      shift.clear();
      shift.addAll(widget.shift);
      log('ShiftID ');
      // Check if 'ShiftID' exists and is an int
      if (shift['ShiftID'] == null || shift['ShiftID'] is! int) {
        log('ShiftID is null or not an int');
        // Handle the error appropriately, e.g., show an error message or navigate back
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Error', style: TextStyle(color: Colors.red)),
                content: const Text('Invalid Shift Data.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Navigate back
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        });
        return;
      }

      _fetchClientData(clientID: shift['ClientID']);
      _fetchWorkerData();
      _fetchShiftData(shift['ShiftID']);
      _initAlarm();
      _checkExtensionBtn();
      _fetchExtensionRequestStatus();
      _fetchIsOnBreak();
      player.setReleaseMode(ReleaseMode.stop);
    }
  }

  void _initAlarm() async {
    final alreadySubscribed = await Prefs.getAlarmSubscribed();
    // Cancel the existing subscription if any, to avoid multiple subscriptions
    _alarmSubscription?.cancel();

    if (!alreadySubscribed) {
      // Create a new subscription after canceling any existing ones
      _alarmSubscription = Alarm.ringStream.stream.listen((event) {
        if (event.id == 42) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showBreakEndDialog(context, Theme.of(context).colorScheme);
          });
        }
      });
      Prefs.setAlarmSubscribed(true);
    }
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    _timer?.cancel();
    _extensionTimer?.cancel();
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

  void setAlarm(DateTime dateTime) {
    final alarmSettings = AlarmSettings(
      id: 42,
      dateTime: dateTime,
      assetAudioPath: 'assets/audio/alarm.wav',
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      enableNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
      notificationTitle: 'Break Ended',
      notificationBody: 'Your break has ended.',
    );
    Alarm.isRinging(42).then((value) {
      if (value == true) {
        _showStopAlarmNotification('Stop Alarm', 'Your break has ended.');
      }
    });

    Alarm.set(alarmSettings: alarmSettings);
    _scheduleAlarmStop();
  }

  void _scheduleAlarmStop() {
    _alarmStopTimer = Timer(const Duration(minutes: 5), () {
      player.stop();
      Alarm.stop(42);
    });
  }

  // Function to show a notification when the alarm is about to stop
  Future<void> _showStopAlarmNotification(String? title, String? body) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'm-w-bg', // Replace with your channel ID
      'Mostech Notifs', // Replace with your channel name
      channelDescription:
          'General Channel to get Notifs', // Replace with your channel description
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      showWhen: false,
      // Define actions
      additionalFlags:
          Int32List.fromList([1]), // Necessary for Android 8.0 and above
      styleInformation: const DefaultStyleInformation(true, true),
      // Set up notification actions
      actions: [
        const AndroidNotificationAction(
          'stop_alarm', // Action ID
          'Stop', // Action Label
        ),
      ],
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );

    // Handle the actions when the notification is tapped
    _setupNotificationActionHandlers();
  }

// Set up handlers for the notification actions
  void _setupNotificationActionHandlers() {
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload == 'stop_alarm') {
          log('Alarm stopped');
          endBreak();
        }
      },
    );
  }

  Future<void> showBreakEndDialog(
      BuildContext context, ColorScheme colorScheme) async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title:
                Text('Break Ended', style: TextStyle(color: colorScheme.error)),
            content: Text('Your break has ended.',
                style: TextStyle(color: colorScheme.primary)),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // End the break and close the dialog
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
    if (shift['ShiftStatus'] == 'In Progress') {
      final shiftEnd = DateTime.parse(shift['ShiftEnd']);
      final now = DateTime.now();

      if (now.isAfter(shiftEnd.subtract(const Duration(minutes: 15))) && !showExtensionBtn) {
        if (mounted) {
          setState(() {
            showExtensionBtn = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            showExtensionBtn = false;
          });
        }
      }
    }

    _timer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      final shiftEnd = DateTime.parse(shift['ShiftEnd']);
      final now = DateTime.now();

      if (now.isAfter(shiftEnd) && showExtensionBtn) {
        if (mounted) {
          setState(() {
            showExtensionBtn = false;
          });
        }
        timer.cancel();

        if (extensionData.isEmpty) {
          await _changeShiftStatus('Completed', shift['ShiftID'],
              reason: 'Shift ended late by ${now.difference(shiftEnd).inMinutes} minutes');
        }
      } else if (now.isAfter(shiftEnd.subtract(const Duration(minutes: 15))) && !showExtensionBtn) {
        if (mounted) {
          setState(() {
            showExtensionBtn = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            showExtensionBtn = false;
          });
        }
      }

      final extensionRequestExists = await _checkExtensionRequestExists();
      if (extensionRequestExists) {
        if (mounted) {
          setState(() {
            showExtensionBtn = false;
          });
        }
        timer.cancel();
      }
    });
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
      final workerID = await Prefs.getWorkerID();

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

  Future<void> _fetchShiftData(int shiftID) async {
    Api.get('getApprovedShifts/$shiftID').then((response) {
      if (response['data'] != null && response['data'].isNotEmpty) {
        setState(() {
          shift.addAll(response['data'][0]);
        });
        _getPfp(shift['ClientProfilePhoto']);
        setState(() {
          breakDuration = shift['BreakDuration'] != null
              ? Duration(minutes: shift['BreakDuration'])
              : Duration.zero;
        });
      } else {
        log('No data found for ShiftID: $shiftID');
        // Optionally, handle this case by showing an error or navigating back
      }
    }).catchError((error) {
      log('Error fetching shift data: $error');
      // Optionally, handle the error by showing a dialog or navigating back
    });
  }


  void _getPfp(profilePhoto) async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final url = await s3Storage.presignedGetObject(
        profilePhoto.toString().split('/').first,
        profilePhoto.toString().split('/').sublist(1).join('/'),
      );

      log('URL: $url');

      setState(() {
        _pfp = url;
      });
    } catch (e) {
      log('Error getting profile picture: $e');
    }
  }

  Future<void> _makeTimeSheetEntry(shift) async {
    final workerID = await Prefs.getWorkerID();

    final data = {
      'ShiftId': shift['ShiftID'],
      'ServiceCode': shift['ServiceCode'],
      'ClientId': shift['ClientID'],
      'TlId': clientData['CaseManager'],
      'TlRemarks':
          workerID == clientData['CaseManager'] ? 'Worker is TL' : null,
      'TlStatus': workerID == clientData['CaseManager'] ? 'A' : 'U',
      'RmId': clientData['CaseManager2'],
      'RmRemarks': null,
      'RmStatus': 'U',
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

    _startTracking();
  }

  Future<void> _fetchExtensionRequestStatus() async {
    try {
      String shiftIdUrl = 'getShiftExtensionDetailDataByShiftId/${shift['ShiftID']}';
      log('Fetching extension data for ShiftID: ${shift['ShiftID']}');
      final response = await Api.get(shiftIdUrl);

      if (response != null && response['data'] != null && response['data'].isNotEmpty) {
        if (mounted) {
          setState(() {
            showExtensionBtn = false;
            extensionData.clear();
            extensionData.addAll(response['data'][0]);
          });
          if (extensionData['Status'] == 'A') {
            if (_extensionTimer?.isActive ?? false) {
              _extensionTimer?.cancel(); // Stop polling when status is 'A'
            }
            _playSuccessSound(); // Play sound after stopping the timer
          }
        }
      } else {
        log('No extension data found for ShiftID: ${shift['ShiftID']}');
        if (mounted) {
          setState(() {
            showExtensionBtn = false;
          });
        }
        if (_extensionTimer?.isActive ?? false) {
          _extensionTimer?.cancel(); // Stop polling if no data is found
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
                        child: _pfp != null
                            ? ClipOval(
                                child: Image.network(
                                  _pfp!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
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
                // if (shift['ShiftStatus'].toString().contains('Completed'))
                //   GestureDetector(
                //     onTap: () {
                //       Navigator.of(context).pushNamed('/end_shift',
                //           arguments: {'shift': shift, 'worker': workerData});
                //     },
                //     child: Card(
                //       color: colorScheme.tertiaryContainer,
                //       child: Padding(
                //         padding: const EdgeInsets.all(10.0),
                //         child: Text(
                //           'See Shift End Fields',
                //           style: TextStyle(
                //               color: colorScheme.onTertiaryContainer,
                //               fontSize: 16),
                //         ),
                //       ),
                //     ),
                //   ),
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showExtensionBtn) const SizedBox(width: 60),
                    if (shift['ShiftStatus'] == 'In Progress')
                      showEndShiftBtn
                          ? Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: SlideAction(
                                enabled: shift['ShiftStatus'] == 'In Progress',
                                sliderButtonIcon: Icon(
                                  Icons.arrow_forward,
                                  color: colorScheme.onPrimary,
                                  size: 30,
                                ),
                                borderRadius: 15,
                                innerColor: colorScheme.error,
                                outerColor: colorScheme.errorContainer,
                                textColor: colorScheme.onError,
                                animationDuration:
                                    const Duration(milliseconds: 500),
                                submittedIcon: const Icon(
                                  Icons.check,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                text: 'Slide to End Shift',
                                textStyle: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSubmit: () async {
                                  showEndShiftDialog(context, colorScheme);
                                  setState(() {
                                    showEndShiftBtn = false;
                                  });
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    if (shift['ShiftStatus'] == 'In Progress' &&
                        !showExtensionBtn) ...[
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
                                        : extensionData['Status'] == 'R'
                                            ? 'Rejected'
                                            : 'Pending',
                                    style: TextStyle(
                                        color: extensionData['Status'] == 'A'
                                            ? Colors.lightGreen
                                            : extensionData['Status'] == 'R'
                                                ? Colors.red
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
                const SizedBox(height: 10),
                if (shift['ShiftStatus'] == 'In Progress' &&
                    Duration(minutes: shift['BreakDuration'] ?? 0) >
                        Duration.zero &&
                    !isBreakActive &&
                    (breakEndTime == null ||
                        breakEndTime!.isBefore(DateTime.now())) &&
                    !DateTime.now().isAfter(DateTime.parse(shift['ShiftEnd'])))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    child: MButton(
                      label: 'Start Break',
                      colorScheme: colorScheme,
                      onPressed: () {
                        startBreak(colorScheme);
                      },
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
                          Text(
                            'You have ${breakDuration.inMinutes - totalBreakDuration} minutes left',
                            style: TextStyle(
                                color: colorScheme.onSurface, fontSize: 12),
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
                                  'Start Time',
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 14),
                                ),
                                Text(
                                  DateFormat('hh:mm aa').format(
                                      DateTime.parse(shift['ShiftStart'])
                                          .toUtc()
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
                                          .toUtc()
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
          title: Text('End Shift (og_)', style: TextStyle(color: colorScheme.error)),
          content: Text('Are you sure you want to end this shift?',
              style: TextStyle(color: colorScheme.primary)),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    showEndShiftBtn = false;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                log('Ending shift...');
                _stopTracking();
                final args = {
                  'shift': shift,
                  'worker': workerData,
                  'KM': totalDistanceKm,
                };
                Navigator.of(context).pop();
                if (mounted) {
                  Navigator.of(context)
                      .pushNamed('/end_shift', arguments: args);
                }
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
            _extensionTimer =
                Timer.periodic(const Duration(seconds: 10), (timer) {
              _fetchExtensionRequestStatus();
            });
          },
        );
      },
    );
  }
}
