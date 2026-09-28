import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF166048),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFC2F1DF),
      onPrimaryContainer: Color(0xFF166048),
      surface: Colors.white,
      onSurface: Color(0xFF0D1512),
      surfaceContainerHighest: Color.fromARGB(255, 238, 232, 232),
    ),
    useMaterial3: true,
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4ADE80),
      onPrimary: Color(0xFF00391C),
      primaryContainer: Color(0xFF0D402B),
      onPrimaryContainer: Color(0xFFC2F1DF),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE0E0E0),
      onSurfaceVariant: Color(0xFFE0E0E0),
      surfaceContainerHighest: Color(0xFF2C2C2C),
      surfaceContainerHigh: Color(0xFF2C2C2C),
      surfaceContainer: Color(0xFF1E1E1E),
      outline: Color(0xFF8A8A8A),
    ),
    useMaterial3: true,
  );
}
