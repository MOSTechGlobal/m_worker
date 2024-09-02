import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:m_worker/utils/api.dart';
import 'package:m_worker/utils/prefs.dart';
import 'package:s3_storage/s3_storage.dart';

class ExtendRequestDialog extends StatefulWidget {
  final Map<dynamic, dynamic> shiftData;
  final Map<dynamic, dynamic> workerData;
  final ColorScheme colorScheme;
  final void Function(int)? onExtensionRequested;

  const ExtendRequestDialog({
    super.key,
    required this.shiftData,
    required this.workerData,
    required this.colorScheme,
    this.onExtensionRequested,
  });

  @override
  _ExtendRequestDialogState createState() => _ExtendRequestDialogState();
}

class _ExtendRequestDialogState extends State<ExtendRequestDialog> {
  XFile? image0;
  String doc = '';
  double _progressState = 0.0;
  int? _selectedSegment;
  Map response = {};

  final TextEditingController _extensionReasonController =
      TextEditingController();

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

  Future<String> _getCurrentLocation() async {
    final location = await Geolocator.getCurrentPosition();
    return '(${location.latitude}, ${location.longitude})';
  }

  void _requestExtension() async {
    try {
      final email = await Prefs.getEmail();
      final company = await Prefs.getCompanyName();
      String objectLocation = '';

      setState(() {
        objectLocation =
            '$company/worker/${widget.workerData['WorkerID']}/shift_extension/sid_${widget.shiftData['ShiftID']}/start_${image0?.path.split('/').last ?? doc.split('/').last}';
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
          'ShiftId': widget.shiftData['ShiftID'],
          'RequestTime': DateTime.now().toLocal().toIso8601String(),
          'Remarks': _extensionReasonController.text,
          'StartGeoLoc': await _getCurrentLocation(),
          'StartAttachment':
              'https://moscaresolutions.s3.ap-southeast-2.amazonaws.com/$objectLocation',
          'Status': 'P',
          'EndGeoLoc': null,
          'EndAttachment': null,
          "WorkerId": widget.workerData['WorkerID'],
          'MakerUser': email,
          'MakerDate': DateTime.now().toLocal().toIso8601String(),
        };

        final result = await Api.post('insertShiftExtensionDetailData', data);
        setState(() {
          response = result;
        });
        log('Extension Request Response: $response');
      }

      // todo notify
      Api.post('sendNotificationToID', {
        'id': 'us_${widget.workerData['CaseManager']}',
        'title':
            'Extension requested for shift ${widget.shiftData['ShiftID']} #${response['insertId']}',
        'body':
            'Worker ${widget.workerData['WorkerID']} has requested an extension for shift ${widget.shiftData['ShiftID']} with reason: ${_extensionReasonController.text}',
        'data': {
          'type': 'shift_extension',
          'shiftID': widget.shiftData['ShiftID'],
          'workerID': widget.workerData['WorkerID'],
        },
      });

      Navigator.of(context).pop();

      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text('Extension Requested #${response['data']['insertId']}',
                style: TextStyle(color: widget.colorScheme.error)),
            content: Text(
                'Your extension request has been sent. \n Your case manager will review it soon.',
                style: TextStyle(color: widget.colorScheme.primary)),
            actions: [
              CupertinoDialogAction(
                child: Text('OK',
                    style: TextStyle(color: widget.colorScheme.error)),
                onPressed: () {
                  widget.onExtensionRequested
                      ?.call(response['data']['insertId']);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      log('Error Requesting Extension: $e');
    } finally {
      setState(() {
        image0 = null;
        doc = '';
        _progressState = 0.0;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Extend Shift?',
                style:
                    TextStyle(color: widget.colorScheme.error, fontSize: 20)),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Request an extension for this shift.',
                  style: TextStyle(color: widget.colorScheme.primary)),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Reason',
                  labelStyle: TextStyle(color: widget.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.colorScheme.primary),
                  ),
                ),
                controller: _extensionReasonController,
                style: TextStyle(color: widget.colorScheme.primary),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.upload_file,
                      color: widget.colorScheme.primary),
                  label: Text(
                    'Upload File',
                    style: TextStyle(
                        color: widget.colorScheme.primary, fontSize: 14),
                  ),
                ),
                ButtonSegment(
                  value: 1,
                  icon:
                      Icon(Icons.camera_alt, color: widget.colorScheme.primary),
                  label: Text(
                    'Take Photo',
                    style: TextStyle(
                        color: widget.colorScheme.primary, fontSize: 14),
                  ),
                ),
              ],
              emptySelectionAllowed: true,
              selected:
                  _selectedSegment != null ? {_selectedSegment!} : <int>{},
              showSelectedIcon: false,
              onSelectionChanged: (Set<int> selected) {
                setState(() {
                  _selectedSegment =
                      selected.isNotEmpty ? selected.first : null;
                });
                _handleSegmentSelection(_selectedSegment);
              },
            ),
            const SizedBox(height: 15),
            if (_progressState > 0.0)
              LinearProgressIndicator(
                value: _progressState,
                backgroundColor: widget.colorScheme.primary,
                valueColor:
                    AlwaysStoppedAnimation<Color>(widget.colorScheme.error),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (image0 != null)
                    Text('File: ${image0!.path.split('/').last}',
                        style: TextStyle(
                            color:
                                widget.colorScheme.tertiary.withOpacity(0.8))),
                  if (doc.isNotEmpty)
                    Text('File: ${doc.split('/').last}',
                        style: TextStyle(
                            color:
                                widget.colorScheme.tertiary.withOpacity(0.8))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    image0 = null;
                    doc = '';
                    _progressState = 0.0;
                    _extensionReasonController.clear();
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _requestExtension();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colorScheme.errorContainer,
                ),
                child: Text('Request Extension',
                    style:
                        TextStyle(color: widget.colorScheme.onErrorContainer)),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
