import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/pages/shift/sub_pages/shift_incident.dart';

import '../../../bloc/theme_bloc.dart';

void showShiftIncident(BuildContext context, String clientID, String workerID) {
  final incidentData = {
    'ClientInvolved': false,
    'WorkerInvolved': false,
    'PropertyDamage': false,
    'Level': 'Hazard/Risk',
    'Date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
    'Time': TimeOfDay.now().format(context),
    'Summary': '',
  };

  final dateController =
      TextEditingController(text: incidentData['Date'].toString());
  final timeController =
      TextEditingController(text: incidentData['Time'].toString());

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
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Incident',
                            style: TextStyle(
                                color: colorScheme.tertiary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            title: const Text('Client Involved'),
                            value: incidentData['ClientInvolved'] as bool?,
                            onChanged: (bool? value) {
                              setState(() {
                                incidentData['ClientInvolved'] = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Worker Involved'),
                            value: incidentData['WorkerInvolved'] as bool?,
                            onChanged: (bool? value) {
                              setState(() {
                                incidentData['WorkerInvolved'] = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Property Damage'),
                            value: incidentData['PropertyDamage'] as bool?,
                            onChanged: (bool? value) {
                              setState(() {
                                incidentData['PropertyDamage'] = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Level',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            style: TextStyle(
                              color: colorScheme.primary,
                            ),
                            value: incidentData['Level'] as String?,
                            items: [
                              'Hazard/Risk',
                              'Level 1',
                              'Level 2',
                              'Level 3',
                              'Near Miss'
                            ]
                                .map((level) => DropdownMenuItem(
                                      value: level,
                                      child: Text(level),
                                    ))
                                .toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                incidentData['Level'] = newValue!;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                  ),
                                  onTapOutside: (_) {
                                    FocusScope.of(context).unfocus();
                                  },
                                  decoration:
                                      const InputDecoration(labelText: 'Date'),
                                  controller: dateController,
                                  keyboardType: TextInputType.none,
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );
                                    if (pickedDate != null) {
                                      final formattedDate =
                                          DateFormat('dd/MM/yyyy')
                                              .format(pickedDate);
                                      setState(() {
                                        incidentData['Date'] = formattedDate;
                                        dateController.text = formattedDate;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                  ),
                                  onTapOutside: (_) {
                                    FocusScope.of(context).unfocus();
                                  },
                                  controller: timeController,
                                  decoration:
                                      const InputDecoration(labelText: 'Time'),
                                  keyboardType: TextInputType.none,
                                  onTap: () async {
                                    TimeOfDay? pickedTime =
                                        await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (pickedTime != null) {
                                      final formattedTime =
                                          pickedTime.format(context);
                                      setState(() {
                                        incidentData['Time'] = formattedTime;
                                        timeController.text = formattedTime;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            style: TextStyle(
                              color: colorScheme.primary,
                            ),
                            onTapOutside: (_) {
                              FocusScope.of(context).unfocus();
                            },
                            decoration:
                                const InputDecoration(labelText: 'Summary'),
                            maxLines: 3,
                            onChanged: (value) {
                              setState(() {
                                incidentData['Summary'] = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.onPrimary,
                                  backgroundColor: colorScheme.primary,
                                ),
                                child: const Text('Create'),
                                onPressed: () {
                                  log(incidentData.toString());
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IncidentFormScreen(
                                          clientID: clientID,
                                          workerID: workerID,
                                          prefilledInfo: incidentData),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
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
