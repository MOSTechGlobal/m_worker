import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:m_worker/main.dart';

Future<void> showTokenRefreshErrorDialog() async {
  final context = navigatorKey.currentState!.overlay!.context;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        title: Text('Session Expired',
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
        content: Text('Your session has expired. Please log in again.',
            style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login screen or perform re-authentication
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamed('/login');
            },
            child: Text('OK',
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      );
    },
  );
}
