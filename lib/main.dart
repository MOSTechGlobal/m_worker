import 'dart:developer';

import 'package:alarm/alarm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:m_worker/components/notification/notif_popup.dart';
import 'package:m_worker/login_page.dart';
import 'package:m_worker/pages/account/training_qualification.dart';
import 'package:m_worker/pages/availability.dart';
import 'package:m_worker/pages/documents.dart';
import 'package:m_worker/pages/id_card.dart';
import 'package:m_worker/pages/myaccount.dart';
import 'package:m_worker/pages/shift/shift_root.dart';
import 'package:m_worker/pages/shift/sub_pages/more/end_shift.dart';
import 'package:m_worker/pages/timesheets.dart';
import 'package:m_worker/themes.dart';

import 'auth/auth.dart';
import 'bloc/theme_bloc.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    log("Foreground message received: ${message}");
    handleNotification(message);
  });
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    log("Message opened app: ${message}");
    handleNotification(message);
  });

  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  await dotenv.load(fileName: ".env");
  await Alarm.init();
  Alarm.stop(42);
  runApp(const MyApp());
}

Future<void> handleNotification(RemoteMessage message) async {
  showNotificationDialog(
      message.notification!.title, message.notification!.body, message.data);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("Background message received: ${message}");
  handleNotification(message);
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
            navigatorKey: navigatorKey,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthPage(),
              '/login': (context) => const LoginPage(),
              '/shift_details': (context) => const ShiftRoot(),
              '/account': (context) => const MyAccount(),
              '/training_qualification': (context) =>
                  const TrainingQualification(),
              '/documents': (context) => const Documents(),
              '/availability': (context) => const Availability(),
              '/id_card': (context) => const IdCard(),
              '/timesheets': (context) => const Timesheets(),
              '/end_shift': (context) => const EndShift(),
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
