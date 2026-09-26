import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/alert.dart';
import '../../core/services/alerts_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_components.dart';
import '../alerts/submit_alert_page.dart';

// ==============================================================================
// HOME PAGE — Alerts Feed (v1 primary launch surface)
// road / electricity / water / govt
// ==============================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedCategory;
  int? _selectedWardId;
  List<Alert> _alerts = [];
  bool _loading = true;
  bool _error = false;
  Timer? _refreshTimer;

  final _categories = ['road', 'electricity', 'water', 'govt'];

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = false; });
    final alerts = await AlertsService.fetchFeedAlerts(
      category: _selectedCategory,
      wardId: _selectedWardId,
      limit: 40,
    );
    if (!mounted) return;
    setState(() {
      _alerts = alerts;
      _loading = false;
      _error = false;
    });
  }

  void _showAlertDetail(Alert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AlertDetailModal(alert: alert),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AuthService.currentProfile;

    return AtmosphericBackground(
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildHeader(profile.fullName),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),
                  child: _buildCategoryRail(),
                ),
              ),
              if (_loading)
                _buildSkeletonSliver()
              else if (_error)
                SliverFillRemaining(child: _buildError())
              else if (_alerts.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AlertCard(
                          alert: _alerts[i],
                          onTap: () => _showAlertDetail(_alerts[i]),
                        ),
                      ),
                      childCount: _alerts.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_greeting()},',
                style: AppTextStyles.footnote,
              ),
              Text(
                name.isNotEmpty ? name.split(' ').first : 'Harur',
                style: AppTextStyles.title2,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SubmitAlertPage()),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRail() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _CategoryChip(
            label: 'All',
            selected: _selectedCategory == null,
            color: AppColors.primary,
            onTap: () => setState(() {
              _selectedCategory = null;
              _load();
            }),
          ),
          const SizedBox(width: 8),
          ..._categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryChip(
                  label: cat.categoryLabel,
                  icon: cat.categoryIcon,
                  selected: _selectedCategory == cat,
                  color: cat.categoryColor,
                  onTap: () => setState(() {
                    _selectedCategory = _selectedCategory == cat ? null : cat;
                    _load();
                  }),
                ),
              )),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSkeletonSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: List.generate(5, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _AlertSkeleton(),
          )),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.tertiaryLabel),
          const SizedBox(height: 12),
          Text('Could not load alerts', style: AppTextStyles.subheadline),
          const SizedBox(height: 16),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedCategory?.categoryIcon ?? '📢',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'No alerts right now',
            style: AppTextStyles.title3,
          ),
          const SizedBox(height: 6),
          Text(
            'Harur is quiet. Tap + to report something.',
            style: AppTextStyles.footnote,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ── Category Chip ──────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final String? icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.20),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alert Card ─────────────────────────────────────────────────────────────────
class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;

  const AlertCard({super.key, required this.alert, this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = alert.category.categoryColor;
    final isPending = alert.isPending;
    final isEmergency = alert.emergencyTagged;

    return GlassCard(
      onTap: onTap,
      fillColor: Colors.white.withValues(alpha: isPending ? 0.7 : 0.95),
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      shadows: isEmergency
          ? [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.20),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 60,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: catColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(alert.category.categoryIcon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    PillBadge(
                      label: alert.category.categoryLabel.toUpperCase(),
                      color: catColor,
                      dot: false,
                    ),
                    const Spacer(),
                    if (isEmergency)
                      const PillBadge(label: '🚨 EMERGENCY', color: AppColors.danger, dot: false),
                    if (isPending && !isEmergency)
                      const PillBadge(label: 'PENDING', color: AppColors.warning, dot: true),
                    const SizedBox(width: 6),
                    Text(
                      alert.timeAgo,
                      style: AppTextStyles.caption2,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alert.title,
                  style: AppTextStyles.headline.copyWith(
                    color: isPending ? AppColors.secondaryLabel : AppColors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  alert.body,
                  style: AppTextStyles.subheadline.copyWith(
                    color: AppColors.secondaryLabel,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (alert.wardName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.tertiaryLabel),
                      const SizedBox(width: 3),
                      Text(
                        alert.wardName!,
                        style: AppTextStyles.caption1,
                      ),
                      if (alert.isOfficial) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.verified_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          alert.publishedAsRole ?? 'Official',
                          style: AppTextStyles.caption1.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alert Detail Modal ─────────────────────────────────────────────────────────
class _AlertDetailModal extends StatelessWidget {
  final Alert alert;
  const _AlertDetailModal({required this.alert});

  @override
  Widget build(BuildContext context) {
    final catColor = alert.category.categoryColor;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Text(alert.category.categoryIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              PillBadge(
                label: alert.category.categoryLabel.toUpperCase(),
                color: catColor,
              ),
              const Spacer(),
              if (alert.emergencyTagged)
                const PillBadge(label: '🚨 EMERGENCY', color: AppColors.danger),
              const SizedBox(width: 8),
              Text(alert.timeAgo, style: AppTextStyles.caption1),
            ],
          ),
          const SizedBox(height: 14),

          Text(alert.title, style: AppTextStyles.title2),
          const SizedBox(height: 12),

          Text(
            alert.body,
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          if (alert.wardName != null || alert.publishedAsRole != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.systemBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  if (alert.wardName != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Location: ', style: AppTextStyles.caption1.copyWith(fontWeight: FontWeight.w600)),
                        Text(alert.wardName!, style: AppTextStyles.caption1),
                      ],
                    ),
                  if (alert.publishedAsRole != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Source: ', style: AppTextStyles.caption1.copyWith(fontWeight: FontWeight.w600)),
                        Text(alert.publishedAsRole!, style: AppTextStyles.caption1),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ── Alert Skeleton ─────────────────────────────────────────────────────────────
class _AlertSkeleton extends StatelessWidget {
  const _AlertSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SkeletonBox(width: 60, height: 22, borderRadius: 100),
            SizedBox(width: 8),
            SkeletonBox(width: 80, height: 22, borderRadius: 100),
            Spacer(),
            SkeletonBox(width: 40, height: 14),
          ]),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 18),
          SizedBox(height: 6),
          SkeletonBox(width: double.infinity, height: 14),
          SizedBox(height: 4),
          SkeletonBox(width: 200, height: 14),
        ],
      ),
    );
  }
}
