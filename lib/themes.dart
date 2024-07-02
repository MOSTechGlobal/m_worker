import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  textTheme: GoogleFonts.openSansTextTheme(),
  colorScheme: lightColorScheme,
);

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  textTheme: GoogleFonts.openSansTextTheme(),
  colorScheme: darkColorScheme,
);

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xff0d6680),
  surfaceTint: Color(0xff0d6680),
  onPrimary: Color(0xffffffff),
  primaryContainer: Color(0xffbaeaff),
  onPrimaryContainer: Color(0xff001f29),
  secondary: Color(0xff4c616b),
  onSecondary: Color(0xffffffff),
  secondaryContainer: Color(0xffcfe6f1),
  onSecondaryContainer: Color(0xff071e26),
  tertiary: Color(0xff5c5b7e),
  onTertiary: Color(0xffffffff),
  tertiaryContainer: Color(0xffe2dfff),
  onTertiaryContainer: Color(0xff181837),
  error: Color(0xffba1a1a),
  onError: Color(0xffffffff),
  errorContainer: Color(0xffffdad6),
  onErrorContainer: Color(0xff410002),
  surface: Color(0xfff5fafd),
  onSurface: Color(0xff171c1f),
  onSurfaceVariant: Color(0xff40484c),
  outline: Color(0xff70787d),
  outlineVariant: Color(0xffc0c8cc),
  shadow: Color(0xff000000),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xff2c3134),
  inversePrimary: Color(0xff89d0ee),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xff89d0ee),
  surfaceTint: Color(0xff89d0ee),
  onPrimary: Color(0xff003545),
  primaryContainer: Color(0xff004d62),
  onPrimaryContainer: Color(0xffbaeaff),
  secondary: Color(0xffb4cad5),
  onSecondary: Color(0xff1e333c),
  secondaryContainer: Color(0xff354a53),
  onSecondaryContainer: Color(0xffcfe6f1),
  tertiary: Color(0xffc5c3ea),
  onTertiary: Color(0xff2d2d4d),
  tertiaryContainer: Color(0xff444465),
  onTertiaryContainer: Color(0xffe2dfff),
  error: Color(0xffffb4ab),
  onError: Color(0xff690005),
  errorContainer: Color(0xff93000a),
  onErrorContainer: Color(0xffffdad6),
  surface: Color(0xff0f1417),
  onSurface: Color(0xffdee3e6),
  onSurfaceVariant: Color(0xffc0c8cc),
  outline: Color(0xff8a9296),
  outlineVariant: Color(0xff40484c),
  shadow: Color(0xff000000),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xffdee3e6),
  inversePrimary: Color(0xff0d6680),
);