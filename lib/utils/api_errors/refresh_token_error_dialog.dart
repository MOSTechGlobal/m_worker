import 'package:flutter/material.dart';
import 'package:m_worker/main.dart';

Future<void> showTokenRefreshErrorDialog() async {
  final context = navigatorKey.currentState!.overlay!.context;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Session Expired'),
        content: Text('Your session has expired. Please log in again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login screen or perform re-authentication
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
