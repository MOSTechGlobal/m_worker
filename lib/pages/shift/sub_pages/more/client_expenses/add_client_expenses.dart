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

import '../../../../../bloc/theme_bloc.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  late final _descriptionController = TextEditingController();
  late final _amountController = TextEditingController();
  XFile? selectedImage;
  String imageUrl = '';
  late double _progressState = 0.0;
  int? _selectedSegment;

  int clientId = 0;
  int shiftId = 0;

  int? expenseId;

  @override
  void didChangeDependencies() {
    // get the clientId from the named route
    final arg =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    log('args: $arg');
    setState(() {
      clientId = arg?['ClientID'] ?? 0;
      shiftId = arg?['ShiftID'] ?? 0;
      expenseId = arg?['ExpenseID'];
    });

    if (expenseId != null) {
      // fetch the expense details
      _fetchExpenseDetails();
    }
    super.didChangeDependencies();
  }

  Future<void> _fetchExpenseDetails() async {
    try {
      final res = await Api.get('getClientExpensesDataByExpId/$expenseId');
      setState(() {
        _descriptionController.text = res['data'][0]['Description'];
        _amountController.text = res['data'][0]['TotalAmount'].toString();
      });
      _getImage('${res['data'][0]['Bucket']}', '${res['data'][0]['Folder']}',
          '${res['data'][0]['File']}');
    } catch (e) {
      log('Error fetching data: $e');
    }
  }

  void _getImage(bucket, folder, file) async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final url = await s3Storage.presignedGetObject(
        bucket,
        '$folder$file',
      );

      log('URL: $url');

      setState(() {
        imageUrl = url;
      });
    } catch (e) {
      log('Error getting profile picture: $e');
    }
  }

  Future<void> _saveExpense() async {
    final description = _descriptionController.text;
    final amount = _amountController.text;

    if (description.isNotEmpty && amount.isNotEmpty && selectedImage != null) {
      final email = await Prefs.getEmail();
      final company = await Prefs.getCompanyName();

      final data = {
        'Description': description,
        'TotalAmount': amount,
        'Date': DateTime.now().toIso8601String(),
        'Bucket': 'moscaresolutions',
        'Folder': '$company/client/$clientId/expenses/',
        'File':
            '${_descriptionController.text}_${selectedImage!.path.split('/').last}',
        'ShiftID': shiftId,
      };

      if (expenseId != null) {
        // If expenseId exists, we're updating an existing expense
        data['UpdaterUser'] = email.toString();
        data['UpdaterDate'] = DateTime.now().toIso8601String();
        await Api.put('updateClientExpensesDataById/$expenseId', data);
      } else {
        // Otherwise, we're creating a new expense
        data['MakerUser'] = email.toString();
        data['MakerDate'] = DateTime.now().toIso8601String();
        await Api.post('postClientExpensesDataWithShift/$clientId', data);
      }

      await _saveImage();
      Navigator.of(context).pop(); // Go back to previous screen after save
    } else {
      final snackBar = SnackBar(
        content: const Text(
          'All fields are required',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red.withOpacity(0.8),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _saveImage() async {
    final company = await Prefs.getCompanyName();
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final objectLocation =
          '$company/client/$clientId/expenses/${_descriptionController.text}_${selectedImage!.path.split('/').last}';

      await s3Storage.putObject(
        'moscaresolutions',
        objectLocation,
        Stream<Uint8List>.value(
            Uint8List.fromList(File(selectedImage!.path).readAsBytesSync())),
        onProgress: (progress) {
          setState(() {
            _progressState =
                progress.toDouble() / File(selectedImage!.path).lengthSync();
          });
        },
      );

      final imageUrl =
          'https://moscaresolutions.s3.ap-southeast-2.amazonaws.com/$objectLocation';
      log('Image uploaded: $imageUrl');
    } catch (e) {
      log('Error uploading document: $e');
    } finally {
      setState(() {
        selectedImage = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  void _handleSegmentSelection(int? index) {
    if (index == 0) {
      _uploadImage();
    } else if (index == 1) {
      _takePhoto();
    }

    setState(() {
      _selectedSegment = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              expenseId != null ? 'Update Expense' : 'Add Expense',
              style:
                  TextStyle(color: colorScheme.onSurface), // AppBar text color
            ),
            backgroundColor: colorScheme.surface, // AppBar background color
          ),
          backgroundColor: colorScheme.surface, // Scaffold background color
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary, // Use primary color
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(
                      color: colorScheme.onSurface, // Use onSurface color
                    ),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor:
                          colorScheme.surface, // Use surface variant color
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: colorScheme.onSurface, // Use onSurface color
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor:
                          colorScheme.surface, // Use surface variant color
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SegmentedButton<int>(
                      emptySelectionAllowed: true,
                      segments: [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.upload_file,
                              color: colorScheme.primary),
                          label: Text('Upload Image',
                              style: TextStyle(color: colorScheme.primary)),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.camera_alt,
                              color: colorScheme.primary),
                          label: Text('Take Photo',
                              style: TextStyle(color: colorScheme.primary)),
                        ),
                      ],
                      selected: _selectedSegment != null
                          ? {_selectedSegment!}
                          : <int>{},
                      onSelectionChanged: (Set<int> selected) {
                        setState(() {
                          _selectedSegment =
                              selected.isNotEmpty ? selected.first : null;
                        });
                        _handleSegmentSelection(_selectedSegment);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (selectedImage != null || imageUrl.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // pop up the image in a dialog
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(
                                      color: colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                size: 30,
                                                color: colorScheme.error,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  selectedImage = null;
                                                });
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                size: 30,
                                                color: colorScheme.primary,
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                        selectedImage == null &&
                                                imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                              )
                                            : Image.file(
                                                File(selectedImage!.path)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Stack(
                            children: [
                              selectedImage == null && expenseId != null
                                  ? FadeInImage.assetNetwork(
                                      placeholder:
                                          'assets/images/id_card_pfp_placeholder.png',
                                      image: imageUrl,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      fadeInDuration:
                                          const Duration(milliseconds: 500),
                                    )
                                  : Image.file(
                                      File(selectedImage!.path),
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                              Positioned(
                                top: 0,
                                right: 0,
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Icon(
                                    Icons.open_in_full,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _saveExpense,
                        icon: const Icon(Icons.save),
                        label: expenseId != null
                            ? const Text('Update Expense')
                            : const Text('Save Expense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_progressState > 0) ...[
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: _progressState,
                      backgroundColor: colorScheme.onSurface.withOpacity(0.2),
                      color: colorScheme
                          .primary, // Primary color for progress indicator
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
