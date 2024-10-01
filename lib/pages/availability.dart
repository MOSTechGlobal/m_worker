import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/utils/prefs.dart';

import '../bloc/theme_bloc.dart';
import '../utils/api.dart';

class WorkerAvailability extends StatefulWidget {
  const WorkerAvailability({super.key});

  @override
  _WorkerAvailabilityState createState() => _WorkerAvailabilityState();
}

class _WorkerAvailabilityState extends State<WorkerAvailability> {
  int workerId = 0;

  List<String> availability = List.filled(14, 'Unavailable');
  List<List<String>> partialAvailability = List.generate(14, (_) => []);
  bool bulkMode = false;
  List<int> selectedDays = [];
  String? copiedAvailability;
  bool disableSection = false;
  int? timePickerIndex;

  TimeOfDay? pickedStartTime = null;
  TimeOfDay? pickedEndTime = null;

  bool _isLoading = false;

  List<Map<String, dynamic>> selectedTimeSlots = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    int? workerId = await Prefs.getWorkerID();
    setState(() {
      this.workerId = workerId!; // Make sure to check if workerId is null
      _isLoading = true;
    });

    try {
      final response = await Api.get('getWorkerAvailabilityTimeData/$workerId');

      // Log the response
      log('Response: $response');

      if (response['success'] == true) {
        final availabilityData = response['data'][0];

        setState(() {
          // Set availability for the current week
          availability[0] = availabilityData['CurrentMoStatus'];
          availability[1] = availabilityData['CurrentTuStatus'];
          availability[2] = availabilityData['CurrentWeStatus'];
          availability[3] = availabilityData['CurrentThStatus'];
          availability[4] = availabilityData['CurrentFrStatus'];
          availability[5] = availabilityData['CurrentSaStatus'];
          availability[6] = availabilityData['CurrentSuStatus'];

          // Set availability for the next week
          availability[7] = availabilityData['NextMoStatus'];
          availability[8] = availabilityData['NextTuStatus'];
          availability[9] = availabilityData['NextWeStatus'];
          availability[10] = availabilityData['NextThStatus'];
          availability[11] = availabilityData['NextFrStatus'];
          availability[12] = availabilityData['NextSaStatus'];
          availability[13] = availabilityData['NextSuStatus'];

          // Function to handle availability for partial times
          List<String> parseAvailability(dynamic data) {
            if (data is List) {
              return List<String>.from(data);
            } else if (data is String) {
              try {
                // Decode the JSON string to extract availability
                List<dynamic> decoded = jsonDecode(data);
                if (decoded.isNotEmpty && decoded[0] is String) {
                  return [decoded[0]]; // Return the first element as a list
                }
              } catch (e) {
                log("Error parsing availability data: $e");
                // Handle potential errors or return an empty list if parsing fails
                return [];
              }
            }
            return [];
          }

          // If there are partial times, fill partialAvailability
          partialAvailability[0] =
              parseAvailability(availabilityData['CurrentMo']);
          partialAvailability[1] =
              parseAvailability(availabilityData['CurrentTu']);
          partialAvailability[2] =
              parseAvailability(availabilityData['CurrentWe']);
          partialAvailability[3] =
              parseAvailability(availabilityData['CurrentTh']);
          partialAvailability[4] =
              parseAvailability(availabilityData['CurrentFr']);
          partialAvailability[5] =
              parseAvailability(availabilityData['CurrentSa']);
          partialAvailability[6] =
              parseAvailability(availabilityData['CurrentSu']);
          partialAvailability[7] =
              parseAvailability(availabilityData['NextMo']);
          partialAvailability[8] =
              parseAvailability(availabilityData['NextTu']);
          partialAvailability[9] =
              parseAvailability(availabilityData['NextWe']);
          partialAvailability[10] =
              parseAvailability(availabilityData['NextTh']);
          partialAvailability[11] =
              parseAvailability(availabilityData['NextFr']);
          partialAvailability[12] =
              parseAvailability(availabilityData['NextSa']);
          partialAvailability[13] =
              parseAvailability(availabilityData['NextSu']);
        });
      } else {
        // Handle cases where the API indicates a failure
        log('Failed to fetch availability data: ${response['error']}');
      }
    } catch (error) {
      log('Error fetching availability: $error');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading regardless of success or failure
      });
    }
  }

  void showTimePickerDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Select Time Range",
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const Divider(),
                    // Time From
                    ListTile(
                      title: Text(
                        "From",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      trailing: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: TextButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              barrierDismissible: false,
                              initialTime: pickedStartTime ?? TimeOfDay.now(),
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(alwaysUse24HourFormat: false),
                                  child: child!,
                                );
                              },
                            );

                            if (time != null) {
                              setState(() {
                                pickedStartTime =
                                    time; // Update pickedStartTime
                              });
                              log('Selected time [FROM]: ${pickedStartTime!.format(context)}'); // Log formatted time
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please select a valid time.')),
                              );
                            }
                          },
                          child: Text(
                            pickedStartTime != null
                                ? pickedStartTime!.format(
                                    context) // Display the selected time
                                : 'Select Time',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time To
                    ListTile(
                      title: Text(
                        "To",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      trailing: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: TextButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: pickedStartTime ?? TimeOfDay.now(),
                              barrierDismissible: false,
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(alwaysUse24HourFormat: false),
                                  child: child!,
                                );
                              },
                            );

                            if (time != null) {
                              setState(() {
                                pickedEndTime = time;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please select a valid time.')),
                              );
                            }
                          },
                          child: Text(
                            pickedEndTime != null
                                ? pickedEndTime!.format(context)
                                : 'Select Time',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Check if both start and end times are selected before saving
                            if (pickedStartTime != null &&
                                pickedEndTime != null) {
                              setState(() {
                                // Store the selected time range in the state
                                partialAvailability[index] = [
                                  '${pickedStartTime!.hourOfPeriod.toString().padLeft(2, '0')}:${pickedStartTime!.minute.toString().padLeft(2, '0')} ${pickedStartTime!.period == DayPeriod.am ? 'AM ' : 'PM'} - ${pickedEndTime!.hourOfPeriod.toString().padLeft(2, '0')}:${pickedEndTime!.minute.toString().padLeft(2, '0')} ${pickedEndTime!.period == DayPeriod.am ? 'AM' : 'PM'}',
                                ];
                                availability[index] =
                                    'As Below'; // Update availability status
                              });
                              Navigator.pop(context); // Close the dialog
                              setState(() {
                                pickedStartTime = null;
                                pickedEndTime = null;
                              });
                            } else {
                              // Notify the user to select both times
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please select both time fields.')),
                              );
                            }
                          },
                          child: const Text("Save"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void handleAvailabilityChange(int index, String status) {
    setState(() {
      availability[index] = status;
    });
  }

  void handlePartialAvailability(int index) {
    setState(() {
      timePickerIndex = index;
    });
    showTimePickerDialog(index);
  }

// Function to convert TimeOfDay to String
  String formatTimeOfDay(dynamic time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<void> handleSaveAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await Api.put('updateWorkerAvailabilityTimeData/$workerId', {
        'data': {
          'CurrentMoStatus': availability[0],
          'CurrentTuStatus': availability[1],
          'CurrentWeStatus': availability[2],
          'CurrentThStatus': availability[3],
          'CurrentFrStatus': availability[4],
          'CurrentSaStatus': availability[5],
          'CurrentSuStatus': availability[6],
          'NextMoStatus': availability[7],
          'NextTuStatus': availability[8],
          'NextWeStatus': availability[9],
          'NextThStatus': availability[10],
          'NextFrStatus': availability[11],
          'NextSaStatus': availability[12],
          'NextSuStatus': availability[13],
          'CurrentMo': partialAvailability[0],
          'CurrentTu': partialAvailability[1],
          'CurrentWe': partialAvailability[2],
          'CurrentTh': partialAvailability[3],
          'CurrentFr': partialAvailability[4],
          'CurrentSa': partialAvailability[5],
          'CurrentSu': partialAvailability[6],
          'NextMo': partialAvailability[7],
          'NextTu': partialAvailability[8],
          'NextWe': partialAvailability[9],
          'NextTh': partialAvailability[10],
          'NextFr': partialAvailability[11],
          'NextSa': partialAvailability[12],
          'NextSu': partialAvailability[13],
        }
      });

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability saved successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save availability.')),
        );
      }
    } catch (error) {
      log('Error saving availability: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save availability.')),
      );
    } finally {
      fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.now();

    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Worker Availability',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            iconTheme: IconThemeData(color: colorScheme.onSurface),
            actions: [
              IconButton(
                onPressed: handleSaveAvailability,
                icon: const Icon(Icons.save),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 50,
                          child: LinearProgressIndicator(),
                        ),
                      )
                    : Expanded(
                        child: RefreshIndicator(
                          onRefresh: fetchData,
                          child: ListView.builder(
                            itemCount: 14,
                            itemBuilder: (context, index) {
                              final dayDate =
                                  startDate.add(Duration(days: index));
                              final dayFormatted =
                                  DateFormat('EEEEE').format(dayDate);
                              final isToday =
                                  DateFormat('yyyy-MM-dd').format(dayDate) ==
                                      DateFormat('yyyy-MM-dd')
                                          .format(DateTime.now());

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Card(
                                  color: availability[index] == 'Available'
                                      ? Colors.green.withOpacity(0.7)
                                      : availability[index] == 'UNAvailable'
                                          ? Colors.red.withOpacity(0.7)
                                          : Colors.orange.withOpacity(0.7),
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isToday)
                                          Center(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.all(
                                                        Radius.circular(4)),
                                                color: colorScheme.surface
                                                    .withOpacity(0.7),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Text(
                                                  'Today',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: colorScheme
                                                          .onSurface),
                                                ),
                                              ),
                                            ),
                                          ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              dayFormatted,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                            Text(
                                                DateFormat('dd/MM/yyyy')
                                                    .format(dayDate),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            color:
                                                Colors.white.withOpacity(0.1),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              TextButton(
                                                onPressed: () =>
                                                    handleAvailabilityChange(
                                                        index, 'Available'),
                                                style: TextButton.styleFrom(
                                                    backgroundColor: availability[
                                                                    index]
                                                                .toLowerCase() ==
                                                            'available'
                                                        ? Colors.green
                                                        : null),
                                                child: const Text('Available',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    handleAvailabilityChange(
                                                        index, 'UNAvailable'),
                                                style: TextButton.styleFrom(
                                                    backgroundColor: availability[
                                                                    index]
                                                                .toLowerCase() ==
                                                            'unavailable'
                                                        ? Colors.red
                                                        : null),
                                                child: const Text('Unavailable',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    handlePartialAvailability(
                                                        index),
                                                style: TextButton.styleFrom(
                                                    backgroundColor: availability[
                                                                    index]
                                                                .toLowerCase() ==
                                                            'as below'
                                                        ? Colors.orange
                                                        : null),
                                                child: const Text('Partial',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (availability[index] == 'As Below' &&
                                            partialAvailability[index]
                                                .isNotEmpty)
                                          Center(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                textAlign: TextAlign.center,
                                                partialAvailability[index][0],
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
