import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class mShiftTile extends StatelessWidget {
  final String date;
  final List shiftsForDate;
  final ColorScheme colorScheme;

  const mShiftTile(
      {super.key,
      required this.date,
      required this.shiftsForDate,
      required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _buildDateSection(date, shiftsForDate, colorScheme);
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

  Widget _buildDateSection(
      String date, List shiftsForDate, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      '${shift['ClientFirstName'][0]}${shift['ClientLastName'][0]}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          style: TextStyle(
                              fontSize: 14, color: colorScheme.secondary),
                        ),
                        const SizedBox(height: 5),
                        Card(
                          color: colorScheme.primaryContainer.withOpacity(0.5),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${DateFormat('HH:mm').format(DateTime.parse(shift['ShiftStart']).toLocal())} - ${DateFormat('HH:mm').format(DateTime.parse(shift['ShiftEnd']).toLocal())} (${calculateShiftDuration(shift['ShiftStart'], shift['ShiftEnd'])})',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
