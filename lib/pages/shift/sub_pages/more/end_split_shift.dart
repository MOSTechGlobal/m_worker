import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/components/button.dart';
import 'package:m_worker/components/mFilledTextField.dart';
import 'package:s3_storage/s3_storage.dart';

import '../../../../utils/api.dart';
import '../../../../utils/prefs.dart';

class EndSplitShift extends StatefulWidget {
  const EndSplitShift({super.key});

  @override
  State<EndSplitShift> createState() => _EndSplitShiftState();
}

class _EndSplitShiftState extends State<EndSplitShift> {
  late Map<dynamic, dynamic> shift = {};
  late Map splitShift = {};
  late int workerID = 0;
  bool isShiftExtened = false;
  bool isLoading = false;
  int? _selectedSegment;
  XFile? image0;
  String doc = '';
  double _progressState = 0.0;

  ScaffoldMessengerState? _scaffoldMessengerState;

  String actualKm = '0.0';

  final List<TextEditingController> _kmNoteControllers = [];
  final List<TextEditingController> _travelNoteControllers = [];
  final List<TextEditingController> _timeSheetRemarksControllers = [];
  final TextEditingController _extendedMinutesController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isKmNoteValid = true;
  bool _isExtendedMinutesValid = true;
  bool _isTravelNoteValid = true;
  bool _isTimeSheetRemarksValid = true;
  bool _isNoteValid = true;

  @override
  void initState() {
    setState(() {
      isLoading = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      _checkShiftExtension();
    });
    setState(() {
      isLoading = false;
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      isLoading = true;
    });
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>;
    setState(() {
      shift = args['shift'];
      workerID = args['worker']['WorkerID'];
      actualKm = args['KM'].toStringAsFixed(2);
      splitShift = args['splitShift'];
    });
    // Initialize controllers for each split shift
    for (int i = 1; i <= 4; i++) {
      if (splitShift.containsKey('s${i}_service_code') &&
          splitShift['s${i}_service_code'] != '' &&
          splitShift['s${i}_service_code'] != null) {
        _kmNoteControllers.add(TextEditingController());
        _travelNoteControllers.add(TextEditingController());
        _timeSheetRemarksControllers.add(TextEditingController());
      }
    }
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkShiftExtension() async {
    log('Checking if shift has an extension request');
    setState(() {
      isLoading = true;
    });

    try {
      int shiftID = shift['ShiftID'];
      final response = await Api.get('checkIfExtensionRequestExists/$shiftID');
      log('Response: $response');
      if (response['success'] == true && response['data'] == true) {
        setState(() {
          isShiftExtened = true;
        });
        log('Shift has an extension request');
      } else {
        setState(() {
          isShiftExtened = false;
        });
      }
    } catch (e) {
      log('Error fetching extension data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // todo if the worker is defaulter then the shift needs to be on and it goes to senior management for not clocking out on time unless the admin extends the shift
  // todo automatically end the shift if the worker is a defaulter

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        image0 = image;
        doc = '';
      });
    }
  }

  Future<void> _uploadDoc() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        doc = result.files.first.path!;
        image0 = null;
      });
    }
  }

  Future<void> _endExtension() async {
    log('Ending extension');
    setState(() {
      isLoading = true;
    });
    final location = await Geolocator.getCurrentPosition();
    final endLoc = '(${location.latitude}, ${location.longitude})';

    try {
      final company = await Prefs.getCompanyName();
      final workerID = await Prefs.getWorkerID();
      String objectLocation = '';

      setState(() {
        objectLocation =
            '$company/worker/$workerID/shift_extension/sid_${shift['ShiftID']}/end_${image0?.path.split('/').last ?? doc.split('/').last}';
      });

      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      if (image0 != null) {
        await s3Storage.putObject(
          'moscaresolutions',
          objectLocation,
          Stream<Uint8List>.value(
              Uint8List.fromList(File(image0!.path).readAsBytesSync())),
          onProgress: (progress) {
            setState(() {
              if (image0 != null) {
                _progressState =
                    progress.toDouble() / File(image0!.path).lengthSync();
              }
              if (doc.isNotEmpty) {
                _progressState = progress.toDouble() / File(doc).lengthSync();
              }
            });
          },
        );
      } else if (doc.isNotEmpty) {
        await s3Storage.putObject(
          'moscaresolutions',
          objectLocation,
          Stream<Uint8List>.value(
              Uint8List.fromList(File(doc).readAsBytesSync())),
          onProgress: (progress) {
            setState(() {
              _progressState = progress.toDouble() / File(doc).lengthSync();
            });
          },
        );
      }

      // store in db
      if (image0 != null || doc.isNotEmpty) {
        final data = {
          'ShiftId': shift['ShiftID'],
          'EndTime': DateTime.now().toIso8601String(),
          "Minutes": _extendedMinutesController.text,
          'EndLoc': endLoc,
          'EndAttachment': objectLocation,
        };

        try {
          await Api.post('updateExtensionEndTime', data);
        } catch (e) {
          log('Error ending extension: $e');
        }
      }
    } catch (e) {
      log('Error ending extension: $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _changeShiftStatus(String type, int shiftID,
      {String? reason}) async {
    log('Changing shift status to $type');
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
        setState(() {
          shift['ShiftStatus'] = status;
        });
      } else {
        log('Error changing shift status');
      }
    } catch (e) {
      log('Error changing shift status: $e');
    }
  }

  Future<void> _timesheetDetails() async {
    log('Updating timesheet details');
    // todo: endsplit
    final email = await Prefs.getEmail();
    for (int i = 0; i < _kmNoteControllers.length; i++) {
      final data = {
        'ShiftId': splitShift['shift_id'],
        // 'ShiftStartDate': shift['ShiftStart'],
        'ShiftStartDate': splitShift['s${i + 1}_start_time'],
        'Km': _kmNoteControllers[i].text,
        'TravelNote': _travelNoteControllers[i].text,
        'WorkerRemarks': _timeSheetRemarksControllers[i].text,
        'ActualKm': actualKm,
        'UpdateTime': DateTime.now().toString(),
        'UpdateBy': email,
        'ExtendedMinutes': _extendedMinutesController.text,
      };

      try {
        log("end data: $data");
        await Api.post('endSplitShiftInsertTimesheetDetails', data);
      } catch (e) {
        log('Error updating timesheet details: $e');
        return;
      }
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Shift Ended',
              style: TextStyle(
                  fontSize: 18, color: Theme.of(context).colorScheme.primary)),
          content: Text('Shift has been ended successfully',
              style: TextStyle(
                  fontSize: 16, color: Theme.of(context).colorScheme.primary)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                    Theme.of(context).colorScheme.primaryContainer),
              ),
              child: Text('OK',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  Future _saveNote() async {
    log('Saving note');
    final email = await Prefs.getEmail();
    if (_noteController.text.isNotEmpty) {
      // TODO: redesign the existing table structure
      // TODO: fix the data to be sent and the endpoint to be called after confirming and fixing the backend
      final data = {
        'Note': _noteController.text,
        'NoteType': 'TIMESHEET NOTE',
        // TODO: Confirm note category to get from maintenance
        'CreatedBy': email,
        'VisibleWorkerApp': 1,
        // 'VisibleClientApp': 1,
        // ServiceCode: 'string',
        // ServiceDate: 'string', // Shift Date
      };

      await Api.post('insertClientNotesData/${shift['ClientID']}', data);
    } else {
      if (_scaffoldMessengerState != null) {
        _scaffoldMessengerState!.showSnackBar(
          const SnackBar(
              content: Text('Note cannot be empty',
                  style: TextStyle(fontSize: 16, color: Colors.white))),
        );
      }
    }
  }

  bool _validateFields() {
    bool isValid = true;

    if (isShiftExtened && _extendedMinutesController.text.isEmpty) {
      setState(() {
        _isExtendedMinutesValid = false;
      });
      isValid = false;
    } else {
      setState(() {
        _isExtendedMinutesValid = true;
      });
      isValid = true;
    }

    if (_noteController.text.isEmpty) {
      setState(() {
        _isNoteValid = false;
      });
      isValid = false;
    } else {
      setState(() {
        _isNoteValid = true;
      });
      isValid = true;
    }

    return isValid;
  }

  Future<void> _endShift() async {
    if (!_validateFields()) {
      return;
    }

    await Prefs.clearAlarmSubscribed();

    try {
      if (!isShiftExtened) {
        _endExtension();


      }_timesheetDetails();

      _saveNote();
      _changeShiftStatus('end', shift['ShiftID']);
    } catch (e) {
      log('Error ending shift: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('End Shift'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '#${shift['ShiftID']}',
                  style: TextStyle(
                    color: colorScheme.tertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          body: isLoading
              ? const Center(
                  child: SizedBox(width: 100, child: LinearProgressIndicator()),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        if (isShiftExtened) ...[
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color:
                                  colorScheme.primaryContainer.withOpacity(0.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'You have an extension request for this shift.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Enter the extended time in minutes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                MFilledtextfield(
                                  hintText: 'minutes',
                                  colorScheme: colorScheme,
                                  isValid: _isExtendedMinutesValid,
                                  controller: _extendedMinutesController,
                                  onChanged: (value) {
                                    _extendedMinutesController.text = value;
                                  },
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Send Extension End Attachments ?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                Row(
                                  children: [
                                    SegmentedButton<int>(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                                colorScheme.secondaryContainer),
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      segments: [
                                        ButtonSegment(
                                          value: 0,
                                          icon: Icon(
                                            Icons.file_upload,
                                            color: colorScheme
                                                .onSecondaryContainer,
                                          ),
                                          label: Text(
                                            'Upload File',
                                            style: TextStyle(
                                                color: colorScheme
                                                    .onSecondaryContainer,
                                                fontSize: 14),
                                          ),
                                        ),
                                        ButtonSegment(
                                          value: 1,
                                          icon: Icon(
                                            Icons.camera_alt,
                                            color: colorScheme
                                                .onSecondaryContainer,
                                          ),
                                          label: Text(
                                            'Take Photo',
                                            style: TextStyle(
                                                color: colorScheme
                                                    .onSecondaryContainer,
                                                fontSize: 14),
                                          ),
                                        ),
                                      ],
                                      emptySelectionAllowed: true,
                                      selected: _selectedSegment != null
                                          ? {_selectedSegment!}
                                          : <int>{},
                                      showSelectedIcon: false,
                                      onSelectionChanged: (Set<int> selected) {
                                        setState(() {
                                          _selectedSegment = selected.isNotEmpty
                                              ? selected.first
                                              : null;
                                        });
                                        _handleSegmentSelection(
                                            _selectedSegment);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      size: 18,
                                      image0 != null
                                          ? Icons.image
                                          : doc.isNotEmpty
                                              ? Icons.file_copy
                                              : null,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      size: 18,
                                      image0 != null || doc.isNotEmpty
                                          ? Icons.check
                                          : null,
                                      color: colorScheme.error,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                _progressState > 0
                                    ? LinearProgressIndicator(
                                        value: _progressState,
                                        backgroundColor: colorScheme.primary,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                colorScheme.secondary),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 10),
                        ] else
                          const SizedBox.shrink(),
                        for (int i = 0; i < _kmNoteControllers.length; i++) ...[
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color:
                                colorScheme.primaryContainer.withOpacity(0.3),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Service Code: ${splitShift['s${i + 1}_service_code']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.tertiary,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'KM travelled during the shift',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  MFilledtextfield(
                                    hintText: 'KM',
                                    colorScheme: colorScheme,
                                    controller: _kmNoteControllers[i],
                                    onChanged: (value) {
                                      _kmNoteControllers[i].text = value;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Travel Note',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  MFilledtextfield(
                                    multiLine: true,
                                    hintText: 'note',
                                    colorScheme: colorScheme,
                                    controller: _travelNoteControllers[i],
                                    onChanged: (value) {
                                      _travelNoteControllers[i].text = value;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'TimeSheet Remarks',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  MFilledtextfield(
                                    multiLine: true,
                                    hintText: 'Remarks',
                                    colorScheme: colorScheme,
                                    controller: _timeSheetRemarksControllers[i],
                                    onChanged: (value) {
                                      _timeSheetRemarksControllers[i].text =
                                          value;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          'Note',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        MFilledtextfield(
                          multiLine: true,
                          hintText: 'Notes about the shift (required)',
                          colorScheme: colorScheme,
                          controller: _noteController,
                          isValid: _isNoteValid,
                          onChanged: (value) {
                            _noteController.text = value;
                          },
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: MButton(
                            onPressed: () {
                              _endShift();
                            },
                            colorScheme: colorScheme,
                            label: 'End Shift',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _handleSegmentSelection(int? index) {
    if (index == null) {
      log('No selection');
      return;
    }

    if (index == 0) {
      // Handle image upload
      _uploadDoc();
    } else if (index == 1) {
      // Handle taking a photo
      _takePhoto();
    }

    setState(() {
      _selectedSegment = null;
    });
  }
}
