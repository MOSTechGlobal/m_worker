import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:m_worker/utils/api.dart';
import 'package:m_worker/utils/prefs.dart';
import 'package:s3_storage/s3_storage.dart';

import '../../../../bloc/theme_bloc.dart';

class ShiftAddNotePhoto extends StatefulWidget {
  final dynamic clientID;
  final bool? isLoc;

  const ShiftAddNotePhoto({super.key, required this.clientID, this.isLoc});

  @override
  State<ShiftAddNotePhoto> createState() => _ShiftAddNotePhotoState();
}

class _ShiftAddNotePhotoState extends State<ShiftAddNotePhoto> {
  int? _selectedSegment;
  late final _noteController = TextEditingController();
  XFile? image0;
  late dynamic clientData = {};

  late dynamic _progressState = 0.0;

  Future<void> _fetchClientData() async {
    try {
      final response = await Api.get('getClientMasterData/${widget.clientID}');
      setState(() {
        clientData = response['data'][0];
      });
    } catch (e) {
      log(e.toString());
    }
  }

  Future _saveNote() async {
    final email = await Prefs.getEmail();
    final note = _noteController.text;
    if (note.isNotEmpty) {
      // TODO: redesign the existing table structure
      // TODO: fix the data to be sent and the endpoint to be called after confirming and fixing the backend
      final data = {
        'Note': note,
        'NoteType': 'APP NOTE',
        // TODO: Confirm note category to get from maintenance
        'CreatedBy': email,
        'VisibleWorkerApp': 1,
        // 'VisibleClientApp': 1,
        // ServiceCode: 'string',
        // ServiceDate: 'string', // Shift Date
      };

      widget.isLoc == false
          ? await Api.post('insertClientNotesData/${widget.clientID}', data)
          : await Api.post('postLocProfNotesData/${widget.clientID}', data);
      Navigator.of(context).pop();
    } else {
      final snackBar = SnackBar(
        content: const Text('Note cannot be empty',
            style: TextStyle(fontSize: 16, color: Colors.white)),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red.withOpacity(0.8),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _saveImage() async {
    _fetchClientData();
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final company = await Prefs.getCompanyName();

      final objectLocation = widget.isLoc == false
          ? '$company/client/${widget.clientID}/notes/${image0!.path.split('/').last}'
          : '$company/location/${widget.clientID}/notes/${image0!.path.split('/').last}';

      await s3Storage.putObject(
        'moscaresolutions',
        objectLocation,
        Stream<Uint8List>.value(
            Uint8List.fromList(File(image0!.path).readAsBytesSync())),
        onProgress: (progress) {
          setState(() {
            _progressState =
                progress.toDouble() / File(image0!.path).lengthSync();
          });
        },
      );

      // store in db
      final email = await Prefs.getEmail();
      if (image0 != null) {
        // TODO: redesign the existing table structure
        // TODO: fix the data to be sent and the endpoint to be called after confirming and fixing the backend
        final data = {
          'Note':
              'https://moscaresolutions.s3.ap-southeast-2.amazonaws.com/$objectLocation',
          'NoteType': 'APP NOTE',
          // TODO: Confirm note category to get from maintenance
          'CreatedBy': email,
          'VisibleWorkerApp': 1,
          // 'VisibleClientApp': 1,
          // ServiceCode: 'string',
          // ServiceDate: 'string', // Shift Date
        };

        log('insertClientNotesData/${widget.clientID}');
        log('notes/$data}');

        widget.isLoc == false
            ? await Api.post('insertClientNotesData/${widget.clientID}', data)
            : await Api.post('postLocProfNotesData/${widget.clientID}', data);
        Navigator.of(context).pop();
      }
    } catch (e) {
      log('Error uploading document: $e');
    } finally {
      setState(() {
        image0 = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Dialog(
          child: SizedBox(
            width: double.infinity,
            height: 400.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    'Add Note',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter note here',
                      ),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      _saveNote();
                    },
                    child: const Text('Save'),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        icon:
                            Icon(Icons.upload_file, color: colorScheme.primary),
                        label: Text(
                          'Upload Image',
                          style: TextStyle(
                              color: colorScheme.primary, fontSize: 14),
                        ),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon:
                            Icon(Icons.camera_alt, color: colorScheme.primary),
                        label: Text(
                          'Take Photo',
                          style: TextStyle(
                              color: colorScheme.primary, fontSize: 14),
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
                        _selectedSegment =
                            selected.isNotEmpty ? selected.first : null;
                      });
                      _handleSegmentSelection(_selectedSegment);
                    },
                  ),
                  const SizedBox(height: 15),
                  if (image0 != null)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: _progressState,
                          backgroundColor:
                              colorScheme.secondary.withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  // info text
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: colorScheme.tertiary.withOpacity(0.5)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Note: You can add a note or a photo, but not both.',
                          style: TextStyle(
                            color: colorScheme.tertiary.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  )
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
      // Handle no selection
      log('No selection');
      return;
    }

    if (index == 0) {
      // Handle image upload
      _uploadImage();
    } else if (index == 1) {
      // Handle taking a photo
      _takePhoto();
    }

    setState(() {
      _selectedSegment = null;
    });
  }

  Future<void> _uploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        image0 = image;
      });
      _saveImage();
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        image0 = image;
      });
      _saveImage();
    }
  }
}
