import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[50],
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
