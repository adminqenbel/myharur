import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Single Source of Truth Brand Colors ────────────────────────────────────
  static const Color accent     = Color(0xFFF4B400);  // Amber Accent (Always)
  
  // Light Theme Colors
  static const Color bgLight    = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F7);
  static const Color textPrimaryLight = Color(0xFF081C2D); // Dark Navy
  static const Color textSecondaryLight = Color(0xFF64748B);
  
  // Dark Theme Colors
  static const Color bgDark     = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);

  // Status Colors (Shared)
  static const Color success    = Color(0xFF06D6A0);  
  static const Color danger     = Color(0xFFEF233C);  
  static const Color info       = Color(0xFF3A86FF);  

  static const Color dividerLight = Color(0xFFE8EDF2);
  static const Color dividerDark  = Color(0xFF2C2C2E);

  // Fallback aliases (to be removed eventually, kept for compatibility if absolutely needed)
  static const Color primary = textPrimaryLight;
  static const Color surface = surfaceLight;
  static const Color bg = bgLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color divider = dividerLight;
  static const Color secondary = textPrimaryLight;

  // ── Border Radius ──────────────────────────────────────────────────────────
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 20.0;

  // ── Card Decoration ────────────────────────────────────────────────────────
  static BoxDecoration card({double radius = radiusMd, Color color = surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
      ],
    );
  }

  static BoxDecoration gradientCard({List<Color>? colors}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radiusLg),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors ?? [primary, const Color(0xFF1A3A5C)],
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgLight,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: textPrimaryLight,
        secondary: accent,
        surface: surfaceLight,
        background: bgLight,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: textPrimaryLight,
        onSurface: textPrimaryLight,
        onBackground: textPrimaryLight,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        centerTitle: false,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimaryLight,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: textPrimaryLight),
        actionsIconTheme: const IconThemeData(color: textPrimaryLight),
      ),

      // Navigation Bar (bottom)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: accent.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimaryLight);
          }
          return GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondaryLight);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: textPrimaryLight, size: 24);
          }
          return const IconThemeData(color: textSecondaryLight, size: 22);
        }),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
      ),

      // TabBar
      tabBarTheme: const TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: textSecondaryLight,
        indicatorColor: accent,
        dividerColor: Colors.transparent,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: textPrimaryLight,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryLight,
          side: const BorderSide(color: dividerLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: info,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: dividerLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input / TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: info, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: textSecondaryLight, fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: textSecondaryLight, fontSize: 14),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: bgLight,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryLight),
        side: const BorderSide(color: dividerLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        tileColor: surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: dividerLight, thickness: 1, space: 1),

      // Text
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimaryLight),
        headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimaryLight),
        headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimaryLight),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimaryLight),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimaryLight),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 15, color: textPrimaryLight),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondaryLight),
        bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondaryLight),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimaryLight),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgDark,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: textPrimaryDark,
        secondary: accent,
        surface: surfaceDark,
        background: bgDark,
        error: danger,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimaryDark,
        onBackground: textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        centerTitle: false,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(color: textPrimaryDark, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.2),
        iconTheme: const IconThemeData(color: textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: accent,
        unselectedItemColor: textSecondaryDark,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black, // Dark theme amber button has black text
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryDark,
          side: const BorderSide(color: dividerDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      // Input / TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: info, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: textSecondaryDark, fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: textSecondaryDark, fontSize: 14),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: dividerDark, thickness: 1, space: 1),

      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimaryDark),
        headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimaryDark),
        headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimaryDark),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimaryDark),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimaryDark),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 15, color: textPrimaryDark),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondaryDark),
        bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondaryDark),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimaryDark),
      ),
    );
  }
}
