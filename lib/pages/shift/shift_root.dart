import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/components/badgeIcon.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_details.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_notes.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_profile.dart';
import 'package:m_worker/utils/api.dart';

class ShiftRoot extends StatefulWidget {
  const ShiftRoot({super.key});

  @override
  State<ShiftRoot> createState() => _ShiftRootState();
}

class _ShiftRootState extends State<ShiftRoot> {
  Map<String, dynamic> shiftData = {};
  List<dynamic> clientmWorkerData = [];
  late int _selectedIndex = 0;
  final PageController _pageController = PageController();
  late bool hasAppNote = false;
  late bool hasProfile = false;
  late String shiftAlert = '';
  bool _isDialogShown = false; // Flag to track if the dialog has been shown

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shift =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    shiftData = Map<String, dynamic>.from(shift);
    hasAppNote =
        shiftData['AppNote'] != null && shiftData['AppNote'].isNotEmpty;
    hasProfile = clientmWorkerData.isNotEmpty;
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shift Details'),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: NavigationBar(
              animationDuration: const Duration(milliseconds: 300),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                if (index < 4) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                } else if (index == 4) {
                  showShiftProfileDialog(context,
                      clientmWorkerData.isNotEmpty ? clientmWorkerData[0] : {});
                } else if (index == 5) {
                  _showMoreOptions(context, colorScheme);
                }
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.info_outlined),
                  label: 'Details',
                  selectedIcon: Icon(Icons.info),
                ),
                const NavigationDestination(
                  icon: Icon(Icons.warning_amber),
                  label: 'Incident',
                  selectedIcon: Icon(Icons.warning),
                ),
                NavigationDestination(
                  icon: hasAppNote
                      ? const BadgeIcon(
                          icon: Icons.note_outlined, badgeCount: 1)
                      : const Icon(Icons.note_outlined),
                  label: 'Notes',
                  selectedIcon: const Icon(Icons.note),
                ),
                const NavigationDestination(
                  icon: Icon(Icons.upload_file),
                  label: 'Add Note/Photo',
                  selectedIcon: Icon(Icons.upload_file_rounded),
                ),
                NavigationDestination(
                  icon: hasProfile
                      ? const BadgeIcon(icon: Icons.person_pin, badgeCount: 1)
                      : const Icon(Icons.person_pin),
                  label: 'Profile',
                  selectedIcon: const Icon(Icons.person_pin),
                ),
                const NavigationDestination(
                  icon: Icon(Icons.more_outlined),
                  label: 'More',
                  selectedIcon: Icon(Icons.more),
                ),
              ],
            ),
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              if (index < 4) {
                setState(() {
                  _selectedIndex = index;
                });
              } else if (index == 4) {
                showShiftProfileDialog(context,
                    clientmWorkerData.isNotEmpty ? clientmWorkerData[0] : {});
              } else if (index == 5) {
                _showMoreOptions(context, colorScheme);
              }
            },
            children: [
              ShiftDetails(
                shift: shiftData,
              ),
              Center(
                child: Text('Incident',
                    style: TextStyle(fontSize: 30, color: colorScheme.primary)),
              ),
              ShiftNotes(
                shift: shiftData,
                clientmWorkerData:
                    clientmWorkerData.isNotEmpty ? clientmWorkerData[0] : {},
              ),
              Center(
                child: Text('Add Note/Photo',
                    style: TextStyle(fontSize: 30, color: colorScheme.primary)),
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
