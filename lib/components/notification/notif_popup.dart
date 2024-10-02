import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/main.dart';

import '../../bloc/theme_bloc.dart';

Future<void> showNotificationDialog(title, body, data, context) async {
  showDialog(
    context: context,
    builder: (context) {
      return BlocBuilder<ThemeBloc, ThemeMode>(
        builder: (context, state) {
          final colorScheme = Theme.of(context).colorScheme;
          return Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all(colorScheme.primary),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK',
                        style: TextStyle(color: colorScheme.onPrimary)),
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
