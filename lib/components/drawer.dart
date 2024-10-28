import 'package:flutter/material.dart';
import 'package:m_worker/home_page.dart';
import 'package:m_worker/pages/account/training_qualification.dart';
import 'package:m_worker/pages/all_shifts/all_shifts_page.dart';
import 'package:m_worker/pages/availability.dart';
import 'package:m_worker/pages/documents.dart';
import 'package:m_worker/pages/id_card.dart';
import 'package:m_worker/pages/myaccount.dart';
import 'package:m_worker/pages/timesheets.dart';

class mDrawer extends StatelessWidget {
  final ColorScheme colorScheme;
  final Function onSignOut;

  const mDrawer(
      {super.key, required this.colorScheme, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'mWorker',
                      style: TextStyle(
                        fontSize: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.logout, color: colorScheme.error),
                      onPressed: () {
                        onSignOut();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('My Account'),
                  onTap: () {
                    _slideRoute(context, '/account');
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Shifts'),
            onTap: () {
              _slideRoute(context, '/all_shifts_page');
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time_rounded),
            title: const Text('Timesheets'),
            onTap: () {
              _slideRoute(context, '/timesheets');
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_present),
            title: const Text('Documents'),
            onTap: () {
              _slideRoute(context, '/documents');
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_busy),
            title: const Text('Leave Requests'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Incidents'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Forms'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: const Text('Availability'),
            onTap: () {
              Navigator.pushNamed(context, '/availability');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_box),
            title: const Text('Id Card'),
            onTap: () {
              _slideRoute(context, '/id_card');
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Communicate',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.new_releases),
            title: const Text('Invitations'),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Group Messages'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble),
            title: const Text('Private Messages'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.call),
            title: const Text('Call Office'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.grade),
            title: const Text('Training / Qualification'),
            onTap: () {
              _slideRoute(context, '/training_qualification');
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Compliance'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
    );
  }

  void _slideRoute(BuildContext context, String routeName) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _getRouteWidget(context, routeName),
        // transitionsBuilder: (context, animation, secondaryAnimation, child) {
        //   const begin = Offset(1.0, 0.0);
        //   const end = Offset.zero;
        //   const curve = Curves.ease;
        //
        //   var tween =
        //       Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        //
        //   return SlideTransition(
        //     position: animation.drive(tween),
        //     child: child,
        //   );
        // },
      ),
    );
  }

  Widget _getRouteWidget(BuildContext context, String routeName) {
    switch (routeName) {
      case '/account':
        return const MyAccount();
      case '/training_qualification':
        return const TrainingQualification();
      case '/documents':
        return const Documents();
      case '/availability':
        return const WorkerAvailability();
      case '/id_card':
        return const IdCard();
      case '/timesheets':
        return const Timesheets();
      case '/all_shifts_page':
        return const AllShiftPage();
      case '/':
        return const HomePage(); // Replace with your actual widget for the home page
      default:
        return const HomePage(); // Default widget if the route is not recognized
    }
  }
}
