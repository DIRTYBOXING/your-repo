import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF0B3D91);
const Color kAccent = Color(0xFFFFC107);

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      secondary: kAccent,
    ),
    scaffoldBackgroundColor: const Color(0xFFF6F7F9),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
  );
}
