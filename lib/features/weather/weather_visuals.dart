import 'package:flutter/material.dart';
import '../../core/models/weather.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Icon for a condition (moon variants at night).
IconData weatherIcon(WeatherCondition c, bool isDay) {
  switch (c) {
    case WeatherCondition.clear:
    case WeatherCondition.mostlyClear:
      return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    case WeatherCondition.partlyCloudy:
      return isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded;
    case WeatherCondition.overcast:
      return Icons.cloud_rounded;
    case WeatherCondition.fog:
      return Icons.foggy;
    case WeatherCondition.drizzle:
      return Icons.water_drop_outlined;
    case WeatherCondition.rain:
    case WeatherCondition.showers:
      return Icons.water_drop_rounded;
    case WeatherCondition.heavyRain:
      return Icons.umbrella_rounded;
    case WeatherCondition.thunderstorm:
      return Icons.thunderstorm_rounded;
    case WeatherCondition.unknown:
      return Icons.cloud_queue_rounded;
  }
}

const _rainyConditions = {
  WeatherCondition.drizzle,
  WeatherCondition.rain,
  WeatherCondition.heavyRain,
  WeatherCondition.showers,
  WeatherCondition.thunderstorm,
};

/// Colour treatment for the weather hero/teaser card, picked from the live report:
/// rain takes priority (dark blue + raindrops), then hot or cool by temperature,
/// otherwise the app's usual blue-violet-red gradient.
class WeatherPalette {
  final Gradient gradient;
  final Color textColor;
  final Color mutedTextColor;
  final Color shadowColor;
  final bool rainy;
  const WeatherPalette({
    required this.gradient,
    required this.textColor,
    required this.mutedTextColor,
    required this.shadowColor,
    this.rainy = false,
  });
}

WeatherPalette weatherPalette(WeatherCondition condition, double tempC) {
  if (_rainyConditions.contains(condition)) {
    return WeatherPalette(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0C1F3D), Color(0xFF1E4976)]),
      textColor: Colors.white,
      mutedTextColor: Colors.white.withValues(alpha: 0.82),
      shadowColor: const Color(0xFF0C1F3D),
      rainy: true,
    );
  }
  if (tempC >= 34) {
    return WeatherPalette(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFC02E), Color(0xFFFF7A00)]),
      textColor: Colors.white,
      mutedTextColor: Colors.white.withValues(alpha: 0.85),
      shadowColor: const Color(0xFFFF7A00),
    );
  }
  if (tempC <= 20) {
    return const WeatherPalette(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF9AD1FB), Colors.white]),
      textColor: Color(0xFF0E4E85),
      mutedTextColor: Color(0xFF3E7CAD),
      shadowColor: Color(0xFF9AD1FB),
    );
  }
  return WeatherPalette(
    gradient: AppColors.weatherGradient,
    textColor: Colors.white,
    mutedTextColor: Colors.white.withValues(alpha: 0.82),
    shadowColor: AppColors.weatherViolet,
  );
}

/// A handful of translucent raindrop glyphs scattered over the rainy palette's background.
class RainOverlay extends StatelessWidget {
  final Color color;
  const RainOverlay({super.key, this.color = Colors.white});

  static const _drops = [(0.12, 0.15, 16.0), (0.32, 0.58, 22.0), (0.55, 0.22, 14.0), (0.74, 0.64, 20.0), (0.90, 0.34, 15.0), (0.45, 0.82, 18.0)];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          for (final (dx, dy, size) in _drops)
            Positioned(
              left: c.maxWidth * dx,
              top: c.maxHeight * dy,
              child: Icon(Icons.water_drop_rounded, size: size, color: color.withValues(alpha: 0.16)),
            ),
        ],
      ),
    );
  }
}

String conditionLabel(AppLocalizations t, WeatherCondition c) {
  switch (c) {
    case WeatherCondition.clear: return t.wxClear;
    case WeatherCondition.mostlyClear: return t.wxMostlyClear;
    case WeatherCondition.partlyCloudy: return t.wxPartlyCloudy;
    case WeatherCondition.overcast: return t.wxOvercast;
    case WeatherCondition.fog: return t.wxFog;
    case WeatherCondition.drizzle: return t.wxDrizzle;
    case WeatherCondition.rain: return t.wxRain;
    case WeatherCondition.heavyRain: return t.wxHeavyRain;
    case WeatherCondition.showers: return t.wxShowers;
    case WeatherCondition.thunderstorm: return t.wxThunderstorm;
    case WeatherCondition.unknown: return t.wxUnknown;
  }
}
