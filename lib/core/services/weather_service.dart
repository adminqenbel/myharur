import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../util/secure_log.dart';

// ==============================================================================
// WEATHER SERVICE — Open-Meteo forecast (free, no key; attribution shown in the UI).
// Results are cached for 10 minutes per location so switching tabs never refetches.
// ==============================================================================
class WeatherService {
  static const _ttl = Duration(minutes: 10);
  static final Map<String, ({WeatherReport report, DateTime at})> _cache = {};

  static WeatherReport? cached(WeatherLocation loc) => _cache[loc.id]?.report;

  @visibleForTesting
  static void debugPrime(WeatherLocation loc, WeatherReport report) => _cache[loc.id] = (report: report, at: DateTime.now());

  /// Returns the forecast, or the last good one if the network fails, or null if there is none.
  static Future<WeatherReport?> fetch(WeatherLocation loc, {bool force = false}) async {
    final hit = _cache[loc.id];
    if (!force && hit != null && DateTime.now().difference(hit.at) < _ttl) return hit.report;

    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': loc.lat.toString(),
        'longitude': loc.lon.toString(),
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day',
        'hourly': 'temperature_2m,precipitation_probability,weather_code,is_day',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_max',
        'timezone': 'Asia/Kolkata',
        'forecast_days': '7',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final report = WeatherReport.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      _cache[loc.id] = (report: report, at: DateTime.now());
      return report;
    } catch (e) {
      secureLog('[WEATHER] fetch ${loc.id} failed: $e');
      return hit?.report;
    }
  }
}
