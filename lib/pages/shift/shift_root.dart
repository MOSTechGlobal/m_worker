import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/components/badgeIcon.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_add_note_photo.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_details.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_notes.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_profile.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_split_details.dart';
import 'package:m_worker/utils/api.dart';

import '../../components/shift_detail/shift_incident/shift_incident.dart';

class ShiftRoot extends StatefulWidget {
  const ShiftRoot({super.key});

  @override
  State<ShiftRoot> createState() => _ShiftRootState();
}

class _ShiftRootState extends State<ShiftRoot> with TickerProviderStateMixin {
  Map<String, dynamic> shiftData = {};
  List<dynamic> clientmWorkerData = [];
  late TabController _tabController;
  late bool hasAppNote = false;
  late bool hasProfile = false;
  late String shiftAlert = '';
  late bool isLoading = false;
  bool _isDialogShown = false; // Flag to track if the dialog has been shown

  bool _isSplit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shiftArguments = ModalRoute.of(context)!.settings.arguments;

    if (shiftArguments is Map<String, dynamic>) {
      shiftData = Map<String, dynamic>.from(shiftArguments);
      _fetchShiftData(shiftData['ShiftID']);
    }
    hasAppNote =
        shiftData['AppNote'] != null && shiftData['AppNote'].isNotEmpty;
    _fetchClientmWorkerData();
  }

  Future<void> _fetchShiftData(shiftID) async {
    setState(() {
      isLoading = true;
    });
    log('Fetching shift data for ShiftID: $shiftID');
    await Api.get('getApprovedShifts/$shiftID').then((response) {
      setState(() {
        shiftData = response['data'][0];
      });
    });
    await _fetchIfSplitExists(shiftID);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchIfSplitExists(int shiftID) async {
    log('Checking if split exists for ShiftID: $shiftID');
    try {
      final response = await Api.get(
          'checkIfSplitShiftExists/206'); // todo change to shiftID
      log('Response from API: ${response.toString()}');
      if (response['data'].isNotEmpty) {
        setState(() {
          _isSplit = true;
        });
        log('Split exists.');
      } else {
        setState(() {
          _isSplit = false;
        });
        log('No split found.');
      }
    } catch (e) {
      log('Error checking split shift: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchClientmWorkerData() async {
    try {
      final response =
          await Api.get('getClientDetailsVWorkerData/${shiftData["ClientID"]}');
      setState(() {
        clientmWorkerData = response['data'];
        shiftAlert = clientmWorkerData.isNotEmpty
            ? clientmWorkerData[0]['ShiftAlert'] ?? ''
            : '';
        hasProfile = clientmWorkerData.isNotEmpty;
      });
      log(clientmWorkerData.toString());
      if (shiftAlert.isNotEmpty && !_isDialogShown) {
        _isDialogShown = true; // Set flag to true
        _showShiftAlert();
      }
    } catch (e) {
      log(e.toString());
    }
  }

  void _showShiftAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Shift Alert',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          content: Text(shiftAlert,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary, fontSize: 20)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _updateShiftStatus(String newStatus) {
    setState(() {
      shiftData['ShiftStatus'] = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shift Details'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '#${shiftData['ShiftID']}',
                  style: TextStyle(
                    color: colorScheme.tertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outlined),
                      SizedBox(width: 4),
                      Text('Details'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      hasAppNote
                          ? const BadgeIcon(
                              icon: Icons.note_outlined, badgeCount: 1)
                          : const Icon(Icons.note_outlined),
                      const SizedBox(width: 4),
                      const Text('Notes'),
                    ],
                  ),
                ),
              ],
            ),
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
                              shiftData['ClientID'].toString(),
                              shiftData['SupportWorker1'].toString());
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
                          showShiftAddNotePhoto(context, shiftData['ClientID']);
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
                              clientmWorkerData.isNotEmpty
                                  ? clientmWorkerData[0]
                                  : {});
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
                        icon: Icon(Icons.more, color: colorScheme.onSecondary),
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
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _isSplit
                        ? ShiftSplitDetails(
                            shift: shiftData,
                            onStatusChanged: _updateShiftStatus,
                          )
                        : ShiftDetails(
                            shift: shiftData,
                            onStatusChanged: _updateShiftStatus,
                          ),
                    ShiftNotes(
                      shift: shiftData,
                      clientmWorkerData: clientmWorkerData.isNotEmpty
                          ? clientmWorkerData[0]
                          : {},
                    ),
                  ],
                ),
        );
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
