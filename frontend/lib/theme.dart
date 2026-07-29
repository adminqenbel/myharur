import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ───────────────────────────────────────────────────────────
  static const Color primaryYellow = Color(0xFFF4B400);
  static const Color secondaryYellow = Color(0xFFFFD54F);
  
  static const Color primaryDark = Color(0xFF081C2D);
  static const Color secondaryDark = Color(0xFF102A43);
  static const Color surfaceDark = Color(0xFF16324F);
  
  static const Color bgDark = Color(0xFF081C2D);
  static const Color bgLight = Color(0xFFFFFFFF);
  
  static const Color cardBgLight = Color(0xFFFFFFFF);
  static const Color cardBgDark = Color(0xFF102A43);
  
  static const Color dividerColor = Color(0xFFE8E8E8);
  static const Color dividerDark = Color(0xFF16324F);
  
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF7A7A7A);
  
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color emergency = Color(0xFFD32F2F);
  static const Color verified = Color(0xFF2E7D32);

  // ── Design Tokens ──────────────────────────────────────────────────────────
  static const double cardRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double buttonHeight = 54.0;
  static const double cardPadding = 18.0;
  
  // ── Shadows ────────────────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Typography ─────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color textColor) {
    return GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(fontSize: 34, fontWeight: FontWeight.bold, color: textColor),
      headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
      titleLarge: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w600, color: textColor), // Section Title
      titleMedium: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: textColor), // Card Title
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.normal, color: textColor), // Body
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.normal, color: textSecondary),
      labelSmall: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.normal, color: textSecondary), // Caption
    );
  }

  // ── Button Styles ──────────────────────────────────────────────────────────
  static ElevatedButtonThemeData get _elevatedButtonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryYellow,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size.fromHeight(buttonHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  );

  static OutlinedButtonThemeData get _outlinedButtonTheme => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryYellow,
      side: const BorderSide(color: primaryYellow, width: 1.5),
      elevation: 0,
      minimumSize: const Size.fromHeight(buttonHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  );
  
  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryYellow,
      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  );

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryYellow,
        secondary: secondaryYellow,
        surface: cardBgLight,
        background: bgLight,
        error: emergency,
        onPrimary: Colors.white,
        onSurface: textPrimaryLight,
        onBackground: textPrimaryLight,
      ),
      textTheme: _buildTextTheme(textPrimaryLight),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      dividerColor: dividerColor,
      cardTheme: CardThemeData(
        color: cardBgLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(color: primaryYellow), // Active color
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryDark),
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        secondary: secondaryYellow,
        surface: cardBgDark,
        background: bgDark,
        error: emergency,
        onPrimary: Colors.white,
        onSurface: textPrimaryDark,
        onBackground: textPrimaryDark,
      ),
      textTheme: _buildTextTheme(textPrimaryDark),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      dividerColor: dividerDark,
      cardTheme: CardThemeData(
        color: cardBgDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(color: primaryYellow), // Active color
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
