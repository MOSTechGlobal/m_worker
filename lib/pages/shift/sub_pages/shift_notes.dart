import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../bloc/theme_bloc.dart';

class ShiftNotes extends StatelessWidget {
  final Map shift;
  final Map clientmWorkerData;

  const ShiftNotes(
      {super.key, required this.shift, required this.clientmWorkerData});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          children: [
            const SizedBox(height: 16),
            shift['AppNote'].isEmpty
                ? Center(
                    child: Text('No notes',
                        style: TextStyle(color: colorScheme.error)),
                  )
                : Card(
                    color: colorScheme.primaryContainer,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shift["AppNote"],
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary)),
                            const SizedBox(height: 8),
                            Text(
                              shift["MakerUser"] ?? '',
                              style: TextStyle(
                                color: colorScheme.secondary,
                                fontSize: 12,
                              ),
                            ),
                            shift["MakerDate"] != null
                                ? Text(
                                    DateFormat('dd/MM/yyyy hh:mm a').format(
                                        DateTime.parse(shift["MakerDate"])),
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontSize: 12,
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
            clientmWorkerData["ShiftAlert"] != null
                ? Card(
                    color: colorScheme.primaryContainer,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('[Shift Alert]',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.error)),
                            Text(clientmWorkerData["ShiftAlert"],
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary)),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
          ],
        );
      },
    );
  }
}
