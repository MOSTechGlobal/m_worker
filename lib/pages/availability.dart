import 'package:flutter/material.dart';
import 'package:m_worker/utils/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Availability extends StatefulWidget {
  const Availability({super.key});

  @override
  State<Availability> createState() => _AvailabilityState();
}

class _AvailabilityState extends State<Availability> {
  Map _workerData = {};

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  void _fetchAvailability() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final workerID = prefs.getString('workerID');
    final res = await Api.get('getWorkerAvailabilityTimeData/$workerID');
    setState(() {
      _workerData = res['data'][0];
    });
  }

  List<String> _parseTimeSlots(String timeSlots) {
    List<dynamic> timeList = json.decode(timeSlots);
    return timeList.cast<String>();
  }

  Widget _buildAvailabilitySection(String title, Map<String, String> availability, Map<String, String> status, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        ...availability.keys.map((day) {
          List<String> timeSlots = _parseTimeSlots(availability[day]!);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            color: colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Status: ${status[day]}',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  ...timeSlots.map((time) => Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  )),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    Map<String, String> currentAvailability = {
      "CurrentMo": _workerData['CurrentMo'] ?? '[]',
      "CurrentTu": _workerData['CurrentTu'] ?? '[]',
      "CurrentWe": _workerData['CurrentWe'] ?? '[]',
      "CurrentTh": _workerData['CurrentTh'] ?? '[]',
      "CurrentFr": _workerData['CurrentFr'] ?? '[]',
      "CurrentSa": _workerData['CurrentSa'] ?? '[]',
      "CurrentSu": _workerData['CurrentSu'] ?? '[]',
    };
    Map<String, String> currentStatus = {
      "CurrentMo": _workerData['CurrentMoStatus'] ?? '',
      "CurrentTu": _workerData['CurrentTuStatus'] ?? '',
      "CurrentWe": _workerData['CurrentWeStatus'] ?? '',
      "CurrentTh": _workerData['CurrentThStatus'] ?? '',
      "CurrentFr": _workerData['CurrentFrStatus'] ?? '',
      "CurrentSa": _workerData['CurrentSaStatus'] ?? '',
      "CurrentSu": _workerData['CurrentSuStatus'] ?? '',
    };
    Map<String, String> nextAvailability = {
      "NextMo": _workerData['NextMo'] ?? '[]',
      "NextTu": _workerData['NextTu'] ?? '[]',
      "NextWe": _workerData['NextWe'] ?? '[]',
      "NextTh": _workerData['NextTh'] ?? '[]',
      "NextFr": _workerData['NextFr'] ?? '[]',
      "NextSa": _workerData['NextSa'] ?? '[]',
      "NextSu": _workerData['NextSu'] ?? '[]',
    };
    Map<String, String> nextStatus = {
      "NextMo": _workerData['NextMoStatus'] ?? '',
      "NextTu": _workerData['NextTuStatus'] ?? '',
      "NextWe": _workerData['NextWeStatus'] ?? '',
      "NextTh": _workerData['NextThStatus'] ?? '',
      "NextFr": _workerData['NextFrStatus'] ?? '',
      "NextSa": _workerData['NextSaStatus'] ?? '',
      "NextSu": _workerData['NextSuStatus'] ?? '',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchAvailability();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildAvailabilitySection('Current Availability', currentAvailability, currentStatus, colorScheme),
                const SizedBox(height: 20),
                _buildAvailabilitySection('Next Availability', nextAvailability, nextStatus, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
