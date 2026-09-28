import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/weather.dart';
import '../../core/services/weather_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import 'weather_visuals.dart';

/// Compact weather card for the Home tab (Harur). Tapping opens the Weather tab.
class WeatherTeaser extends StatefulWidget {
  final VoidCallback onTap;
  final WeatherLocation location;
  const WeatherTeaser({super.key, required this.onTap, this.location = WeatherLocation.harur});

  @override
  State<WeatherTeaser> createState() => _WeatherTeaserState();
}

class _WeatherTeaserState extends State<WeatherTeaser> {
  WeatherReport? _report;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _report = WeatherService.cached(widget.location);
    _load();
  }

  Future<void> _load() async {
    final r = await WeatherService.fetch(widget.location);
    if (!mounted) return;
    setState(() {
      _report = r ?? _report;
      _failed = r == null && _report == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final r = _report;
    final palette = r == null ? null : weatherPalette(r.current.condition, r.current.temp);
    final textColor = palette?.textColor ?? Colors.white;
    final mutedColor = palette?.mutedTextColor ?? Colors.white.withValues(alpha: 0.85);

    return AppCard(
      onTap: widget.onTap,
      gradient: palette?.gradient ?? AppColors.weatherGradient,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: r == null
          ? SizedBox(
              height: 52,
              child: Row(
                children: [
                  const Icon(Icons.cloud_outlined, color: Colors.white70, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _failed ? t.weatherErrorTitle : t.loading,
                      style: AppTextStyles.subheadline.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                if (palette!.rainy) Positioned.fill(child: RainOverlay(color: textColor)),
                Row(
                  children: [
                    Icon(weatherIcon(r.current.condition, r.current.isDay), color: textColor, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.location.id == 'harur' ? t.locHarur : t.locDharmapuri, style: AppTextStyles.footnote.copyWith(color: mutedColor)),
                          const SizedBox(height: 2),
                          Text(conditionLabel(t, r.current.condition), style: AppTextStyles.headline.copyWith(color: textColor)),
                          Text(
                            t.highLow(r.today.max.round(), r.today.min.round()),
                            style: AppTextStyles.footnote.copyWith(color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                    Text('${r.current.temp.round()}°', style: AppTextStyles.largeTitle.copyWith(color: textColor, fontSize: 44, fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
            ),
    );
  }
}
