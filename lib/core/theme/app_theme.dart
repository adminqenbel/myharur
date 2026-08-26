import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==============================================================================
// MYHARUR APP THEME — Apple-like, Blue Primary, Clean & Simple
// ==============================================================================

class AppColors {
  // Primary — iOS blue
  static const primary = Color(0xFF007AFF);
  static const primaryDark = Color(0xFF0056CC);
  static const primaryLight = Color(0xFF5AC8FA);
  static const primarySurface = Color(0xFFE8F2FF);

  // Semantic
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const danger = Color(0xFFFF3B30);
  static const info = Color(0xFF5AC8FA);

  // Category alert colors
  static const road = Color(0xFFFF9500);        // Amber
  static const electricity = Color(0xFFFFCC00); // Yellow
  static const water = Color(0xFF007AFF);        // Blue
  static const govt = Color(0xFF5856D6);         // Indigo

  // Neutrals — iOS system palette
  static const ink = Color(0xFF1C1C1E);
  static const secondaryLabel = Color(0xFF636366);
  static const tertiaryLabel = Color(0xFF8E8E93);
  static const quaternaryLabel = Color(0xFFAEAEB2);
  static const separator = Color(0xFFD1D1D6);
  static const opaqueSeparator = Color(0xFFC6C6C8);
  static const systemBackground = Color(0xFFF2F2F7);
  static const secondaryBackground = Color(0xFFFFFFFF);
  static const tertiaryBackground = Color(0xFFE5E5EA);
  static const groupedBackground = Color(0xFFF2F2F7);

  // Glass
  static const glassFill = Color(0x14FFFFFF);
  static const glassBorder = Color(0x1AFFFFFF);
  static const glassDark = Color(0x99000000);

  // Brand dark (petrol — kept for MMID card accent)
  static const petrol = Color(0xFF234149);
  static const petrolLight = Color(0xFF8EB7C7);
}

class AppTextStyles {
  static const _base = TextStyle(fontFamily: 'Inter');

  // Display
  static final largeTitle = _base.copyWith(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: AppColors.ink);
  static final title1 = _base.copyWith(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 0.35, color: AppColors.ink);
  static final title2 = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.35, color: AppColors.ink);
  static final title3 = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.38, color: AppColors.ink);
  static final headline = _base.copyWith(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41, color: AppColors.ink);

  // Body
  static final body = _base.copyWith(fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.41, color: AppColors.ink);
  static final callout = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.32, color: AppColors.ink);
  static final subheadline = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.24, color: AppColors.ink);
  static final footnote = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: -0.08, color: AppColors.secondaryLabel);
  static final caption1 = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0, color: AppColors.secondaryLabel);
  static final caption2 = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 0.07, color: AppColors.tertiaryLabel);

  // Labels
  static final labelLarge = _base.copyWith(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41, color: AppColors.primary);
  static final labelSmall = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.tertiaryLabel);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.systemBackground,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.secondaryBackground,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.ink,
        onError: Colors.white,
      ),

      // AppBar — transparent iOS-style
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.secondaryBackground.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headline,
        iconTheme: const IconThemeData(color: AppColors.primary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Cards — white with subtle shadow
      cardTheme: CardThemeData(
        color: AppColors.secondaryBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.separator, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: AppTextStyles.headline,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.headline,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.separator, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.separator, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.tertiaryLabel),
        labelStyle: AppTextStyles.footnote,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.separator,
        thickness: 0.5,
        space: 1,
      ),

      // Bottom nav (custom pill nav used instead)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        indicatorColor: AppColors.primarySurface,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.caption2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700);
          }
          return AppTextStyles.caption2;
        }),
      ),

      // Text theme bridging
      textTheme: TextTheme(
        displaySmall: AppTextStyles.largeTitle,
        headlineMedium: AppTextStyles.title1,
        headlineSmall: AppTextStyles.title2,
        titleLarge: AppTextStyles.title3,
        titleMedium: AppTextStyles.headline,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.callout,
        bodySmall: AppTextStyles.subheadline,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.footnote,
        labelSmall: AppTextStyles.caption2,
      ),
    );
  }
}

// ==============================================================================
// ALERT CATEGORY HELPERS
// ==============================================================================
extension AlertCategoryTheme on String {
  Color get categoryColor {
    switch (toLowerCase()) {
      case 'road': return AppColors.road;
      case 'electricity': return AppColors.electricity;
      case 'water': return AppColors.water;
      case 'govt': return AppColors.govt;
      default: return AppColors.primary;
    }
  }

  String get categoryIcon {
    switch (toLowerCase()) {
      case 'road': return '\u{1F6E3}';
      case 'electricity': return '\u26A1';
      case 'water': return '\u{1F4A7}';
      case 'govt': return '\u{1F3DB}';
      default: return '\u{1F4E2}';
    }
  }

  String get categoryLabel {
    switch (toLowerCase()) {
      case 'road': return 'Road';
      case 'electricity': return 'Electricity';
      case 'water': return 'Water';
      case 'govt': return 'Government';
      default: return this;
    }
  }
}
