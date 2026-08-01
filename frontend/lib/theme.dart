import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ───────────────────────────────────────────────────────────
  static const Color primary    = Color(0xFF081C2D);  // Dark Navy
  static const Color secondary  = Color(0xFF102A43);  
  static const Color surface    = Color(0xFF16324F);  
  static const Color accent     = Color(0xFFF4B400);  // Yellow Accent
  static const Color success    = Color(0xFF06D6A0);  
  static const Color danger     = Color(0xFFEF233C);  
  static const Color info       = Color(0xFF3A86FF);  
  
  static const Color bgLight    = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF081C2D);
  static const Color textSecondaryLight = Color(0xFF64748B);
  
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);

  // Aliases for compatibility
  static const Color textSecondary = textSecondaryLight;
  static const Color bg = bgLight;
  static const Color accentDark = Color(0xFFD49C00);
  
  static const Color divider    = Color(0xFFE8EDF2);

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
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: bgLight,
        background: bgLight,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: primary,
        onSurface: textPrimaryLight,
        onBackground: textPrimaryLight,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),

      // Navigation Bar (bottom)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: primary);
          }
          return GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 22);
        }),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
      ),

      // TabBar
      tabBarTheme: const TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: Colors.white60,
        indicatorColor: accent,
        dividerColor: Colors.transparent,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: primary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: divider),
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
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input / TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: info, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 14),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: bg,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        tileColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: divider, thickness: 1, space: 1),

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
      scaffoldBackgroundColor: primary,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: primary,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: primary,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: secondary,
        selectedItemColor: accent,
        unselectedItemColor: textSecondaryDark,
      ),
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
