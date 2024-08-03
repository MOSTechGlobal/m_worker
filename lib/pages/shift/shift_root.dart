import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/components/shift_detail/shift_detail_3rd_card.dart';
import 'package:m_worker/pages/shift/shift_details.dart';
import 'package:m_worker/utils/api.dart';

class ShiftRoot extends StatefulWidget {
  const ShiftRoot({super.key});

  @override
  State<ShiftRoot> createState() => _ShiftRootState();
}

class _ShiftRootState extends State<ShiftRoot> {
  final shiftData = {};

  late int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final shift =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    setState(() {
      shiftData.clear();
      shiftData.addAll(shift);
    });
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
                if (index < 5) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                } else if (index == 5) {
                  _showMoreOptions(context, colorScheme);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.info_outlined),
                  label: 'Details',
                  selectedIcon: Icon(Icons.info),
                ),
                NavigationDestination(
                  icon: Icon(Icons.warning_amber),
                  label: 'Incident',
                  selectedIcon: Icon(Icons.warning),
                ),
                NavigationDestination(
                  icon: Icon(Icons.note_outlined),
                  label: 'Notes',
                  selectedIcon: Icon(Icons.note),
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_pin_outlined),
                  label: 'Profile',
                  selectedIcon: Icon(Icons.person_pin),
                ),
                NavigationDestination(
                  icon: Icon(Icons.upload_file),
                  label: 'Add Note/Photo',
                  selectedIcon: Icon(Icons.upload_file_rounded),
                ),
                NavigationDestination(
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
              if (index < 5) {
                setState(() {
                  _selectedIndex = index;
                });
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
                      style: TextStyle(fontSize: 30, color: colorScheme.primary))),
              Center(
                  child: Text('Notes',
                      style: TextStyle(fontSize: 30, color:colorScheme.primary))),
              Center(
                  child: Text('Profile',
                      style: TextStyle(fontSize: 30, color: colorScheme.primary))),
              Center(
                  child: Text('Add Note/Photo',
                      style: TextStyle(fontSize: 30, color: colorScheme.primary))),
            ],
          ),
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context, colorScheme) {
    showModalBottomSheet(
      backgroundColor: colorScheme.background,
      context: context,
      builder: (context) {
        return _buildMoreOptions(colorScheme);
      },
    );
  }

  Widget _buildMoreOptions(colorScheme) {
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
