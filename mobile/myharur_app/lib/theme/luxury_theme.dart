import 'package:flutter/material.dart';

/// Master Design System Tokens for Luxury Dark/Red Glassmorphism UI
class LuxuryColors {
  // Master Reference Palette
  static const Color alabasterGrey = Color(0xFFD9D9D9);
  static const Color racingRed = Color(0xFFDD0200);
  static const Color crimsonRed = Color(0xFFB71C1C);
  static const Color blackCherry = Color(0xFF55100D);
  static const Color coffeeBean = Color(0xFF1A0706);

  // Atmospheric Glow Tokens (From Reference Image: Red Top, Champagne Gold Bottom)
  static const Color champagneGold = Color(0xFFE2C9A5);
  static const Color silkSand = Color(0xFFD4AF37);
  static const Color warmIvory = Color(0xFFF7E7CE);

  // Supporting Ambient & Glass Palette
  static const Color deepBackground = Color(0xFF07080A);
  static const Color nearBlack = Color(0xFF0C0E12);

  static const Color glassWhite = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color glassWhiteStrong = Color.fromRGBO(255, 255, 255, 0.15);
  static const Color glassBorder = Color.fromRGBO(255, 255, 255, 0.18);
  static const Color glassBorderSoft = Color.fromRGBO(255, 255, 255, 0.09);

  static const Color redGlow = Color.fromRGBO(221, 2, 0, 0.40);
  static const Color cherryGlow = Color.fromRGBO(85, 16, 13, 0.50);
  static const Color champagneGlow = Color.fromRGBO(226, 201, 165, 0.30);
  static const Color goldGlow = Color.fromRGBO(212, 175, 55, 0.25);

  static const Color primaryText = Color(0xFFF8F9FA);
  static const Color secondaryText = Color(0xFFB0B5C0);
  static const Color accentGoldText = Color(0xFFE2C9A5);

  // Glass Levels & Specular Rim Gradients
  static const Color glassLevel1 = Color.fromRGBO(255, 255, 255, 0.04);
  static const Color glassLevel2 = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color glassLevel3 = Color.fromRGBO(255, 255, 255, 0.13);
  static const Color redGlass = Color.fromRGBO(221, 2, 0, 0.14);
  static const Color goldGlass = Color.fromRGBO(226, 201, 165, 0.12);

  static const LinearGradient specularRimGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromRGBO(255, 255, 255, 0.35),
      Color.fromRGBO(255, 255, 255, 0.05),
      Color.fromRGBO(226, 201, 165, 0.20),
    ],
    stops: [0.0, 0.6, 1.0],
  );
}

class LuxuryTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle heroTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.0,
    color: LuxuryColors.primaryText,
    height: 1.15,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: LuxuryColors.primaryText,
    height: 1.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    color: LuxuryColors.primaryText,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    color: LuxuryColors.primaryText,
    height: 1.4,
  );

  static const TextStyle secondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: LuxuryColors.secondaryText,
    height: 1.35,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: LuxuryColors.primaryText,
  );
}

class LuxuryShapes {
  static const double cardRadius = 24.0;
  static const double buttonRadius = 20.0;
  static const double dialogRadius = 28.0;
  static const double sheetRadius = 28.0;
}
