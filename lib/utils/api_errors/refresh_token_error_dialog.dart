import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:m_worker/main.dart';

Future<void> showTokenRefreshErrorDialog() async {
  final context = navigatorKey.currentState!.overlay!.context;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title:
            const Text('Session Expired', style: TextStyle(color: Colors.red)),
        content: const Text('Your session has expired. Please log in again.',
            style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login screen or perform re-authentication
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamed('/login');
            },
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}
