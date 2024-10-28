import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/components/badgeIcon.dart';
import 'package:m_worker/pages/all_shifts/all_shift_details/sub_pages/shift_incident/shift_incident_dialog.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_add_note_photo.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_profile.dart';
import 'package:m_worker/utils/api.dart';
import 'package:s3_storage/s3_storage.dart';

import '../../../../../components/shift_detail/shift_detail_3rd_card.dart';

class ProfileDetails extends StatefulWidget {
  Map<String, dynamic> shiftData;
  bool isClient;

  ProfileDetails({super.key, required this.shiftData, required this.isClient});

  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails>
    with TickerProviderStateMixin {
  Map<String, dynamic> shiftData = {};
  List<dynamic> clientmWorkerData = [];
  late bool hasAppNote = false;
  late bool hasProfile = false;
  late String shiftAlert = '';
  String? _pfp;
  late bool isLoading = false;
  bool _isDialogShown = false; // Flag to track if the dialog has been shown

  bool _isSplit = false;

  @override
  void initState() {
    _getPfp(widget.shiftData['ClientProfilePhoto']);
    super.initState();
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

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final shiftArguments = ModalRoute.of(context)!.settings.arguments;
  //
  //   if (shiftArguments is Map<String, dynamic>) {
  //     shiftData = Map<String, dynamic>.from(shiftArguments);
  //     _fetchShiftData(shiftData['ShiftID']);
  //   }
  //   hasAppNote =
  //       shiftData['AppNote'] != null && shiftData['AppNote'].isNotEmpty;
  //   _fetchClientmWorkerData();
  // }

  // Future<void> _fetchShiftData(shiftID) async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   log('Fetching shift data for ShiftID: $shiftID');
  //   await Api.get('getApprovedShifts/$shiftID').then((response) {
  //     setState(() {
  //       shiftData = response['data'][0];
  //     });
  //   });
  //   await _fetchIfSplitExists(shiftID);
  //   setState(() {
  //     isLoading = false;
  //   });
  // }

  // Future<void> _fetchIfSplitExists(int shiftID) async {
  //   log('Checking if split exists for ShiftID: $shiftID');
  //   try {
  //     final response = await Api.get('doesShiftSplitExist/$shiftID');
  //     log('Response from API: ${response.toString()}');
  //     if (response['data']) {
  //       setState(() {
  //         _isSplit = true;
  //       });
  //       log('Split exists.');
  //     } else {
  //       setState(() {
  //         _isSplit = false;
  //       });
  //       log('No split found.');
  //     }
  //   } catch (e) {
  //     log('Error checking split shift: $e');
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  // Future<void> _fetchClientmWorkerData() async {
  //   try {
  //     log("clientID: ${shiftData["ClientID"]}");
  //     final response =
  //     await Api.get('getClientDetailsVWorkerData/${shiftData["ClientID"]}');
  //     log("getClientDetailsVWorkerData: $response");
  //     setState(() {
  //       clientmWorkerData = response['data'];
  //       shiftAlert = clientmWorkerData.isNotEmpty
  //           ? clientmWorkerData[0]['ShiftAlert'] ?? ''
  //           : '';
  //       hasProfile = clientmWorkerData.isNotEmpty;
  //     });
  //     log('clientmWorkerData : ${clientmWorkerData.toString()}');
  //     if (shiftAlert.isNotEmpty && !_isDialogShown) {
  //       _isDialogShown = true; // Set flag to true
  //       _showShiftAlert();
  //     }
  //   } catch (e) {
  //     log('error string: ${e.toString()}');
  //   }
  // }

  // void _showShiftAlert() {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         backgroundColor: Theme.of(context).colorScheme.surface,
  //         title: Text('Shift Alert',
  //             style: TextStyle(color: Theme.of(context).colorScheme.error)),
  //         content: Text(shiftAlert,
  //             style: TextStyle(
  //                 color: Theme.of(context).colorScheme.primary, fontSize: 20)),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Close'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  //
  // void _updateShiftStatus(String newStatus) {
  //   setState(() {
  //     shiftData['ShiftStatus'] = newStatus;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
            appBar: AppBar(
              title: widget.isClient == true
                  ? Text(
                      'Client Details',
                      style: TextStyle(color: colorScheme.primary),
                    )
                  : Text(
                      'Worker Details',
                      style: TextStyle(color: colorScheme.primary),
                    ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '#${widget.shiftData['ClientID']}',
                    style: TextStyle(
                      color: colorScheme.tertiary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  color: colorScheme.secondary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.info_outlined,
                              color: colorScheme.onSecondary),
                          onPressed: () {
                            // Handle Incident button
                            showShiftIncident(
                              context,
                              widget.isClient==true? widget.shiftData['ClientID'].toString() :widget.shiftData['WorkerID'].toString(),
                              ''
                            );
                          },
                        ),
                        Text('Incident',
                            style: TextStyle(
                              color: colorScheme.onSecondary,
                            )),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.upload_file_rounded,
                              color: colorScheme.onSecondary),
                          onPressed: () {
                            showShiftAddNotePhoto(
                                context, shiftData['ClientID']);
                          },
                        ),
                        Text('Add Note',
                            style: TextStyle(
                              color: colorScheme.onSecondary,
                            )),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: hasProfile
                              ? BadgeIcon(
                                  icon: Icons.person_pin,
                                  badgeCount: -1,
                                  iconColor: colorScheme.onSecondary)
                              : Icon(Icons.person_pin,
                                  color: colorScheme.onSecondary),
                          onPressed: () {
                            showShiftProfileDialog(
                                context,
                                widget.shiftData);
                          },
                        ),
                        Text('Profile',
                            style: TextStyle(
                              color: colorScheme.onSecondary,
                            )),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon:
                              Icon(Icons.more, color: colorScheme.onSecondary),
                          onPressed: () {
                            _showMoreOptions(context, colorScheme);
                          },
                        ),
                        Text('More',
                            style: TextStyle(
                              color: colorScheme.onSecondary,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                children: [
                  widget.shiftData['FirstName'] != null
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
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    '${widget.shiftData['FirstName'] ?? ""}${widget.shiftData['MiddleName'] ?? ""}${widget.shiftData['LastName'] ?? ""}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 30,
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
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
                            subtitle: widget.shiftData['CaseManager'] ?? '-',
                          ),
                          ShiftDetails3rdCard(
                            title: 'Age: ',
                            subtitle: '${widget.shiftData['Age'] ?? '-'}',
                          ),
                          ShiftDetails3rdCard(
                            title: 'DOB: ',
                            subtitle: '${widget.shiftData['DOB'] ?? '-'}',
                          ),
                          ShiftDetails3rdCard(
                            title: 'Location: ',
                            subtitle:
                                '${widget.shiftData['AddressLine1'] ?? ''} ${widget.shiftData['AddressLine2'] ?? ''} ${widget.shiftData['Suburb'] ?? ''} ${widget.shiftData['Postcode'] ?? ''}',
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ));
      },
    );
  }

  void _showMoreOptions(BuildContext context, ColorScheme colorScheme) {
    showModalBottomSheet(
      backgroundColor: colorScheme.surface,
      context: context,
      builder: (context) {
        return _buildMoreOptions(colorScheme);
      },
    );
  }

  Widget _buildMoreOptions(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.history, color: colorScheme.primary),
          title: const Text('History'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.file_copy, color: colorScheme.primary),
          title: const Text('Documents'),
          onTap: () {
            Navigator.pushNamed(context, '/shift_more_documents', arguments: {
              'ClientID': shiftData['ClientID'],
            });
          },
        ),
        ListTile(
          leading: Icon(Icons.monetization_on, color: colorScheme.primary),
          title: const Text('Expenses'),
          onTap: () {
            Navigator.pushNamed(context, '/shift_more_expenses', arguments: {
              'ClientID': shiftData['ClientID'],
              'ShiftID': shiftData['ShiftID'],
            });
          },
        ),
        ListTile(
          leading: Icon(Icons.paste, color: colorScheme.primary),
          title: const Text('Forms'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

void showShiftProfileDialog(
    BuildContext context, Map<String, dynamic> clientmWorkerData) {
  showDialog(
    context: context,
    builder: (context) {
      return ShiftProfile(clientmWorkerData: clientmWorkerData);
    },
  );
}

void showShiftAddNotePhoto(BuildContext context, clientID) {
  showDialog(
    context: context,
    builder: (context) {
      return ShiftAddNotePhoto(clientID: clientID);
    },
  );
}
