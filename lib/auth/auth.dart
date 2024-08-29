import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:m_worker/home_page.dart';
import 'package:m_worker/login_page.dart';
import 'package:m_worker/utils/prefs.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _auth = LocalAuthentication();
  bool isAuthenticating = false;
  bool isBiometricsEnabled = false;
  bool isAuthenticated = false;
  bool hasCheckedBiometrics = false;
  bool supportsBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    // Check if biometrics are available
    supportsBiometrics = await _canDoBiometrics();
    bool biometricsEnabled = await Prefs.getBiometricsEnabled();
    setState(() {
      isBiometricsEnabled = biometricsEnabled;
      hasCheckedBiometrics = true;
    });

    // If biometrics are not available, use FirebaseAuth's current user
    if (!supportsBiometrics || !isBiometricsEnabled) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        log('User is already signed in: ${currentUser.email}');
        setState(() {
          isAuthenticated = true;
        });
      }
      return;
    }

    // If biometrics are enabled, handle biometric authentication
    if (isBiometricsEnabled) {
      await _handleBiometricAuthentication();
    }
  }

  Future<bool> _canDoBiometrics() async {
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        log('Biometrics not available');
        return false;
      }

      List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        log('No biometrics available');
        return false;
      }
      return true;
    } catch (e) {
      log('Error checking biometrics: $e');
      return false;
    }
  }

  Future<bool> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      log('Authentication error: $e');
    }
    return authenticated;
  }

  Future<void> _handleBiometricAuthentication() async {
    setState(() {
      isAuthenticating = true;
    });

    if (supportsBiometrics && isBiometricsEnabled) {
      bool authenticated = await _authenticate();
      if (authenticated) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.email != null) {
          log('User is already signed in: ${currentUser.email}');
          setState(() {
            isAuthenticated = true;
          });
        } else {
          // If no current user is signed in, sign in with saved credentials
          await _signInWithSavedCredentials();
        }
      }
    }

    setState(() {
      isAuthenticating = false;
    });
  }

  Future<void> _signInWithSavedCredentials() async {
    final email = await Prefs.getEmail();
    final password = await Prefs.getPassword();

    if (email == null || password == null) {
      log('No saved credentials found');
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('User signed in: ${userCredential.user}');
      setState(() {
        isAuthenticated = true;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        log('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        log('Wrong password provided for that user.');
      }
      setState(() {
        isAuthenticated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isAuthenticating || !hasCheckedBiometrics) {
      return const Scaffold(
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Authenticating...',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        )),
      );
    }

    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && isAuthenticated) {
            return const HomePage();
          } else if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
