import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/components/shift_tile/listTile.dart';
import 'package:m_worker/utils/api.dart';
import 'package:m_worker/weather/weather_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<dynamic> shifts = [];
  late dynamic workerData = [];
  late dynamic _worker = {};

  final Set<String> _selectedSegment = {'Today'};
  String? errorMessage;
  bool isLoading = true;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _fetchWorkerShifts() async {
    final user = FirebaseAuth.instance.currentUser!.email;
    try {
      final res = await Api.get('getWorkerMasterDataByEmail/$user');
      _worker = res['data'];
      final workerShifts =
          await Api.get('getShiftMainDataByWorkerID/${_worker['WorkerID']}');
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        try {
          await Api.post('upsertFCMToken', {
            'WorkerID': _worker['WorkerID'],
            'FCMToken': fcmToken,
          });
        } catch (e) {
          log('Error inserting FCM token: $e');
        }
      }
      if (_selectedSegment.contains('Today')) {
        shifts = workerShifts['data'] ?? [];
      } else {
        shifts = workerShifts['data'] ?? [];
      }
      if (shifts.isEmpty) {
        setState(() {
          errorMessage = 'No shifts found';
        });
      }
    } catch (e) {
      log('Error fetching worker shifts: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    _fetchWorkerShifts();
    super.initState();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toUtc();

    final todayShifts = shifts.where((shift) {
      final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .parse(shift['ShiftStart'], true);
      return isSameDay(shiftStart, today);
    }).toList();

    final fortnightShifts = shifts.where((shift) {
      final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .parse(shift['ShiftStart'], true);
      return shiftStart.isAfter(today) &&
          shiftStart.isBefore(today.add(const Duration(days: 14)));
    }).toList();

    final groupedFortnightShifts = groupBy(fortnightShifts, (shift) {
      final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .parse(shift['ShiftStart'], true);
      return DateFormat('yyyy-MM-dd').format(shiftStart);
    });

    final sortedFortnightDates = groupedFortnightShifts.keys.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a);
        final dateB = DateTime.parse(b);
        return dateA.compareTo(dateB);
      });

    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: ImageIcon(
              const AssetImage('assets/images/logo.png'),
              color: colorScheme.primary,
              size: 40,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _signOut,
              ),
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              WeatherWidget(
                city: 'Sydney',
                userName: _worker['FirstName'] ?? 'Worker',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedSegment.contains('Today')
                          ? DateFormat('EE d MMMM').format(DateTime.now())
                          : 'Fortnight\'s Shifts',
                      style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.secondary.withOpacity(0.7)),
                    ),
                    SegmentedButton(
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        enableFeedback: true,
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.disabled)) {
                              return colorScheme.secondary;
                            }
                            return colorScheme.secondary;
                          },
                        ),
                        animationDuration: const Duration(milliseconds: 300),
                      ),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'Today', label: Text('Today')),
                        ButtonSegment(
                            value: 'Fortnight', label: Text('Fortnight')),
                      ],
                      selected: _selectedSegment,
                      onSelectionChanged: (Set<String> newSelection) {
                        if (newSelection.contains('Today')) {
                          setState(() {
                            errorMessage = null;
                            isLoading = true;
                            _selectedSegment.clear();
                            _selectedSegment.add('Today');
                          });
                          _fetchWorkerShifts();
                        } else {
                          setState(() {
                            _selectedSegment.clear();
                            _selectedSegment.add('Fortnight');
                            errorMessage = null;
                          });
                          _fetchWorkerShifts();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 150,
                          child: LinearProgressIndicator(),
                        ),
                      )
                    : errorMessage != null
                        ? Center(
                            child: Text(errorMessage!,
                                style: TextStyle(color: colorScheme.primary)))
                        : RefreshIndicator(
                            onRefresh: _fetchWorkerShifts,
                            child: ListView.builder(
itemCount: _selectedSegment.contains('Today')
                                  ? todayShifts.length
                                  : sortedFortnightDates.length,
                              itemBuilder: (context, index) {
                                if (_selectedSegment.contains('Today')) {
                                  return mShiftTile(
                                    date: 'Today',
                                    shiftsForDate: todayShifts,
                                    colorScheme: colorScheme,
                                  );
                                } else {
                                  final date = sortedFortnightDates[index];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 10),
                                      Text(
                                        date,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: colorScheme.secondary),
                                      ),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            groupedFortnightShifts[date]!.length,
                                        itemBuilder: (context, shiftIndex) {
                                          final shift =
                                              groupedFortnightShifts[date]![shiftIndex];
                                          return mShiftTile(
                                            date: date,
                                            shiftsForDate: [shift],
                                            colorScheme: colorScheme,
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ),
              )
            ],
          ),
        );
      },
    );
  }
}
