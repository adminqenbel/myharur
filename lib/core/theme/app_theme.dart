import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==============================================================================
// MYHARUR DESIGN TOKENS — iOS-style: quiet neutrals, one blue, generous spacing.
// The single expressive element is the weather gradient (blue -> red).
// ==============================================================================

class AppColors {
  // Brand / system blue
  static const primary = Color(0xFF007AFF);
  static const primaryPressed = Color(0xFF0062CC);
  static const primaryTint = Color(0x1F007AFF); // 12%

  // Semantic
  static const success = Color(0xFF30B350);
  static const warning = Color(0xFFFF9500);
  static const danger = Color(0xFFFF3B30);

  // Alert categories
  static const road = Color(0xFFFF9500);
  static const electricity = Color(0xFFF2B600);
  static const water = Color(0xFF0A84FF);
  static const govt = Color(0xFF5E5CE6);

  // Text (iOS label hierarchy)
  static const ink = Color(0xFF111114);
  static const secondaryLabel = Color(0xFF636368);
  static const tertiaryLabel = Color(0xFF8E8E93);
  static const quaternaryLabel = Color(0xFFB4B4BA);

  // Surfaces
  static const background = Color(0xFFF2F2F7); // grouped background
  static const card = Colors.white;
  static const fill = Color(0x1F767680); // segmented / search fill
  static const separator = Color(0xFFD9D9DE);
  static const hairline = Color(0x1F3C3C43);

  // Weather hero: blue -> violet -> red
  static const weatherBlue = Color(0xFF0A6CFF);
  static const weatherViolet = Color(0xFF6B4DE6);
  static const weatherRed = Color(0xFFF0384A);
  static const weatherGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [weatherBlue, weatherViolet, weatherRed],
    stops: [0.0, 0.52, 1.0],
  );

  // Backwards-compatible aliases
  static const systemBackground = background;
  static const secondaryBackground = card;
}

class AppSpacing {
  static const gutter = 16.0;
  static const cardRadius = 22.0;
  static const rowRadius = 14.0;
}

class AppTextStyles {
  static const _f = 'Inter';
  // Slightly taller line-height keeps Tamil glyphs from clipping.
  static TextStyle _s(double size, FontWeight w, {double ls = 0, Color color = AppColors.ink, double h = 1.28}) =>
      TextStyle(fontFamily: _f, fontSize: size, fontWeight: w, letterSpacing: ls, color: color, height: h);

  static final largeTitle = _s(34, FontWeight.w700, ls: -0.6, h: 1.15);
  static final title1 = _s(28, FontWeight.w700, ls: -0.4, h: 1.2);
  static final title2 = _s(22, FontWeight.w700, ls: -0.3, h: 1.22);
  static final title3 = _s(20, FontWeight.w600, ls: -0.3);
  static final headline = _s(17, FontWeight.w600, ls: -0.3);
  static final body = _s(17, FontWeight.w400, ls: -0.3, h: 1.35);
  static final callout = _s(16, FontWeight.w400, ls: -0.25, h: 1.35);
  static final subheadline = _s(15, FontWeight.w400, ls: -0.2, h: 1.32);
  static final footnote = _s(13, FontWeight.w400, ls: -0.05, color: AppColors.secondaryLabel);
  static final caption1 = _s(12, FontWeight.w400, color: AppColors.secondaryLabel);
  static final caption2 = _s(11, FontWeight.w400, color: AppColors.tertiaryLabel);
  static final labelLarge = _s(17, FontWeight.w600, ls: -0.3, color: AppColors.primary);
  static final labelSmall = _s(11, FontWeight.w500, color: AppColors.tertiaryLabel);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.card,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.ink,
        onError: Colors.white,
      ),
      // iOS-style push transition + swipe-back on Android too
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x0F000000),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headline,
        iconTheme: const IconThemeData(color: AppColors.primary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: _border(AppColors.separator, 0.5),
        enabledBorder: _border(AppColors.separator, 0.5),
        focusedBorder: _border(AppColors.primary, 1.5),
        errorBorder: _border(AppColors.danger, 1),
        focusedErrorBorder: _border(AppColors.danger, 1.5),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.quaternaryLabel),
        labelStyle: AppTextStyles.subheadline.copyWith(color: AppColors.tertiaryLabel),
        floatingLabelStyle: AppTextStyles.footnote,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 0.5, space: 0.5),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.primary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2C2C2E),
        contentTextStyle: AppTextStyles.subheadline.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppTextStyles.headline,
        contentTextStyle: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.separator,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.headline,
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
    return base;
  }

  static OutlineInputBorder _border(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
}

/// iOS-like bounce on every platform.
class BouncingScrollBehavior extends MaterialScrollBehavior {
  const BouncingScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

// ==============================================================================
// ALERT CATEGORY HELPERS (colors + icons; labels come from AppLocalizations)
// ==============================================================================
extension AlertCategoryTheme on String {
  Color get categoryColor {
    switch (toLowerCase()) {
      case 'road': return AppColors.road;
      case 'electricity': return AppColors.electricity;
      case 'water': return AppColors.water;
      case 'govt': return AppColors.govt;
      // community news categories
      case 'traffic': return AppColors.road;
      case 'civic': return AppColors.govt;
      case 'health': return AppColors.success;
      case 'education': return AppColors.weatherBlue;
      case 'community': return AppColors.primary;
      case 'other': return AppColors.tertiaryLabel;
      // event categories
      case 'cultural': return AppColors.weatherViolet;
      case 'sports': return AppColors.success;
      case 'religious': return AppColors.weatherRed;
      case 'government': return AppColors.govt;
      case 'business': return AppColors.primary;
      // job categories
      case 'full_time': return AppColors.primary;
      case 'part_time': return AppColors.weatherBlue;
      case 'contract': return AppColors.weatherViolet;
      case 'internship': return AppColors.success;
      case 'daily_wage': return AppColors.warning;
      default: return AppColors.primary;
    }
  }

  IconData get categoryIconData {
    switch (toLowerCase()) {
      case 'road': return Icons.traffic_rounded;
      case 'electricity': return Icons.bolt_rounded;
      case 'water': return Icons.water_drop_rounded;
      case 'govt': return Icons.account_balance_rounded;
      case 'traffic': return Icons.traffic_rounded;
      case 'civic': return Icons.account_balance_rounded;
      case 'health': return Icons.health_and_safety_rounded;
      case 'education': return Icons.school_rounded;
      case 'community': return Icons.groups_rounded;
      case 'other': return Icons.article_rounded;
      case 'cultural': return Icons.celebration_rounded;
      case 'sports': return Icons.sports_cricket_rounded;
      case 'religious': return Icons.temple_hindu_rounded;
      case 'government': return Icons.account_balance_rounded;
      case 'business': return Icons.storefront_rounded;
      case 'full_time': return Icons.work_rounded;
      case 'part_time': return Icons.schedule_rounded;
      case 'contract': return Icons.assignment_rounded;
      case 'internship': return Icons.school_rounded;
      case 'daily_wage': return Icons.construction_rounded;
      default: return Icons.campaign_rounded;
    }
  }

  /// English fallback label (used by tests and non-UI code).
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
