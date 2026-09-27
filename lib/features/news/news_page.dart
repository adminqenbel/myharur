import 'package:flutter/material.dart';
import '../../core/util/safe_launch.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/alert.dart';
import '../../core/models/news_article.dart';
import '../../core/services/alerts_service.dart';
import '../../core/services/news_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../ads/sponsored_card.dart';
import '../alerts/submit_alert_page.dart';
import '../reports/alert_widgets.dart';

// ==============================================================================
// NEWS — local headlines (traffic, weather, civic, farming) for Harur and Dharmapuri,
// gathered every 30 minutes by the news-crawler edge function. Each card links out to
// the publisher; we only store the headline, source and link.
// ==============================================================================
class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  static const _categories = ['traffic', 'weather', 'civic', 'farming', 'general'];
  static const _regions = [null, 'harur', 'dharmapuri'];

  int _tab = 0; // 0 = headlines (crawled), 1 = community (submitted by residents, reviewed)
  String? _category;
  int _region = 0;
  List<NewsArticle> _items = [];
  List<Alert> _community = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_tab == 1) return _loadCommunity();
    setState(() => _loading = _items.isEmpty);
    final r = await NewsService.fetch(category: _category, region: _regions[_region]);
    if (!mounted) return;
    setState(() {
      if (r != null) _items = r;
      _loading = false;
      _error = r == null && _items.isEmpty;
    });
  }

  Future<void> _loadCommunity() async {
    setState(() => _loading = _community.isEmpty);
    final r = await AlertsService.fetchFeedAlerts(kind: 'news', limit: 40);
    if (!mounted) return;
    setState(() {
      if (r != null) _community = r;
      _loading = false;
      _error = r == null && _community.isEmpty;
    });
  }

  Future<void> _share() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const SubmitAlertPage(kind: 'news')));
    if (mounted && _tab == 1) _loadCommunity();
  }

  Future<void> _open(NewsArticle a) async {
    await safeLaunch(a.url);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final community = _tab == 1;

    return CustomScrollView(
      slivers: [
        LargeTitleSliver(title: t.newsTitle, trailing: BarIconButton(icon: Icons.add_rounded, tooltip: t.shareNews, onTap: _share)),
        refreshSliver(_load),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, 12),
            child: SegmentedPill(
              labels: [t.tabHeadlines, t.tabCommunity],
              selected: _tab,
              onChanged: (i) {
                setState(() => _tab = i);
                _load();
              },
            ),
          ),
        ),
        if (!community) ...[
          const SliverToBoxAdapter(child: SponsoredCard(placement: 'news')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 12),
              child: SegmentedPill(
                labels: [t.areaAll, t.locHarur, t.locDharmapuri],
                selected: _region,
                onChanged: (i) {
                  setState(() => _region = i);
                  _load();
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FilterRail(pills: [
                FilterPill(
                  label: t.newsAll,
                  selected: _category == null,
                  onTap: () {
                    setState(() => _category = null);
                    _load();
                  },
                ),
                for (final c in _categories)
                  FilterPill(
                    label: newsCategoryName(t, c),
                    selected: _category == c,
                    color: categoryColor(c),
                    onTap: () {
                      setState(() => _category = _category == c ? null : c);
                      _load();
                    },
                  ),
              ]),
            ),
          ),
        ],
        if (_loading)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            sliver: SliverToBoxAdapter(child: _NewsSkeleton()),
          )
        else if (_error)
          SliverToBoxAdapter(child: EmptyState(icon: Icons.wifi_off_rounded, title: t.newsErrorTitle, body: t.alertsErrorBody, actionLabel: t.retry, onAction: _load))
        else if (community && _community.isEmpty)
          SliverToBoxAdapter(child: EmptyState(icon: Icons.groups_rounded, title: t.communityEmptyTitle, body: t.communityEmptyBody, actionLabel: t.shareNews, onAction: _share))
        else if (community)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 28),
            sliver: SliverList.separated(
              itemCount: _community.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => AlertCard(alert: _community[i], onTap: () => showAlertDetail(context, _community[i], onChanged: _loadCommunity)),
            ),
          )
        else if (_items.isEmpty)
          SliverToBoxAdapter(child: EmptyState(icon: Icons.newspaper_rounded, title: t.newsEmptyTitle, body: t.newsEmptyBody))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 28),
            sliver: SliverList.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _NewsCard(article: _items[i], onTap: () => _open(_items[i])),
            ),
          ),
      ],
    );
  }
}

Color categoryColor(String c) {
  switch (c) {
    case 'traffic': return AppColors.road;
    case 'weather': return AppColors.weatherBlue;
    case 'civic': return AppColors.govt;
    case 'farming': return AppColors.success;
    default: return AppColors.tertiaryLabel;
  }
}

String newsCategoryName(AppLocalizations t, String c) {
  switch (c) {
    case 'traffic': return t.newsTraffic;
    case 'weather': return t.newsWeather;
    case 'civic': return t.newsCivic;
    case 'farming': return t.newsFarming;
    default: return t.newsGeneral;
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  const _NewsCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = categoryColor(article.category);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(label: newsCategoryName(t, article.category), color: color),
              const SizedBox(width: 8),
              Text(context.timeAgo(article.publishedAt), style: AppTextStyles.caption1),
            ],
          ),
          const SizedBox(height: 10),
          Text(article.title, style: AppTextStyles.headline, maxLines: 4, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(article.source ?? '', style: AppTextStyles.footnote, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.tertiaryLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 70, height: 18, radius: 6),
                SizedBox(height: 12),
                SkeletonBox(height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: 220, height: 16),
                SizedBox(height: 12),
                SkeletonBox(width: 100, height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
