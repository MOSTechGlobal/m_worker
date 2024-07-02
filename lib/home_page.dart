import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/utils/api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<dynamic> shifts = [];
  late dynamic workerData = [];
  String? errorMessage;
  bool isLoading = true;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _fetchWorkerShifts() async {
    final user = FirebaseAuth.instance.currentUser!.email;
    try {
      final worker = await Api.get('getWorkerMasterDataByEmail/$user');
      final workerShifts =
          await Api.get('getShiftMainDataByWorkerID/${worker['data']['WorkerID']}');
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        try {
          await Api.post('upsertFCMToken', {
            'WorkerID': worker['data']['WorkerID'],
            'FCMToken': fcmToken,
          });
        } catch (e) {
          log('Error inserting FCM token: $e');
        }
      }
      setState(() {
        shifts = workerShifts['data'] ?? [];
        workerData = worker['data'] ?? [];
      });
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

  String calculateShiftDuration(String shiftStart, String shiftEnd) {
    final start =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(shiftStart, true);
    var end = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(shiftEnd, true);

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    final duration = end.difference(start);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hours hours $minutes minutes';
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toUtc();

    final futureShifts = shifts.where((shift) {
      final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .parse(shift['ShiftStart'], true);
      return isSameDay(shiftStart, today) || shiftStart.isAfter(today);
    }).toList();

    final groupedShifts = groupBy(futureShifts, (shift) {
      final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .parse(shift['ShiftStart'], true);
      return DateFormat('yyyy-MM-dd').format(shiftStart);
    });

    // Sort dates in ascending order and as per time
    final sortedDates = groupedShifts.keys.toList()
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
            title: const Text('My Shifts'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _signOut,
              ),
            ],
          ),
          body: isLoading
              ? const Center(
                  child: SizedBox(
                  width: 150,
                  child: LinearProgressIndicator(),
                ))
              : errorMessage != null
                  ? Center(
                      child: Text(errorMessage!,
                          style: TextStyle(color: colorScheme.primary)))
                  : RefreshIndicator(
                      onRefresh: _fetchWorkerShifts,
                      child: ListView.builder(
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final shiftsForDate = groupedShifts[date]!;
                          return _buildDateSection(
                              date, shiftsForDate, colorScheme);
                        },
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildDateSection(
      String date, List shiftsForDate, ColorScheme colorScheme) {
    final weekday = DateFormat('EEEE').format(DateTime.parse(date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '$weekday, ${DateFormat('d MMMM').format(DateTime.parse(date))}',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.tertiary.withOpacity(0.7)),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shiftsForDate.length,
          itemBuilder: (context, shiftIndex) {
            final shift = shiftsForDate[shiftIndex];
            return _buildShiftCard(shift, colorScheme);
          },
        ),
      ],
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shift, ColorScheme colorScheme) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Card(
          color: colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('HH:mm').format(DateTime.parse(shift['ShiftStart']).toLocal())} - ${DateFormat('HH:mm').format(DateTime.parse(shift['ShiftEnd']).toLocal())} (${calculateShiftDuration(shift['ShiftStart'], shift['ShiftEnd'])})',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary),
                ),
                const SizedBox(height: 5),
                Text(
                  '${shift['ClientFirstName']} ${shift['ClientLastName']}',
                  style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.secondary),
                ),
                const SizedBox(height: 5),
                Text(
                  '${shift['ServiceDescription']}',
                  style: TextStyle(fontSize: 14, color: colorScheme.secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
