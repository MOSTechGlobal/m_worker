import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  textTheme: GoogleFonts.interTextTheme(),
  colorScheme: lightColorScheme,
);

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  textTheme: GoogleFonts.interTextTheme(),
  colorScheme: darkColorScheme,
);

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xff625690),
  surfaceTint: Color(0xff625690),
  onPrimary: Color(0xffffffff),
  primaryContainer: Color(0xffe7deff),
  onPrimaryContainer: Color(0xff1e1048),
  secondary: Color(0xff615b71),
  onSecondary: Color(0xffffffff),
  secondaryContainer: Color(0xffe7dff8),
  onSecondaryContainer: Color(0xff1d192b),
  tertiary: Color(0xff7d5262),
  onTertiary: Color(0xffffffff),
  tertiaryContainer: Color(0xffffd9e5),
  onTertiaryContainer: Color(0xff31111f),
  error: Color(0xffba1a1a),
  onError: Color(0xffffffff),
  errorContainer: Color(0xffffdad6),
  onErrorContainer: Color(0xff410002),
  surface: Color(0xfffdf7ff),
  onSurface: Color(0xff1c1b20),
  onSurfaceVariant: Color(0xff48454e),
  outline: Color(0xff79757f),
  outlineVariant: Color(0xffcac4cf),
  shadow: Color(0xff000000),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xff312f35),
  inversePrimary: Color(0xffccbeff),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xffccbeff),
  surfaceTint: Color(0xffccbeff),
  onPrimary: Color(0xff33275e),
  primaryContainer: Color(0xff4a3e76),
  onPrimaryContainer: Color(0xffe7deff),
  secondary: Color(0xffcac3dc),
  onSecondary: Color(0xff322e41),
  secondaryContainer: Color(0xff494458),
  onSecondaryContainer: Color(0xffe7dff8),
  tertiary: Color(0xffeeb8cb),
  onTertiary: Color(0xff492534),
  tertiaryContainer: Color(0xff623b4a),
  onTertiaryContainer: Color(0xffffd9e5),
  error: Color(0xffffb4ab),
  onError: Color(0xff690005),
  errorContainer: Color(0xff93000a),
  onErrorContainer: Color(0xffffdad6),
  surface: Color(0xff141318),
  onSurface: Color(0xffe6e1e9),
  onSurfaceVariant: Color(0xffcac4cf),
  outline: Color(0xff938f99),
  outlineVariant: Color(0xff48454e),
  shadow: Color(0xff000000),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xffe6e1e9),
  inversePrimary: Color(0xff625690),
);
