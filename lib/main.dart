import 'dart:developer';

import 'package:alarm/alarm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:m_worker/components/notification/notif_popup.dart';
import 'package:m_worker/login_page.dart';
import 'package:m_worker/pages/account/training_qualification.dart';
import 'package:m_worker/pages/all_shifts/all_shift_details/sub_pages/more/end_shift.dart';
import 'package:m_worker/pages/all_shifts/all_shifts_page.dart';
import 'package:m_worker/pages/availability.dart';
import 'package:m_worker/pages/documents.dart';
import 'package:m_worker/pages/id_card.dart';
import 'package:m_worker/pages/myaccount.dart';
import 'package:m_worker/pages/shift/shift_root.dart';
import 'package:m_worker/pages/shift/sub_pages/more/client_documents.dart';
import 'package:m_worker/pages/shift/sub_pages/more/client_expenses/add_client_expenses.dart';
import 'package:m_worker/pages/shift/sub_pages/more/client_expenses/client_expenses.dart';
import 'package:m_worker/pages/shift/sub_pages/more/end_split_shift.dart';
import 'package:m_worker/pages/timesheets.dart';
import 'package:m_worker/themes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth.dart';
import 'bloc/theme_bloc.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _requestNotificationPermission();

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  await dotenv.load(fileName: ".env");
  await Alarm.init();
  Alarm.stop(42);

  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('showWeather')) {
    await prefs.setBool('showWeather', true);
  }

  runApp(const MyApp());
}

Future<void> _requestNotificationPermission() async {
  final status = await Permission.notification.status;

  if (!status.isGranted) {
    // Request permission
    await Permission.notification.request();
  }
}

Future<void> handleNotification(RemoteMessage message) async {
  showNotificationDialog(message.notification!.title,
      message.notification!.body, message.data, navigatorKey.currentContext!);
}

Future<void> handleBackgroundNotification(RemoteMessage message) async {
  // Check if the notification data is available
  if (message.notification != null) {
    // Extract title and body from the message
    String? title = message.notification!.title;
    String? body = message.notification!.body;

    // Show the notification using the local notifications plugin
    await _showNotification(title, body);
  }
}

// Function to show the notification
Future<void> _showNotification(String? title, String? body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'm-w-bg', // Replace with your channel ID
    'Mostech Notifs', // Replace with your channel name
    channelDescription:
        'General Channel to get Notifs', // Replace with your channel description
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    showWhen: false,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("Background message received: $message");
  handleBackgroundNotification(message);
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
              '/all_shifts_page': (context) => const AllShiftPage(),
              '/availability': (context) => const WorkerAvailability(),
              '/id_card': (context) => const IdCard(),
              '/timesheets': (context) => const Timesheets(),
              '/end_shift': (context) => const EndShift(),
              '/end_split_shift': (context) => const EndSplitShift(),
              '/shift_more_documents': (context) => const ClientDocuments(),
              '/shift_more_expenses': (context) => const Expenses(),
              '/shift_more_client_expenses/add': (context) =>
                  const AddExpense(),
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
