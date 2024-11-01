import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:m_worker/utils/api.dart';
import 'package:m_worker/utils/prefs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:s3_storage/s3_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/theme_bloc.dart';

class Documents extends StatefulWidget {
  const Documents({super.key});

  @override
  State<Documents> createState() => _DocumentsState();
}

class _DocumentsState extends State<Documents> {
  final workerDocs = [];
  late List documentCategories = [];

  late double _uploadState = 0.0;
  late bool _isLoading = false;

  @override
  void initState() {
    _fetchData();
    _fetchDocumentCategories();
    askForPermission();
    super.initState();
  }

  void _fetchDocumentCategories() async {
    try {
      final response = await Api.get('getDocumentCategories');
      final Map<String, dynamic> res = response as Map<String, dynamic>;
      setState(() {
        documentCategories.clear();
        documentCategories.addAll(res['data']);
      });
      log('Document categories: $documentCategories');
    } catch (e) {
      log('Error fetching document categories: $e');
    }
  }

  void askForPermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    } else {
      log('Permission already granted');
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final workerID = await Prefs.getWorkerID();
      final response = await Api.get('getWorkerDocumentData/$workerID');
      final Map<String, dynamic> res = response as Map<String, dynamic>;
      setState(() {
        workerDocs.clear();
        workerDocs.addAll(res['data']);
      });
      log('Worker documents: $workerDocs');
    } catch (e) {
      log('Error fetching data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _uploadDoc() async {
    final documentDetails = await _getDocumentDetails();
    if (documentDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No document to upload',
              style: TextStyle(
                color: Colors.white,
              )),
          backgroundColor: Colors.red,
          showCloseIcon: true,
          closeIconColor: Colors.white,
        ),
      );
      return;
    }

    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final company = await Prefs.getCompanyName();
      final workerID = await Prefs.getWorkerID();
      await s3Storage.putObject(
        'moscaresolutions',
        '$company/worker/$workerID/documents/${documentDetails['DocCategory']}_${documentDetails['DocName']}/${File(documentDetails['DocFile']).path.split('/').last}',
        Stream<Uint8List>.value(Uint8List.fromList(
            await File(documentDetails['DocFile']).readAsBytes())),
        onProgress: (bytes) => setState(() {
          _uploadState = bytes.toDouble() /
              File(documentDetails['DocFile']).lengthSync().toDouble();
        }),
      );

      if (_uploadState == 1.0) {
        _insertDocument(documentDetails);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!',
                style: TextStyle(
                  color: Colors.white,
                )),
            backgroundColor: Colors.green,
            showCloseIcon: true,
            closeIconColor: Colors.white,
          ),
        );
      }
    } catch (e) {
      log('Error uploading document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading document: $e',
              style: const TextStyle(
                color: Colors.white,
              )),
          backgroundColor: Colors.red,
          showCloseIcon: true,
          closeIconColor: Colors.white,
        ),
      );
    } finally {
      setState(() {
        _uploadState = 0.0;
      });
    }

    log('Document details: $documentDetails');
  }

  Future _insertDocument(Map documentDetails) async {
    try {
      final workerID = await Prefs.getWorkerID();
      final email = await Prefs.getEmail();
      final company = await Prefs.getCompanyName();
      final response = await Api.post('insertWorkerDocumentData/$workerID', {
        'DocName': documentDetails['DocName'],
        'Category': documentDetails['DocCategory'],
        'Note': documentDetails['DocNote'],
        // s3://moscaresolutions/teuila/worker/abdulqadir@mostech.solutions/1_test2 document name/
        'Bucket': 'moscaresolutions',
        'Folder':
            '$company/worker/$workerID/documents/${documentDetails['DocCategory']}_${documentDetails['DocName']}',
        'File': File(documentDetails['DocFile']).path.split('/').last,
        'CreatedBy': email,
      });
      final Map<String, dynamic> res = response as Map<String, dynamic>;
      log('Document inserted: $res');
      _fetchData();
    } catch (e) {
      log('Error inserting document: $e');
    }
  }

  void _downloadDoc(bucket, folder, file) async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final signedUrl =
          await s3Storage.presignedGetObject(bucket, '$folder/$file');
      log('Signed URL: $signedUrl');
      launch(signedUrl);
    } catch (e) {
      log('Error getting profile picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Documents'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _uploadDoc,
            backgroundColor: colorScheme.primary,
            child: Icon(Icons.add, color: colorScheme.onPrimary),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await _fetchData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _uploadState == 0.0
                      ? const SizedBox()
                      : LinearProgressIndicator(
                          value: _uploadState,
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                  const SizedBox(height: 10),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : workerDocs.isEmpty
                          ? const Center(
                              child: Text(
                                'No documents found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : _buildDocuments(colorScheme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocuments(ColorScheme colorScheme) {
    return Column(
      children: workerDocs.map((doc) {
        return Card(
          color: colorScheme.secondaryContainer,
          margin: const EdgeInsets.all(10),
          child: ListTile(
            title: Text(
              doc['DocName'],
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['DocumentCategoryDescription'],
                  style: TextStyle(
                    color: colorScheme.primary.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
                Text(
                  doc['Note'],
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                log('${doc['Bucket']}, ${doc['Folder']}, ${doc['File']}');
                _downloadDoc(doc['Bucket'], doc['Folder'], doc['File']);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<Map> _getDocumentDetails() async {
    final data = {};
    FilePickerResult? result;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Upload Document',
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Document Name',
                      labelStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2.0,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onChanged: (value) {
                      data['DocName'] = value;
                    },
                  ),

                  const SizedBox(height: 10),
                  // Add some space between text fields

                  // dropdown for document category
                  DropdownButtonFormField(
                    decoration: InputDecoration(
                      labelText: 'Document Category',
                      labelStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2.0,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    dropdownColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    items: documentCategories.map((category) {
                      return DropdownMenuItem(
                        value: category['ID'],
                        child: Text(category['Description']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      data['DocCategory'] = value;
                    },
                  ),

                  const SizedBox(height: 10),
                  // Add some space between text fields

                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Document Note',
                      labelStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2.0,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onChanged: (value) {
                      data['DocNote'] = value;
                    },
                  ),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 1,
                      ),
                    ),
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withOpacity(0.7),
                    child: ListTile(
                      title: Text(
                        result != null
                            ? result!.files.single.name
                            : 'Select File',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.upload_file),
                        onPressed: () async {
                          result = await FilePicker.platform.pickFiles();
                          if (result != null) {
                            setState(() {
                              data['DocFile'] = result!.files.first.path;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, data);
                  },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );

    return data;
  }
}
