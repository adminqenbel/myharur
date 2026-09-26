import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/core/models/news_article.dart';
import 'package:myharur/core/models/weather.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/core/widgets/ui.dart';

/// Builds an Open-Meteo style payload (IST wall-clock timestamps), 3 days of hourly data.
Map<String, dynamic> _fixture({String now = '2026-09-26T19:30'}) {
  final start = DateTime.parse('2026-09-26T00:00');
  final hours = [for (var i = 0; i < 72; i++) start.add(Duration(hours: i))];
  String iso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:00';
  return {
    'current': {
      'time': now,
      'temperature_2m': 29.1,
      'relative_humidity_2m': 52,
      'apparent_temperature': 31.1,
      'precipitation': 0.0,
      'weather_code': 0,
      'wind_speed_10m': 6.7,
      'is_day': 0,
    },
    'hourly': {
      'time': hours.map(iso).toList(),
      'temperature_2m': [for (var i = 0; i < 72; i++) 20.0 + (i % 24)],
      'precipitation_probability': [for (var i = 0; i < 72; i++) i % 100],
      'weather_code': [for (var i = 0; i < 72; i++) i % 3 == 0 ? 3 : 61],
      'is_day': [for (final h in hours) (h.hour >= 6 && h.hour < 18) ? 1 : 0],
    },
    'daily': {
      'time': ['2026-09-26', '2026-09-27', '2026-09-28'],
      'weather_code': [0, 80, 95],
      'temperature_2m_max': [33.4, 31.0, 29.5],
      'temperature_2m_min': [22.1, 21.5, 21.0],
      'precipitation_probability_max': [5, 70, 90],
      'sunrise': ['2026-09-26T06:01', '2026-09-27T06:01', '2026-09-28T06:01'],
      'sunset': ['2026-09-26T18:06', '2026-09-27T18:05', '2026-09-28T18:05'],
      'uv_index_max': [9.1, 6.0, 4.2],
    },
  };
}

void main() {
  group('Weather model', () {
    test('parses current conditions and today/day arrays', () {
      final r = WeatherReport.fromJson(_fixture());
      expect(r.current.temp, 29.1);
      expect(r.current.humidity, 52);
      expect(r.current.isDay, isFalse);
      expect(r.current.condition, WeatherCondition.clear);
      expect(r.daily.length, 3);
      expect(r.today.max, 33.4);
      expect(r.daily[2].condition, WeatherCondition.thunderstorm);
      expect(r.today.sunrise.hour, 6);
    });

    test('hourly starts at the current hour and covers 24 hours', () {
      final r = WeatherReport.fromJson(_fixture(now: '2026-09-26T19:30'));
      expect(r.hourly.length, 24);
      expect(r.hourly.first.time, DateTime.parse('2026-09-26T19:00'));
      expect(r.hourly.last.time, DateTime.parse('2026-09-27T18:00'));
    });

    test('hourly is shorter (not wrong) when the forecast runs out', () {
      final r = WeatherReport.fromJson(_fixture(now: '2026-09-28T20:10'));
      expect(r.hourly.length, 4); // 20:00..23:00 are all that is left in the fixture
    });

    test('WMO codes map to sensible conditions', () {
      expect(conditionFromCode(0), WeatherCondition.clear);
      expect(conditionFromCode(3), WeatherCondition.overcast);
      expect(conditionFromCode(45), WeatherCondition.fog);
      expect(conditionFromCode(53), WeatherCondition.drizzle);
      expect(conditionFromCode(63), WeatherCondition.rain);
      expect(conditionFromCode(65), WeatherCondition.heavyRain);
      expect(conditionFromCode(81), WeatherCondition.showers);
      expect(conditionFromCode(99), WeatherCondition.thunderstorm);
      expect(conditionFromCode(123), WeatherCondition.unknown);
    });
  });

  group('News model', () {
    test('parses a crawler row and falls back safely', () {
      final a = NewsArticle.fromJson({
        'id': 'n1',
        'title': 'Lorry collision halts highway traffic',
        'url': 'https://example.com/a',
        'source': 'The News Mill',
        'category': 'traffic',
        'region': 'dharmapuri',
        'language': 'en',
        'published_at': '2026-09-26T04:30:00+00:00',
      });
      expect(a.category, 'traffic');
      expect(a.source, 'The News Mill');
      expect(a.publishedAt.toUtc().hour, 4);

      final b = NewsArticle.fromJson({'id': 'n2', 'published_at': 'not-a-date'});
      expect(b.category, 'general');
      expect(b.region, 'both');
      expect(b.title, '');
    });
  });

  group('Localization', () {
    testWidgets('every visible string exists in Tamil and English', (tester) async {
      late AppLocalizations en;
      late AppLocalizations ta;
      await tester.pumpWidget(MaterialApp(
        supportedLocales: LocaleController.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: Builder(builder: (c) {
          en = AppLocalizations.of(c);
          return const SizedBox();
        }),
      ));
      await tester.pumpWidget(MaterialApp(
        supportedLocales: LocaleController.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('ta'),
        home: Builder(builder: (c) {
          ta = AppLocalizations.of(c);
          return const SizedBox();
        }),
      ));
      expect(en.tabWeather, 'Weather');
      expect(ta.tabWeather, 'வானிலை');
      expect(en.minutesAgo(5), '5m ago');
      expect(ta.reviewWaiting(3), contains('3'));
    });

    test('language controller only accepts en / ta', () async {
      final c = LocaleController.instance;
      await c.setLanguage('ta');
      expect(c.isTamil, isTrue);
      await c.setLanguage('fr');
      expect(c.isTamil, isTrue);
      await c.setLanguage('en');
      expect(c.locale, const Locale('en'));
    });
  });

  group('UI kit', () {
    testWidgets('segmented control reports taps and keeps a fixed layout', (tester) async {
      var selected = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SegmentedPill(labels: const ['One', 'Two', 'Three'], selected: selected, onChanged: (i) => setState(() => selected = i)),
          ),
        ),
      ));
      final before = tester.getSize(find.byType(SegmentedPill));
      await tester.tap(find.text('Three'));
      await tester.pumpAndSettle();
      expect(selected, 2);
      expect(tester.getSize(find.byType(SegmentedPill)), before);
    });

    testWidgets('tab bar: switching tabs never changes its size (no jitter)', (tester) async {
      var selected = 0;
      final tabs = [
        const TabSpec('Home', Icons.home_outlined, Icons.home_rounded),
        const TabSpec('News', Icons.newspaper_outlined, Icons.newspaper_rounded),
        const TabSpec('Weather', Icons.cloud_outlined, Icons.cloud_rounded),
        const TabSpec('Help', Icons.health_and_safety_outlined, Icons.health_and_safety_rounded),
        const TabSpec('Account', Icons.person_outline_rounded, Icons.person_rounded),
      ];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) => AppTabBar(selected: selected, tabs: tabs, onTap: (i) => setState(() => selected = i)),
          ),
        ),
      ));
      final labelSizes = {for (final t in tabs) t.label: tester.getSize(find.text(t.label))};
      final barSize = tester.getSize(find.byType(AppTabBar));

      for (final label in ['Weather', 'Account', 'Home']) {
        await tester.tap(find.text(label));
        // sample mid-animation as well as at the end
        await tester.pump(const Duration(milliseconds: 90));
        expect(tester.getSize(find.byType(AppTabBar)), barSize);
        await tester.pumpAndSettle();
        for (final t in tabs) {
          expect(tester.getSize(find.text(t.label)), labelSizes[t.label], reason: '${t.label} label resized after selecting $label');
        }
      }
      expect(selected, 0);
    });
  });
}
