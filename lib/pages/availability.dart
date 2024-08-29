import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/api.dart';
import '../utils/prefs.dart'; // Make sure to import this package

class Availability extends StatefulWidget {
  const Availability({super.key});

  @override
  State<Availability> createState() => _AvailabilityState();
}

class _AvailabilityState extends State<Availability> {
  Map<String, dynamic> _workerData = {};
  List _availabilityRange = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  void _fetchAvailability() async {
    final workerID = await Prefs.getWorkerID();
    final res =
        await Api.get('getDetailedWorkerAvailabilityTimeData/$workerID');
    final res0 = await Api.get('getWorkerAvailabilityTimeData/$workerID');
    setState(() {
      _workerData = res; // Assuming res contains the full response with 'data'
      _availabilityRange = res0['data'];
    });
  }

  List<String> _parseTimeSlots(List<dynamic> timeSlots) {
    return timeSlots.cast<String>();
  }

  void _editAvailability(String dayKey) {
    setState(() {
      _isEditing = true;
    });
    // Show a dialog for editing availability
    showDialog(
      context: context,
      builder: (context) {
        return AvailabilityEditDialog(
          initialAvailability: _workerData['data']
              .firstWhere((item) => item['date'] == dayKey)['time'],
          onSave: (updatedAvailability) {
            setState(() {
              // Update the specific day entry
              var index = _workerData['data']
                  .indexWhere((item) => item['date'] == dayKey);
              if (index != -1) {
                _workerData['data'][index]['time'] = updatedAvailability;
              }
              _isEditing = false;
            });
          },
        );
      },
    );
  }

  void _sameForNextFortnight() async {
    // Assuming 'FromDate' and 'ToDate' are stored in _workerData
    log(_availabilityRange.toString());
    DateTime fromDate = DateTime.parse(_availabilityRange[0]['FromDate']);
    DateTime toDate = DateTime.parse(_availabilityRange[0]['ToDate']);

    final newFromDate = fromDate.add(const Duration(days: 14));
    final newToDate = toDate.add(const Duration(days: 14));

    // Update _workerData with the new date range
    setState(() {
      _workerData['FromDate'] = DateFormat('yyyy-MM-dd').format(newFromDate);
      _workerData['ToDate'] = DateFormat('yyyy-MM-dd').format(newToDate);
    });

    // Optionally, save the updated data to the server
    final workerID = await Prefs.getWorkerID();
    //await Api.put('updateWorkerAvailabilityData/$workerID', data: _workerData);
    log('$newFromDate, $newToDate');
  }

  Widget _buildAvailabilitySection(
      List<dynamic> availability, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        ...availability.map((dayData) {
          List<String> timeSlots = _parseTimeSlots(dayData['time']);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            color: colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${dayData['day']} - ${dayData['date']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (!_isEditing)
                        IconButton(
                          icon: Icon(Icons.edit, color: colorScheme.primary),
                          onPressed: () => _editAvailability(dayData['date']),
                        ),
                    ],
                  ),
                  Text(
                    'Status: ${dayData['status']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  ...timeSlots.map(
                    (time) => Text(
                      time,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.forward),
            onPressed: _sameForNextFortnight,
          )
        ],
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
                _buildAvailabilitySection(
                    _workerData['data'] ?? [], colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AvailabilityEditDialog extends StatefulWidget {
  final List<dynamic> initialAvailability;
  final ValueChanged<List<dynamic>> onSave;

  const AvailabilityEditDialog({
    required this.initialAvailability,
    required this.onSave,
    super.key,
  });

  @override
  _AvailabilityEditDialogState createState() => _AvailabilityEditDialogState();
}

class _AvailabilityEditDialogState extends State<AvailabilityEditDialog> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialAvailability
        .map((timeSlot) => TextEditingController(text: timeSlot))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Availability'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._controllers.map((controller) {
            return TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Time Slot'),
            );
          }),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _controllers.add(TextEditingController());
              });
            },
            child: const Text('Add Time Slot'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final updatedAvailability =
                _controllers.map((controller) => controller.text).toList();
            widget.onSave(updatedAvailability);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
