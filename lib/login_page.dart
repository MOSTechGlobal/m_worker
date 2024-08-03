import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:m_worker/components/mTextField.dart';
import 'package:m_worker/home_page.dart';
import 'package:m_worker/utils/api.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/theme_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late String _email = '';
  late String _password = '';
  late String _company = '';
  bool _isLoading = false;
  String errorMsg = '';

  Future<bool?> _isEmailAllowed(email) async {
    try {
      final responseData =
          await Api.post('isWorkerEmailAllowed', {'email': email});
      if (responseData != null) {
        if (responseData['isAllowed']) {
          return true;
        } else {
          return false;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void login() async {
    setState(() {
      _isLoading = true;
    });
    final bool? isEmailAllowed = await _isEmailAllowed(_email);
    if (isEmailAllowed == null) {
      errorMsg = 'An unexpected error occurred.';
      setState(() {
        _isLoading = false;
      });
      return;
    } else if (!isEmailAllowed) {
      errorMsg = 'You are not allowed to login.';
      setState(() {
        _isLoading = false;
      });
      return;
    } else {
      errorMsg = '';
    }

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      String? bearer = await userCredential.user!.getIdToken();
      await prefs.setString('bearer', bearer!);

      const storage = FlutterSecureStorage();
      await prefs.setString('company', _company);
      await storage.write(key: 'email', value: _email);
      await storage.write(key: 'password', value: _password);

      errorMsg = 'Success';

      setState(() {
        _isLoading = false;
      });
      await Navigator.of(context).pushReplacement(_routeToHomePage());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Wrong password provided for that user.';
      } else {
        errorMsg = e.message!;
      }
    } catch (e) {
      errorMsg = 'An unexpected error occurred.'; // Generic error message
      errorMsg = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: colorScheme.primary,
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              color: colorScheme.primary,
                              child: Container(
                                height: 300,
                              ),
                            ),
                            Positioned(
                              top: 80,
                              child: Column(
                                children: [
                                  ImageIcon(
                                    const AssetImage('assets/images/logo.png'),
                                    size: 80,
                                    color: colorScheme.inversePrimary,
                                  ),
                                  const SizedBox(height: 25),
                                  Text(
                                    'Moscare Worker',
                                    style: TextStyle(
                                      color: colorScheme.inversePrimary,
                                      fontSize: 21,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Card(
                            color: colorScheme.primaryContainer,
                            margin: EdgeInsets.zero,
                            shape: const RoundedRectangleBorder(
                              side: BorderSide.none,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(80),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Login",
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  MTextField(
                                    onChanged: (value) {
                                      _company = value;
                                    },
                                    colorScheme: colorScheme,
                                    labelText: 'Company',
                                  ),
                                  const SizedBox(height: 30),
                                  MTextField(
                                    onChanged: (value) {
                                      _email = value;
                                    },
                                    colorScheme: colorScheme,
                                    labelText: 'Email',
                                  ),
                                  const SizedBox(height: 24),
                                  MTextField(
                                    onChanged: (value) {
                                      _password = value;
                                    },
                                    colorScheme: colorScheme,
                                    labelText: 'Password',
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 40),
                                  _isLoading
                                      ? LinearProgressIndicator(
                                          color: colorScheme.primary,
                                        )
                                      : ElevatedButton(
                                          onPressed: () {
                                            login();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                colorScheme.primary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 32, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.25,
                                            ),
                                          ),
                                          child: Text('Login',
                                              style: TextStyle(
                                                color:
                                                    colorScheme.inversePrimary,
                                              )),
                                        ),
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMsg,
                                    style: TextStyle(
                                      color: colorScheme.error,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Route _routeToHomePage() {
    _isLoading = false;
    return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          final tween = Tween(begin: begin, end: end);
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );

          return SlideTransition(
            position: tween.animate(curvedAnimation),
            child: child,
          );
        });
  }
}
