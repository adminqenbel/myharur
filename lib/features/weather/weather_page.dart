import 'package:flutter/material.dart';
import '../../core/util/safe_launch.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/weather.dart';
import '../../core/services/weather_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import 'weather_visuals.dart';

// ==============================================================================
// WEATHER — Harur and Dharmapuri. The blue -> red gradient hero is the one
// expressive element in the app; everything below it stays quiet and readable.
// ==============================================================================
class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  int _loc = 0;
  final Map<String, WeatherReport> _reports = {};
  bool _loading = true;

  WeatherLocation get _location => WeatherLocation.all[_loc];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    final loc = _location;
    final cached = WeatherService.cached(loc);
    if (cached != null) _reports[loc.id] = cached;
    setState(() {
      _loading = _reports[loc.id] == null;
    });
    final r = await WeatherService.fetch(loc, force: force);
    if (!mounted) return;
    setState(() {
      if (r != null) _reports[loc.id] = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final report = _reports[_location.id];
    final name = _loc == 0 ? t.locHarur : t.locDharmapuri;

    return CustomScrollView(
      slivers: [
        LargeTitleSliver(title: t.weatherTitle),
        refreshSliver(() => _load(force: true)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, 14),
            child: SegmentedPill(
              labels: [t.locHarur, t.locDharmapuri],
              selected: _loc,
              onChanged: (i) {
                setState(() => _loc = i);
                _load();
              },
            ),
          ),
        ),
        if (report == null && _loading)
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter), child: SkeletonBox(height: 300, radius: 28)),
          )
        else if (report == null)
          SliverToBoxAdapter(
            child: EmptyState(icon: Icons.cloud_off_rounded, title: t.weatherErrorTitle, body: t.weatherErrorBody, actionLabel: t.retry, onAction: () => _load(force: true)),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 32),
            sliver: SliverList.list(children: [
              _Hero(report: report, place: name),
              ..._alerts(context, report),
              const SizedBox(height: 14),
              _HourlyCard(report: report),
              const SizedBox(height: 14),
              _DailyCard(report: report),
              const SizedBox(height: 14),
              _Details(report: report),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () => safeLaunch('https://open-meteo.com/'),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(t.weatherCredit, style: AppTextStyles.caption2.copyWith(decoration: TextDecoration.underline)),
                  ),
                ),
              ),
            ]),
          ),
      ],
    );
  }

  List<Widget> _alerts(BuildContext context, WeatherReport r) {
    final t = context.t;
    final out = <Widget>[];
    if (r.today.rainChance >= 60) {
      out.add(const SizedBox(height: 12));
      out.add(Banner2(icon: Icons.umbrella_rounded, text: t.rainAlert(r.today.rainChance), color: AppColors.weatherBlue));
    }
    if (r.today.max >= 38) {
      out.add(const SizedBox(height: 12));
      out.add(Banner2(icon: Icons.device_thermostat_rounded, text: t.heatAlert(r.today.max.round()), color: AppColors.weatherRed));
    }
    return out;
  }
}

// ── Hero ───────────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final WeatherReport report;
  final String place;
  const _Hero({required this.report, required this.place});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = report.current;
    final white70 = Colors.white.withValues(alpha: 0.82);

    return SoftShadow(
      radius: 30,
      shadows: [BoxShadow(color: AppColors.weatherViolet.withValues(alpha: 0.28), blurRadius: 30, offset: const Offset(0, 14))],
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(gradient: AppColors.weatherGradient, shape: squircle(30)),
      child: Stack(
        children: [
          // soft depth: two translucent discs
          Positioned(right: -60, top: -70, child: _disc(230, 0.10)),
          Positioned(left: -80, bottom: -110, child: _disc(260, 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.place_rounded, size: 16, color: white70),
                    const SizedBox(width: 4),
                    Text(place, style: AppTextStyles.headline.copyWith(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${c.temp.round()}°', style: const TextStyle(fontFamily: 'Inter', fontSize: 96, height: 1.05, letterSpacing: -4, fontWeight: FontWeight.w400, color: Colors.white)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(weatherIcon(c.condition, c.isDay), color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(conditionLabel(t, c.condition), style: AppTextStyles.title3.copyWith(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(t.highLow(report.today.max.round(), report.today.min.round()), style: AppTextStyles.callout.copyWith(color: white70)),
                const SizedBox(height: 2),
                Text(t.feelsLike(c.feelsLike.round()), style: AppTextStyles.footnote.copyWith(color: white70)),
                const SizedBox(height: 14),
                Text(t.updatedAt(_clock(report.fetchedAt)), style: AppTextStyles.caption2.copyWith(color: Colors.white.withValues(alpha: 0.65))),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _disc(double size, double alpha) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)));
}

// ── Hourly ─────────────────────────────────────────────────────────────────────
class _HourlyCard extends StatelessWidget {
  final WeatherReport report;
  const _HourlyCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(t.hourlyTitle, style: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w600))),
          const SizedBox(height: 10),
          SizedBox(
            height: 102,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: report.hourly.length,
              itemBuilder: (context, i) {
                final h = report.hourly[i];
                return SizedBox(
                  width: 58,
                  child: Column(
                    children: [
                      Text(i == 0 ? t.now : _hour(h.time), style: AppTextStyles.caption1.copyWith(fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400, color: AppColors.ink)),
                      const SizedBox(height: 8),
                      Icon(weatherIcon(h.condition, h.isDay), size: 24, color: AppColors.weatherViolet),
                      SizedBox(
                        height: 16,
                        child: h.rainChance >= 30 ? Text('${h.rainChance}%', style: AppTextStyles.caption2.copyWith(color: AppColors.weatherBlue, fontWeight: FontWeight.w600)) : null,
                      ),
                      const SizedBox(height: 4),
                      Text('${h.temp.round()}°', style: AppTextStyles.headline),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 7-day ──────────────────────────────────────────────────────────────────────
class _DailyCard extends StatelessWidget {
  final WeatherReport report;
  const _DailyCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final days = report.daily;
    final lo = days.map((d) => d.min).reduce((a, b) => a < b ? a : b);
    final hi = days.map((d) => d.max).reduce((a, b) => a > b ? a : b);
    final span = (hi - lo) <= 0 ? 1.0 : (hi - lo);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.dailyTitle, style: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) Divider(height: 0.5, color: AppColors.hairline.withValues(alpha: 0.14)),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  SizedBox(width: 56, child: Text(i == 0 ? t.today : weekdayShort(context, days[i].date.weekday), style: AppTextStyles.callout.copyWith(fontWeight: FontWeight.w500))),
                  SizedBox(width: 30, child: Icon(weatherIcon(days[i].condition, true), size: 22, color: AppColors.weatherViolet)),
                  SizedBox(
                    width: 40,
                    child: days[i].rainChance >= 30
                        ? Text('${days[i].rainChance}%', style: AppTextStyles.caption1.copyWith(color: AppColors.weatherBlue, fontWeight: FontWeight.w600))
                        : null,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(width: 30, child: Text('${days[i].min.round()}°', textAlign: TextAlign.end, style: AppTextStyles.callout.copyWith(color: AppColors.tertiaryLabel))),
                        const SizedBox(width: 8),
                        Expanded(child: _RangeBar(start: (days[i].min - lo) / span, end: (days[i].max - lo) / span)),
                        const SizedBox(width: 8),
                        SizedBox(width: 30, child: Text('${days[i].max.round()}°', style: AppTextStyles.callout.copyWith(fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  final double start;
  final double end;
  const _RangeBar({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final left = (start * w).clamp(0.0, w - 6);
      final width = ((end - start) * w).clamp(6.0, w - left);
      return SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(3))),
            Positioned(
              left: left,
              width: width,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(colors: [AppColors.weatherBlue, AppColors.weatherViolet, AppColors.weatherRed]),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Details grid ───────────────────────────────────────────────────────────────
class _Details extends StatelessWidget {
  final WeatherReport report;
  const _Details({required this.report});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = report.current;
    final today = report.today;
    final tiles = <(IconData, String, String)>[
      (Icons.water_drop_outlined, t.humidity, '${c.humidity}%'),
      (Icons.air_rounded, t.wind, '${c.windKmh.round()} km/h'),
      (Icons.umbrella_outlined, t.rainChance, '${today.rainChance}%'),
      (Icons.wb_sunny_outlined, t.uvIndex, today.uv.round().toString()),
      (Icons.wb_twilight_rounded, t.sunrise, _clock(today.sunrise)),
      (Icons.nights_stay_outlined, t.sunset, _clock(today.sunset)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(t.detailsTitle, style: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w600))),
        for (var r = 0; r < tiles.length; r += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: _Tile(icon: tiles[r].$1, label: tiles[r].$2, value: tiles[r].$3)),
                const SizedBox(width: 12),
                Expanded(child: _Tile(icon: tiles[r + 1].$1, label: tiles[r + 1].$2, value: tiles[r + 1].$3)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Tile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.weatherViolet),
            const SizedBox(width: 6),
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.footnote)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.title2),
        ],
      ),
    );
  }
}

// ── formatting ─────────────────────────────────────────────────────────────────
String _clock(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

String _hour(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h ${d.hour < 12 ? 'AM' : 'PM'}';
}

String weekdayShort(BuildContext context, int weekday) {
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const ta = ['திங்', 'செவ்', 'புதன்', 'வியா', 'வெள்', 'சனி', 'ஞாயி'];
  return (LocaleController.instance.isTamil ? ta : en)[(weekday - 1) % 7];
}
