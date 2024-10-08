import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/components/button.dart';
import 'package:m_worker/utils/api.dart';
import 'package:s3_storage/s3_storage.dart';

import '../utils/prefs.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({super.key});

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  late bool _showWeather = false;
  late bool _biometricsEnabled = false;

  late var _companyName = '';
  late var _pfp = '';

  final _workerData = {};
  final _auth = LocalAuthentication();

  @override
  void initState() {
    _fetchPrefs();
    _fetchWorkerData();
    _getPfp();
    super.initState();
  }

  void _fetchWorkerData() async {
    final workerID = await Prefs.getWorkerID();
    final res = await Api.get('getWorkerMasterData/$workerID');
    setState(() {
      _workerData.addAll(res['data'][0]);
    });
    log('Worker data: $_workerData');
  }

  void _fetchPrefs() async {
    final company = await Prefs.getCompanyName();
    final showWeather = await Prefs.getShowWeather();
    final biometricsEnabled = await Prefs.getBiometricsEnabled();
    setState(() {
      _companyName = company ?? '';
      _showWeather = showWeather;
      _biometricsEnabled = biometricsEnabled;
    });
  }

  void _savePrefs(bool value, type) async {
    if (type == 'showWeather') {
      await Prefs.setShowWeather(value);
    } else {
      await Prefs.setBiometricsEnabled(value);
    }
  }

  Future<void> _authenticate() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        log('Biometric authentication not available.');
        setState(() {
          _biometricsEnabled = false;
        });
        // show snackbar to show error
        const snackBar = SnackBar(
          content: Text('Biometric authentication not available.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }
      log('Available biometrics: $availableBiometrics');
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        log('Biometric authentication not available.');
        setState(() {
          _biometricsEnabled = false;
        });
        const snackBar = SnackBar(
          content: Text('Biometric authentication not available.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }
      final isAuthenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to enable biometrics',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (isAuthenticated) {
        setState(() {
          _biometricsEnabled = true;
        });
        await Prefs.setBiometricsEnabled(true);
        log('Authenticated');
      } else {
        log('Not authenticated');
        setState(() {
          _biometricsEnabled = false;
        });
      }
    } catch (e) {
      log('Error authenticating: $e');
    }
  }

  void _uploadPFP(image) async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final company = await Prefs.getCompanyName();
      final workerID = await Prefs.getWorkerID();

      final extension = image.path.split('.').last;
      await s3Storage.putObject(
        'moscaresolutions',
        '$company/worker/$workerID/profile_picture/pfp.$extension',
        Stream<Uint8List>.value(Uint8List.fromList(image.readAsBytesSync())),
        onProgress: (progress) {
          log('Progress: $progress');
        },
      );
    } catch (e) {
      log('Error uploading document: $e');
    } finally {
      Navigator.pop(context);
      _getPfp();
    }
  }

  void _getPfp() async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final company = await Prefs.getCompanyName();
      final workerID = await Prefs.getWorkerID();

      final url = await s3Storage.presignedGetObject(
        'moscaresolutions',
        '$company/worker/$workerID/profile_picture/pfp.png',
      );

      log('URL: $url');

      setState(() {
        _pfp = url;
      });
    } catch (e) {
      log('Error getting profile picture: $e');
    }
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
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: colorScheme.secondaryContainer,
                      child: _pfp.isNotEmpty
                          ? Image.network(
                              _pfp, // Use the image data
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person_outlined,
                                  size: 50,
                                  color: colorScheme.primary,
                                );
                              },
                            )
                          : Icon(
                              Icons.person,
                              size: 50,
                              color: colorScheme.primary,
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: colorScheme.primary,
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 15,
                            color: colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            _showPfpDialog(colorScheme, context);
                          },
                        ),
                      ),
                    ),
                  ],
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
                  _companyName.toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Card(
                    color: colorScheme.secondaryContainer,
                    child: ListTile(
                      title: Text(
                        'Biometrics',
                        style: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                            fontSize: 14),
                      ),
                      trailing: Switch(
                        value: _biometricsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _biometricsEnabled = value;
                            if (value) {
                              _authenticate();
                            } else {
                              _savePrefs(value, 'biometricsEnabled');
                            }
                          });
                        },
                        activeColor: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Card(
                    color: colorScheme.secondaryContainer,
                    child: ListTile(
                      title: Text(
                        'Show Weather info.',
                        style: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                            fontSize: 14),
                      ),
                      trailing: Switch(
                        value: _showWeather,
                        onChanged: (value) {
                          setState(() {
                            _showWeather = value;
                            _savePrefs(value, 'showWeather');
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
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.2),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    splashColor: colorScheme.primary.withOpacity(0.1),
                    leading: Icon(Icons.link, color: colorScheme.primary),
                    title: Text(
                      'Switch Company',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () async {
                      await Prefs.clearAll();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPfpDialog(ColorScheme colorScheme, BuildContext context) {
    XFile? image0;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: colorScheme.primary),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.check, color: colorScheme.primary),
                        onPressed: () async {
                          _uploadPFP(File(image0!.path));
                        },
                      ),
                    ],
                  ),
                  image0 != null
                      ? Image.file(
                          File(image0!.path),
                          width: 100,
                          height: 100,
                          scale: 0.5,
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 20),
                  Text(
                    'Change Profile Picture',
                    style: TextStyle(
                      fontSize: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MButton(
                    label: 'Take a photo',
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.camera);
                      if (image != null) {
                        setState(() {
                          image0 = image;
                        });
                      }
                    },
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 10),
                  MButton(
                    label: 'Choose from gallery',
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          image0 = image;
                        });
                      }
                    },
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
