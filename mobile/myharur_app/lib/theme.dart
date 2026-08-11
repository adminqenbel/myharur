import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/test_config.dart';
import 'theme/luxury_theme.dart';

class AppTheme {
  // ── Single Source of Truth Brand Colors ────────────────────────────────────
  static Color get accent => TestConfig.isLuxuryUiTestBuild ? LuxuryColors.racingRed : appleBlue;
  static Color get appleBlue => TestConfig.isLuxuryUiTestBuild ? LuxuryColors.racingRed : const Color(0xFF007AFF);
  
  // Light Theme Colors (Apple UI Inspired in prod, Luxury Dark in test)
  static Color get bgLight => TestConfig.isLuxuryUiTestBuild ? LuxuryColors.deepBackground : const Color(0xFFFFFFFF);
  static Color get surfaceLight => TestConfig.isLuxuryUiTestBuild ? const Color(0x1F1A0000) : const Color(0xFFF2F2F7);
  static Color get textPrimaryLight => TestConfig.isLuxuryUiTestBuild ? LuxuryColors.primaryText : const Color(0xFF000000); 
  static Color get textSecondaryLight => TestConfig.isLuxuryUiTestBuild ? LuxuryColors.secondaryText : const Color(0xFF8E8E93);
  
  // Dark Theme Colors
  static Color get bgDark => TestConfig.isLuxuryUiTestBuild ? LuxuryColors.deepBackground : const Color(0xFF000000);
  static Color get surfaceDark => TestConfig.isLuxuryUiTestBuild ? const Color(0x1F1A0000) : const Color(0xFF1C1C1E);
  static Color get textPrimaryDark => TestConfig.isLuxuryUiTestBuild ? LuxuryColors.primaryText : const Color(0xFFFFFFFF);
  static Color get textSecondaryDark => TestConfig.isLuxuryUiTestBuild ? LuxuryColors.secondaryText : const Color(0x99EBEBF5);

  // Status Colors
  static const Color success    = Color(0xFF34C759);  
  static const Color danger     = Color(0xFFFF3B30);  
  static Color get info         => appleBlue;  

  static Color get dividerLight => TestConfig.isLuxuryUiTestBuild ? LuxuryColors.glassBorderSoft : const Color(0xFFE5E5EA);
  static Color get dividerDark  => TestConfig.isLuxuryUiTestBuild ? LuxuryColors.glassBorderSoft : const Color(0xFF38383A);

  // Fallback aliases
  static Color get primary => textPrimaryLight;
  static Color get surface => surfaceLight;
  static Color get bg => bgLight;
  static Color get textSecondary => textSecondaryLight;
  static Color get divider => dividerLight;
  static Color get secondary => textPrimaryLight;

  // ── Border Radius ──────────────────────────────────────────────────────────
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 20.0;

  // ── Card Decoration ────────────────────────────────────────────────────────
  static BoxDecoration card({double radius = radiusMd, Color? color}) {
    return BoxDecoration(
      color: color ?? surface,
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
      fontFamily: GoogleFonts.inter().fontFamily,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
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
        backgroundColor: bgLight.withOpacity(0.95),
        foregroundColor: textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: appleBlue),
        actionsIconTheme: IconThemeData(color: appleBlue),
      ),

      // Navigation Bar (bottom)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgLight.withOpacity(0.95),
        indicatorColor: Colors.transparent, // Apple uses transparent indicators
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: appleBlue);
          }
          return GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: textSecondaryLight);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: appleBlue, size: 26);
          }
          return IconThemeData(color: textSecondaryLight, size: 24);
        }),
        elevation: 0,
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
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
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryLight,
          side: BorderSide(color: dividerLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: info,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: dividerLight, width: 1),
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
          borderSide: BorderSide(color: dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: info, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondaryLight, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: textSecondaryLight, fontSize: 14),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: bgLight,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryLight),
        side: BorderSide(color: dividerLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        tileColor: surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: dividerLight, thickness: 1, space: 1),

      // Text
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimaryLight),
        headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimaryLight),
        headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimaryLight),
        titleLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimaryLight),
        titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimaryLight),
        bodyLarge: GoogleFonts.inter(fontSize: 15, color: textPrimaryLight),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondaryLight),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textSecondaryLight),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimaryLight),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgDark,
      fontFamily: GoogleFonts.inter().fontFamily,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
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
        backgroundColor: bgDark.withOpacity(0.95),
        foregroundColor: textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        titleTextStyle: GoogleFonts.inter(color: textPrimaryDark, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.4),
        iconTheme: IconThemeData(color: appleBlue),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgDark.withOpacity(0.95),
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: appleBlue);
          }
          return GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: textSecondaryDark);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: appleBlue, size: 26);
          }
          return IconThemeData(color: textSecondaryDark, size: 24);
        }),
        elevation: 0,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black, // Dark theme amber button has black text
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryDark,
          side: BorderSide(color: dividerDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      // Input / TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: info, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondaryDark, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: textSecondaryDark, fontSize: 14),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: dividerDark, thickness: 1, space: 1),

      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimaryDark),
        headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimaryDark),
        headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimaryDark),
        titleLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimaryDark),
        titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimaryDark),
        bodyLarge: GoogleFonts.inter(fontSize: 15, color: textPrimaryDark),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondaryDark),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textSecondaryDark),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimaryDark),
      ),
    );
  }
}
