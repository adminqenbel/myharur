import 'package:flutter/material.dart';
import '../../core/models/weather.dart';
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
