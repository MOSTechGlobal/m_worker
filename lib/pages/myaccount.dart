import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/components/button.dart';
import 'package:m_worker/utils/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({super.key});

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  late bool showWeather = false;

  final _workerData = {};

  @override
  void initState() {
    _fetchPrefs();
    _fetchWorkerData();
    super.initState();
  }

  void _fetchWorkerData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final workerID = prefs.getString('workerID');
    final res = await Api.get('getWorkerMasterData/$workerID');
    setState(() {
      _workerData.addAll(res['data'][0]);
    });
  }

  void _fetchPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showWeather = prefs.getBool('showWeather') ?? true;
    });
  }

  void _savePrefs(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showWeather', value);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: colorScheme.onSurface),
            title: Text('My Account',
                style: TextStyle(color: colorScheme.onSurface)),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.primary,
                  child: Icon(Icons.person,
                      size: 50, color: colorScheme.onPrimary),
                ),
                const SizedBox(height: 20),
                Text(
                  '${_workerData['FirstName'] ?? ''} ${_workerData['LastName'] ?? ''}',
                  style: TextStyle(
                    fontSize: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Company Name',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 30),
                MButton(
                  colorScheme: colorScheme,
                  label: 'Change Profile Picture',
                  onPressed: () {},
                ),
                const SizedBox(height: 10),
                MButton(
                  colorScheme: colorScheme,
                  label: 'Enable Biometrics',
                  onPressed: () {},
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Card(
                    color: colorScheme.secondaryContainer,
                    child: ListTile(
                      title: Text(
                        'Show Weather info.',
                        style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 14),
                      ),
                      trailing: Switch(
                        value: showWeather,
                        onChanged: (value) {
                          setState(() {
                            showWeather = value;
                            _savePrefs(value);
                          });
                        },
                        activeColor: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                Text(
                  'changes will take effect after restart',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
