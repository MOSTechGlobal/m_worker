import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/bloc/theme_bloc.dart';

class ShiftProfile extends StatelessWidget {
  final Map clientmWorkerData;
  const ShiftProfile({super.key, required this.clientmWorkerData});

  @override
  Widget build(BuildContext context) {
    log(clientmWorkerData.toString());
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.primaryContainer,
          scrollable: true,
          content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 10),
              ListTile(
                title: Text('Shift Alert', style: TextStyle(color: colorScheme.tertiary, fontSize: 16)),
                subtitle: Text(clientmWorkerData['ShiftAlert'] ?? '-', style: TextStyle(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: Text('Client Profile', style: TextStyle(color: colorScheme.tertiary, fontSize: 16)),
                subtitle: Text(clientmWorkerData['ClientProfile'] ?? '-', style: TextStyle(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: Text('Identified Risks', style: TextStyle(color: colorScheme.tertiary, fontSize: 16)),
                subtitle: Text(clientmWorkerData['IdentifiedRisks'] ?? '-', style: TextStyle(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: Text('Access To Residency Notes', style: TextStyle(color: colorScheme.tertiary, fontSize: 16)),
                subtitle: Text(clientmWorkerData['AccesstoResidencyNotes'] ?? '-', style: TextStyle(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: Text('Living Arrangements', style: TextStyle(color: colorScheme.tertiary, fontSize: 16)),
                subtitle: Text(clientmWorkerData['LivingArrangements'] ?? '-', style: TextStyle(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }
}

void showShiftProfileDialog(BuildContext context, Map clientmWorkerData) {
  showDialog(
    context: context,
    builder: (context) {
      return ShiftProfile(clientmWorkerData: clientmWorkerData);
    },
  );
}
