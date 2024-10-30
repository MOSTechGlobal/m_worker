import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/components/badgeIcon.dart';
import 'package:m_worker/pages/all_shifts/all_shift_details/sub_pages/shift_add_note_photo.dart';
import 'package:m_worker/pages/all_shifts/all_shift_details/sub_pages/shift_details.dart';
import 'package:m_worker/pages/all_shifts/all_shift_details/sub_pages/shift_incident/shift_incident_dialog.dart';
import 'package:m_worker/pages/all_shifts/all_shift_details/sub_pages/shift_profile.dart';
import 'package:m_worker/pages/all_shifts/all_shift_details/sub_pages/shift_profile_details/shift_profile_details_page.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_notes.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_split_details.dart';
import 'package:m_worker/utils/api.dart';

class AllShiftsDetailsPage extends StatefulWidget {
  final bool isLoc;
  final int shiftID;

  const AllShiftsDetailsPage(
      {super.key, required this.isLoc, required this.shiftID});

  @override
  State<AllShiftsDetailsPage> createState() => _AllShiftsDetailsPageState();
}

class _AllShiftsDetailsPageState extends State<AllShiftsDetailsPage>
    with TickerProviderStateMixin {
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
    _fetchShiftData(widget.shiftID);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _fetchShiftDataEndPoint() {
    if (widget.isLoc == true) {
      return 'getApprovedLocRosterShiftMainDataByShiftId';
    } else {
      return 'getApprovedShifts';
    }
  }

  Future<void> _fetchShiftData(shiftID) async {
    setState(() {
      isLoading = true;
    });
    final endPoint = _fetchShiftDataEndPoint();
    log('${widget.isLoc}');
    log('Fetching shift data for ShiftID: $shiftID');
    log('Fetching endPoint: $endPoint');
    await Api.get('$endPoint/$shiftID').then((response) {
      setState(() {
        shiftData = response['data'][0];
      });
    });
    log("shiftdata: $shiftData");
    log("before note: $hasAppNote");
    log("widget.isLoc ${widget.isLoc}");
    widget.isLoc == false
        ? _fetchClientmWorkerData()
        : shiftAlert = shiftData['AlertNote'] ?? '';
    if (mounted && shiftAlert.isNotEmpty && !_isDialogShown) {
      _isDialogShown = true;
      _showShiftAlert();
    }
    await _fetchIfSplitExists(shiftID);
    hasAppNote =
        shiftData['AppNote'] != null && shiftData['AppNote'].isNotEmpty;
    log("note: $hasAppNote");
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchIfSplitExists(int shiftID) async {
    log('Checking if split exists for ShiftID: $shiftID');
    try {
      final response = await Api.get('doesShiftSplitExist/$shiftID');
      log('Response from doesShiftSplitExist API: ${response.toString()}');
      if (response['data']) {
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
      log("clientID _fetchClientmWorkerData: ${shiftData["ClientID"]}");
      final response =
          await Api.get('getClientDetailsVWorkerData/${shiftData["ClientID"]}');
      log("getClientDetailsVWorkerData: $response");
      setState(() {
        clientmWorkerData = response['data'];
        shiftAlert = clientmWorkerData.isNotEmpty
            ? clientmWorkerData[0]['ShiftAlert'] ?? ''
            : '';
        hasProfile = clientmWorkerData.isNotEmpty;
      });
      log('clientmWorkerData : ${clientmWorkerData.toString()}');
      if (mounted && shiftAlert.isNotEmpty && !_isDialogShown) {
        _isDialogShown = true;
        _showShiftAlert();
      }
    } catch (e) {
      log('error string: ${e.toString()}');
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
                          ? BadgeIcon(icon: Icons.note_outlined, badgeCount: 1)
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
                          widget.isLoc == false
                              ? showShiftIncident(
                                  context,
                                  shiftData['ClientID'].toString(),
                                  '',
                                )
                              : showCreateIncidentDialog(context, shiftData);
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
                          widget.isLoc == false
                              ? showShiftAddNotePhoto(
                                  context, shiftData['ClientID'], false)
                              : showShiftAddNotePhoto(
                                  context, shiftData['LocationId'], true);
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
                          widget.isLoc == false
                              ? showShiftProfileDialog(
                                  context,
                                  clientmWorkerData.isNotEmpty
                                      ? clientmWorkerData[0]
                                      : {})
                              : Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ShiftProfileDetailsPage(
                                      shift: shiftData,
                                    ),
                                  ),
                                );
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
              : shiftData.isEmpty
                  ? const Center(child: Text('No Shift Selected'))
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
                                isLoc: widget.isLoc,
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

void showShiftAddNotePhoto(BuildContext context, clientID, isLoc) {
  showDialog(
    context: context,
    builder: (context) {
      return ShiftAddNotePhoto(
        clientID: clientID,
        isLoc: isLoc,
      );
    },
  );
}

void showCreateIncidentDialog(
    BuildContext context, Map<String, dynamic> shiftData) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return BlocBuilder<ThemeBloc, ThemeMode>(
            builder: (context, state) {
              final colorScheme = Theme.of(context).colorScheme;
              return Dialog(
                child: Material(
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Create Incident?',
                          style: TextStyle(
                              color: colorScheme.tertiary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Are you going to create the incident for a client or for a location?',
                          style: TextStyle(
                            color: colorScheme.primary,
                              fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ShiftProfileDetailsPage(
                                      shift: shiftData,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'YES, GO TO CLIENT LIST',
                                style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Divider(),
                            const SizedBox(height: 7),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                showShiftIncident(
                                  context,
                                  '',
                                  shiftData['LocationId'].toString(),
                                );
                              },
                              child: Text(
                                'NO, STAY HERE FOR LOCATION',
                                style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}
