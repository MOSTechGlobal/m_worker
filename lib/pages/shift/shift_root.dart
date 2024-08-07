import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/components/badgeIcon.dart';
import 'package:m_worker/pages/shift/sub_pages/more/timesheet_remarks.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_add_note_photo.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_details.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_notes.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_profile.dart';
import 'package:m_worker/utils/api.dart';

class ShiftRoot extends StatefulWidget {
  const ShiftRoot({super.key});

  @override
  State<ShiftRoot> createState() => _ShiftRootState();
}

class _ShiftRootState extends State<ShiftRoot>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> shiftData = {};
  List<dynamic> clientmWorkerData = [];
  late int _bottomNavIndex = 0;
  late TabController _tabController;
  late bool hasAppNote = false;
  late bool hasProfile = false;
  late String shiftAlert = '';
  bool _isDialogShown = false; // Flag to track if the dialog has been shown

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shift =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    shiftData = Map<String, dynamic>.from(shift);
    hasAppNote =
        shiftData['AppNote'] != null && shiftData['AppNote'].isNotEmpty;
    _fetchClientmWorkerData();
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
          title: Text(
            'Shift Alert',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          content: Text(
            shiftAlert,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 20,
            ),
          ),
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
                  'ID: ${shiftData['ShiftID']}',
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
                          ? const BadgeIcon(icon: Icons.note_outlined, badgeCount: 1)
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: NavigationBar(
              animationDuration: const Duration(milliseconds: 300),
              selectedIndex: _bottomNavIndex,
              indicatorColor: Colors.transparent,
              surfaceTintColor: colorScheme.surface,
              onDestinationSelected: (index) {
                setState(() {
                  _bottomNavIndex = index;
                });
                if (index == 0) {
                  // Handle Incident button
                } else if (index == 1) {
                  showShiftAddNotePhoto(context, shiftData['ClientID']);
                } else if (index == 2) {
                  showShiftProfileDialog(context,
                      clientmWorkerData.isNotEmpty ? clientmWorkerData[0] : {});
                } else if (index == 3) {
                  showTimesheetRemarksDialog(context);
                } else if (index == 4) {
                  _showMoreOptions(context, colorScheme);
                }
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.info_outlined),
                  label: 'Incident',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.upload_file_rounded),
                  label: 'Add Note/Photo',
                ),
                NavigationDestination(
                  icon: hasProfile
                      ? const BadgeIcon(icon: Icons.person_pin, badgeCount: 1)
                      : const Icon(Icons.person_pin),
                  label: 'Profile',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.more_time),
                  label: 'Timesheet Remarks',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.more),
                  label: 'More',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              ShiftDetails(shift: shiftData),
              ShiftNotes(
                shift: shiftData,
                clientmWorkerData:
                    clientmWorkerData.isNotEmpty ? clientmWorkerData[0] : {},
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
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.monetization_on, color: colorScheme.primary),
          title: const Text('Expenses'),
          onTap: () {
            Navigator.pop(context);
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

void showTimesheetRemarksDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return const TimesheetRemarks();
    },
    showDragHandle: true,
    enableDrag: true,
  );
}
