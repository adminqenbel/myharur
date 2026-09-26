// ==============================================================================
// WEATHER MODELS — parsed from the Open-Meteo forecast API (no API key).
// Timestamps are IST wall-clock strings (we request timezone=Asia/Kolkata), so they are
// compared with each other / the API's own "current" time, never with the phone clock.
// ==============================================================================

class WeatherLocation {
  final String id; // 'harur' | 'dharmapuri'
  final double lat;
  final double lon;
  const WeatherLocation(this.id, this.lat, this.lon);

  static const harur = WeatherLocation('harur', 12.0624, 78.4983);
  static const dharmapuri = WeatherLocation('dharmapuri', 12.1357, 78.1584);
  static const all = [harur, dharmapuri];
}

enum WeatherCondition { clear, mostlyClear, partlyCloudy, overcast, fog, drizzle, rain, heavyRain, showers, thunderstorm, unknown }

/// WMO weather-interpretation codes -> our small set of conditions.
WeatherCondition conditionFromCode(int code) {
  switch (code) {
    case 0: return WeatherCondition.clear;
    case 1: return WeatherCondition.mostlyClear;
    case 2: return WeatherCondition.partlyCloudy;
    case 3: return WeatherCondition.overcast;
    case 45:
    case 48: return WeatherCondition.fog;
    case 51:
    case 53:
    case 55:
    case 56:
    case 57: return WeatherCondition.drizzle;
    case 61:
    case 63:
    case 66:
    case 67: return WeatherCondition.rain;
    case 65:
    case 82: return WeatherCondition.heavyRain;
    case 80:
    case 81: return WeatherCondition.showers;
    case 95:
    case 96:
    case 99: return WeatherCondition.thunderstorm;
    default: return WeatherCondition.unknown;
  }
}

class CurrentWeather {
  final DateTime time;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windKmh;
  final double precipitation;
  final int code;
  final bool isDay;

  const CurrentWeather({
    required this.time,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windKmh,
    required this.precipitation,
    required this.code,
    required this.isDay,
  });

  WeatherCondition get condition => conditionFromCode(code);
}

class HourlyPoint {
  final DateTime time;
  final double temp;
  final int rainChance;
  final int code;
  final bool isDay;
  const HourlyPoint({required this.time, required this.temp, required this.rainChance, required this.code, required this.isDay});
  WeatherCondition get condition => conditionFromCode(code);
}

class DailyPoint {
  final DateTime date;
  final int code;
  final double max;
  final double min;
  final int rainChance;
  final DateTime sunrise;
  final DateTime sunset;
  final double uv;
  const DailyPoint({
    required this.date,
    required this.code,
    required this.max,
    required this.min,
    required this.rainChance,
    required this.sunrise,
    required this.sunset,
    required this.uv,
  });
  WeatherCondition get condition => conditionFromCode(code);
}

class WeatherReport {
  final CurrentWeather current;
  final List<HourlyPoint> hourly; // next 24 hours starting at the current hour
  final List<DailyPoint> daily; // today + 6 days
  final DateTime fetchedAt;

  const WeatherReport({required this.current, required this.hourly, required this.daily, required this.fetchedAt});

  DailyPoint get today => daily.first;

  factory WeatherReport.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final c = json['current'] as Map<String, dynamic>;
    final h = json['hourly'] as Map<String, dynamic>;
    final d = json['daily'] as Map<String, dynamic>;

    double n(dynamic v) => (v as num?)?.toDouble() ?? 0;
    int i(dynamic v) => (v as num?)?.round() ?? 0;

    final current = CurrentWeather(
      time: DateTime.parse(c['time'] as String),
      temp: n(c['temperature_2m']),
      feelsLike: n(c['apparent_temperature']),
      humidity: i(c['relative_humidity_2m']),
      windKmh: n(c['wind_speed_10m']),
      precipitation: n(c['precipitation']),
      code: i(c['weather_code']),
      isDay: i(c['is_day']) == 1,
    );

    final times = (h['time'] as List).cast<String>();
    final temps = h['temperature_2m'] as List;
    final rain = h['precipitation_probability'] as List;
    final codes = h['weather_code'] as List;
    final days = h['is_day'] as List?;

    // Start at the current hour (floor), take 24 entries.
    final anchor = DateTime(current.time.year, current.time.month, current.time.day, current.time.hour);
    final hourly = <HourlyPoint>[];
    for (var k = 0; k < times.length && hourly.length < 24; k++) {
      final t = DateTime.parse(times[k]);
      if (t.isBefore(anchor)) continue;
      hourly.add(HourlyPoint(
        time: t,
        temp: n(temps[k]),
        rainChance: i(rain[k]),
        code: i(codes[k]),
        isDay: days == null ? (t.hour >= 6 && t.hour < 18) : i(days[k]) == 1,
      ));
    }

    final dTimes = (d['time'] as List).cast<String>();
    final daily = <DailyPoint>[
      for (var k = 0; k < dTimes.length; k++)
        DailyPoint(
          date: DateTime.parse(dTimes[k]),
          code: i((d['weather_code'] as List)[k]),
          max: n((d['temperature_2m_max'] as List)[k]),
          min: n((d['temperature_2m_min'] as List)[k]),
          rainChance: i((d['precipitation_probability_max'] as List)[k]),
          sunrise: DateTime.parse((d['sunrise'] as List)[k] as String),
          sunset: DateTime.parse((d['sunset'] as List)[k] as String),
          uv: n((d['uv_index_max'] as List)[k]),
        ),
    ];

    return WeatherReport(current: current, hourly: hourly, daily: daily, fetchedAt: now ?? DateTime.now());
  }
}
