import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/alert.dart';
import '../../core/services/alerts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../alerts/submit_alert_page.dart';
import '../help/help_page.dart';
import 'alert_widgets.dart';

// ==============================================================================
// REPORTS: the community feed (road, electricity, water, government).
// Only approved reports appear here; new ones go through the filter and review first.
// The emergency helplines live one tap away at the top.
// ==============================================================================
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const _categories = ['road', 'electricity', 'water', 'govt'];

  String? _category;
  List<Alert> _alerts = [];
  bool _loading = true;
  bool _error = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _loading = _alerts.isEmpty);
    final alerts = await AlertsService.fetchFeedAlerts(category: _category, limit: 40);
    if (!mounted) return;
    setState(() {
      if (alerts != null) _alerts = alerts; // a failed refresh keeps what is already on screen
      _loading = false;
      _error = alerts == null && _alerts.isEmpty;
    });
  }

  Future<void> _openSubmit() async {
    await Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const SubmitAlertPage()));
    if (mounted) _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return CustomScrollView(
      slivers: [
        LargeTitleSliver(title: t.reportsTitle, trailing: BarIconButton(icon: Icons.add_rounded, tooltip: t.report, onTap: _openSubmit)),
        refreshSliver(() => _load()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, 14),
            child: AppCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpPage())),
              child: Row(
                children: [
                  const IconTile(icon: Icons.emergency_rounded, color: AppColors.danger, size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.emergencyHelplines, style: AppTextStyles.headline),
                        Text(t.emergencyHelplinesSub, style: AppTextStyles.footnote),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.quaternaryLabel),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FilterRail(pills: [
              FilterPill(
                label: t.catAll,
                selected: _category == null,
                onTap: () {
                  setState(() => _category = null);
                  _load();
                },
              ),
              for (final c in _categories)
                FilterPill(
                  label: context.categoryName(c),
                  selected: _category == c,
                  color: c.categoryColor,
                  onTap: () {
                    setState(() => _category = _category == c ? null : c);
                    _load();
                  },
                ),
            ]),
          ),
        ),
        if (_loading)
          const SliverPadding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter), sliver: SliverToBoxAdapter(child: FeedSkeleton()))
        else if (_error)
          SliverToBoxAdapter(child: EmptyState(icon: Icons.wifi_off_rounded, title: t.alertsErrorTitle, body: t.alertsErrorBody, actionLabel: t.retry, onAction: _load))
        else if (_alerts.isEmpty)
          SliverToBoxAdapter(child: EmptyState(icon: Icons.notifications_none_rounded, title: t.alertsEmptyTitle, body: t.alertsEmptyBody, actionLabel: t.report, onAction: _openSubmit))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 24),
            sliver: SliverList.separated(
              itemCount: _alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => AlertCard(alert: _alerts[i], onTap: () => showAlertDetail(context, _alerts[i], onChanged: () => _load(silent: true))),
            ),
          ),
      ],
    );
  }
}
