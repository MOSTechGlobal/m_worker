import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:m_worker/pages/availability.dart';
import 'package:m_worker/pages/documents.dart';
import 'package:m_worker/pages/id_card.dart';
import 'package:m_worker/pages/myaccount.dart';
import 'package:m_worker/pages/account/training_qualification.dart';
import 'package:m_worker/pages/shift/shift_root.dart';
import 'package:m_worker/themes.dart';
import 'auth/auth.dart';
import 'bloc/theme_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeBloc>(
      create: (context) => ThemeBloc(),
      child: BlocBuilder<ThemeBloc, ThemeMode>(
        builder: (context, state) {
          return MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthPage(),
              '/shift_details': (context) => const ShiftRoot(),
              '/account': (context) => const MyAccount(),
              '/training_qualification': (context) => const TrainingQualification(),
              '/documents': (context) => const Documents(),
              '/availability': (context) => const Availability(),
              '/id_card': (context) => const IdCard(),
            },
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            themeMode: state,
            darkTheme: darkTheme,
          );
        },
      ),
    );
  }
}
