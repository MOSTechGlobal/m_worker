import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/utils/api.dart';

import '../../bloc/theme_bloc.dart';
import '../../components/shift_detail/shift_detail_3rd_card.dart';

class ShiftDetails extends StatefulWidget {
  final Map<dynamic, dynamic> shift;
  const ShiftDetails({super.key, required this.shift});

  @override
  State<ShiftDetails> createState() => _ShiftDetailsState();
}

class _ShiftDetailsState extends State<ShiftDetails> {
  Map shift = {};
  Map clientData = {};

  @override
  void initState() {
    super.initState();
    shift.clear();
    shift.addAll(widget.shift);
    _fetchClientData(clientID: shift['ClientID']);
  }

  Future<void> _fetchClientData({required int clientID}) async {
    try {
      log('Fetching client data for ClientID: $clientID');
      final response = await Api.get('/getClientDataForVW/$clientID');

      if (response['data'] != null && response['data'].isNotEmpty) {
        log('Client data fetched successfully: ${response['data'][0]}');
        setState(() {
          clientData.clear();
          clientData.addAll(response['data'][0]);
        });
      } else {
        log('No data found for ClientID: $clientID');
      }
    } catch (e) {
      log('Error fetching client data: $e');
    }
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
    return hours > 0
        ? '$hours hr ${minutes > 0 ? '$minutes min' : ''}'
        : '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "${shift['ClientFirstName']} ${shift['ClientLastName']} - ${clientData['PreferredName'] ?? ''}",
                          style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '- (idk)',
                              style: TextStyle(
                                  color: colorScheme.onPrimaryContainer),
                            ),
                            const SizedBox(width: 50),
                            Text(
                              'Age: ${clientData['Age']}',
                              style: TextStyle(
                                fontSize: 16,
                                  color: colorScheme.onPrimaryContainer),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    '${shift['ClientFirstName'][0]}${shift['ClientLastName'][0]}',
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(height: 20),
                shift['ShiftStatus'] == "Not Started" ?
                Card(
                  color: Colors.green,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Start Shift',
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ) : shift['ShiftStatus'] == "In Progress" ?
                Card(
                  color: Colors.yellow,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'End Shift',
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ) : shift['ShiftStatus'] == "Completed" ?
                Card(
                  color: Colors.red,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Shift Completed',
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ) : Card(
                  color: colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Shift Status: ',
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 16),
                        ),
                        Text(
                          shift['ShiftStatus'],
                          style: TextStyle(
                              color: colorScheme.primary, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Shift Date: ',
                              style: TextStyle(
                                  color: colorScheme.onSurface, fontSize: 16),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(DateTime.parse(shift['ShiftStart'])),
                              style: TextStyle(
                                  color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Start Time: ',
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16),
                                ),
                                Text(
                                  DateFormat('hh:mm aa').format(
                                      DateTime.parse(shift['ShiftStart'])
                                          .toLocal()),
                                  style: TextStyle(
                                      color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'End Time: ',
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16),
                                ),
                                Text(
                                  DateFormat('hh:mm aa').format(
                                      DateTime.parse(shift['ShiftEnd'])
                                          .toLocal()),
                                  style: TextStyle(
                                      color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Duration',
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16),
                                ),
                                Text(
                                  calculateShiftDuration(
                                      shift['ShiftStart'], shift['ShiftEnd']),
                                  style: TextStyle(
                                      color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShiftDetails3rdCard(
                          title: 'Case Manager: ',
                          subtitle: clientData['CaseManager'] ?? '-',
                        ),
                        ShiftDetails3rdCard(
                          title: 'Tasks Required: ',
                          subtitle: shift['ServiceDescription'] ?? '-',
                        ),
                        ShiftDetails3rdCard(
                          title: 'Location: ',
                          subtitle: '${clientData['AddressLine1'] ?? ''} ${clientData['AddressLine2'] ?? ''} ${clientData['Suburb'] ?? ''} ${clientData['Postcode'] ?? ''}',
                        ),
                        ShiftDetails3rdCard(
                          title: 'DOB: ',
                          subtitle: clientData['DOB'] ?? '',
                        ),
                      ],
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
