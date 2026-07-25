import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0A192F); // Midnight Blue
  static const Color secondary = Color(0xFFFFD700); // Gold/Amber
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF1E293B);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        background: background,
        surface: surface,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: primary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
