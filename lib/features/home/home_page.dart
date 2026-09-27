import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/alert.dart';
import '../../core/models/news_article.dart';
import '../../core/models/weather.dart';
import '../../core/services/alerts_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/feature_flag_service.dart';
import '../../core/services/news_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/safe_launch.dart';
import '../../core/widgets/ui.dart';
import '../../main.dart' show AppTab, TownShell;
import '../ads/sponsored_card.dart';
import '../alerts/submit_alert_page.dart';
import '../news/news_page.dart' show categoryColor, newsCategoryName;
import '../reports/alert_widgets.dart';
import '../weather/weather_teaser.dart';

// ==============================================================================
// HOME: three sliding rails (weather, latest reports, latest news). Swipe sideways inside a rail;
// "See all" jumps to the full tab. Pull down to refresh everything.
// ==============================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Alert>? _alerts;
  List<NewsArticle>? _news;
  List<Alert>? _events;
  List<Alert>? _jobs;
  bool _alertsLoading = true;
  bool _newsLoading = true;
  Timer? _timer;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 3), (_) => _load());
    AuthNotifier.instance.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    AuthNotifier.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
    _loadPending();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final wantEvents = FeatureFlagService.isEnabled('events');
    final wantJobs = FeatureFlagService.isEnabled('jobs');
    final results = await Future.wait([
      AlertsService.fetchFeedAlerts(limit: 6),
      NewsService.fetch(limit: 6),
      wantEvents ? AlertsService.fetchFeedAlerts(kind: 'event', limit: 6) : Future.value(null),
      wantJobs ? AlertsService.fetchFeedAlerts(kind: 'job', limit: 6) : Future.value(null),
    ]);
    if (!mounted) return;
    setState(() {
      _alerts = (results[0] as List<Alert>?) ?? _alerts; // a failed refresh keeps what is on screen
      _news = (results[1] as List<NewsArticle>?) ?? _news;
      if (wantEvents) _events = (results[2] as List<Alert>?) ?? _events;
      if (wantJobs) _jobs = (results[3] as List<Alert>?) ?? _jobs;
      _alertsLoading = false;
      _newsLoading = false;
    });
    _loadPending();
  }

  Future<void> _loadPending() async {
    if (!AuthService.currentProfile.isStaff) {
      if (_pending != 0 && mounted) setState(() => _pending = 0);
      return;
    }
    final n = await AlertsService.pendingCount();
    if (mounted && n != _pending) setState(() => _pending = n);
  }

  Future<void> _openSubmit() async {
    await Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const SubmitAlertPage()));
    if (mounted) _load();
  }

  String _greeting(BuildContext context) {
    final t = context.t;
    final h = DateTime.now().hour;
    return h < 12 ? t.greetMorning : (h < 17 ? t.greetAfternoon : t.greetEvening);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final profile = AuthService.currentProfile;
    final first = profile.fullName.trim().isEmpty ? '' : profile.fullName.trim().split(RegExp(r'\s+')).first;

    return CustomScrollView(
      slivers: [
        LargeTitleSliver(title: t.tabHome, trailing: BarIconButton(icon: Icons.add_rounded, tooltip: t.report, onTap: _openSubmit)),
        refreshSliver(_load),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
            child: Text(
              first.isEmpty ? _greeting(context) : '${_greeting(context)}, $first',
              style: AppTextStyles.title3.copyWith(color: AppColors.secondaryLabel, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        if (profile.isStaff && _pending > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 16),
              child: Banner2(
                icon: Icons.fact_check_rounded,
                text: t.reviewWaiting(_pending),
                color: AppColors.warning,
                onTap: () => TownShell.goTo(context, AppTab.review),
              ),
            ),
          ),

        // ── Weather rail ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Rail(
            title: t.railWeather,
            height: 132,
            onSeeAll: () => TownShell.goTo(context, AppTab.weather),
            children: [
              WeatherTeaser(location: WeatherLocation.harur, onTap: () => TownShell.goTo(context, AppTab.weather)),
              WeatherTeaser(location: WeatherLocation.dharmapuri, onTap: () => TownShell.goTo(context, AppTab.weather)),
            ],
          ),
        ),

        // ── Reports rail ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Rail(
            title: t.railReports,
            height: 168,
            onSeeAll: () => TownShell.goTo(context, AppTab.reports),
            loading: _alertsLoading,
            emptyIcon: Icons.notifications_none_rounded,
            emptyText: t.noReportsYet,
            onEmptyTap: _openSubmit,
            children: [
              for (final a in _alerts ?? const <Alert>[]) AlertCard(alert: a, compact: true, onTap: () => showAlertDetail(context, a)),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SponsoredCard(placement: 'home')),

        // ── Events rail (only once a super admin turns the module on) ───────────
        if (FeatureFlagService.isEnabled('events'))
          SliverToBoxAdapter(
            child: Rail(
              title: t.railEvents,
              height: 168,
              onSeeAll: () => TownShell.goTo(context, AppTab.reports),
              emptyIcon: Icons.event_rounded,
              emptyText: t.eventsEmptyTitle,
              children: [
                for (final a in _events ?? const <Alert>[]) AlertCard(alert: a, compact: true, onTap: () => showAlertDetail(context, a)),
              ],
            ),
          ),

        // ── Jobs rail (only once a super admin turns the module on) ─────────────
        if (FeatureFlagService.isEnabled('jobs'))
          SliverToBoxAdapter(
            child: Rail(
              title: t.railJobs,
              height: 168,
              onSeeAll: () => TownShell.goTo(context, AppTab.reports),
              emptyIcon: Icons.work_outline_rounded,
              emptyText: t.jobsEmptyTitle,
              children: [
                for (final a in _jobs ?? const <Alert>[]) AlertCard(alert: a, compact: true, onTap: () => showAlertDetail(context, a)),
              ],
            ),
          ),

        // ── News rail ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Rail(
            title: t.railNews,
            height: 150,
            onSeeAll: () => TownShell.goTo(context, AppTab.news),
            loading: _newsLoading,
            emptyIcon: Icons.newspaper_rounded,
            emptyText: t.noNewsYet,
            children: [
              for (final n in _news ?? const <NewsArticle>[]) _NewsRailCard(article: n),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// A titled row of cards you swipe sideways (snaps card by card).
class Rail extends StatefulWidget {
  final String title;
  final double height;
  final VoidCallback onSeeAll;
  final List<Widget> children;
  final bool loading;
  final IconData? emptyIcon;
  final String? emptyText;
  final VoidCallback? onEmptyTap;

  const Rail({
    super.key,
    required this.title,
    required this.height,
    required this.onSeeAll,
    required this.children,
    this.loading = false,
    this.emptyIcon,
    this.emptyText,
    this.onEmptyTap,
  });

  @override
  State<Rail> createState() => _RailState();
}

class _RailState extends State<Rail> {
  final _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final p = (_controller.page ?? 0).round();
      if (p != _page && mounted) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final items = widget.children;

    Widget body;
    if (widget.loading && items.isEmpty) {
      body = const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter), child: SkeletonBox(height: 120, radius: 22));
    } else if (items.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: AppCard(
          onTap: widget.onEmptyTap,
          child: Row(children: [
            Icon(widget.emptyIcon ?? Icons.inbox_rounded, color: AppColors.tertiaryLabel),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.emptyText ?? '', style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel))),
          ]),
        ),
      );
    } else {
      body = PageView.builder(
        controller: _controller,
        padEnds: false,
        itemCount: items.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(left: AppSpacing.gutter, right: i == items.length - 1 ? AppSpacing.gutter : 0),
          child: Align(alignment: Alignment.topCenter, child: items[i]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
            child: Row(
              children: [
                Expanded(child: Text(widget.title, style: AppTextStyles.title3)),
                Pressable(
                  onTap: widget.onSeeAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(t.seeAll, style: AppTextStyles.subheadline.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: widget.height, child: body),
          if (items.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < items.length && i < 8; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(color: i == _page ? AppColors.primary : AppColors.separator, borderRadius: BorderRadius.circular(3)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NewsRailCard extends StatelessWidget {
  final NewsArticle article;
  const _NewsRailCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      onTap: () => safeLaunch(article.url),
      child: SizedBox(
        height: 118,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Tag(label: newsCategoryName(t, article.category), color: categoryColor(article.category)),
              const SizedBox(width: 8),
              Text(context.timeAgo(article.publishedAt), style: AppTextStyles.caption1),
            ]),
            const SizedBox(height: 10),
            Expanded(child: Text(article.title, style: AppTextStyles.headline, maxLines: 3, overflow: TextOverflow.ellipsis)),
            Row(children: [
              Expanded(child: Text(article.source ?? '', style: AppTextStyles.footnote, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.open_in_new_rounded, size: 15, color: AppColors.tertiaryLabel),
            ]),
          ],
        ),
      ),
    );
  }
}
