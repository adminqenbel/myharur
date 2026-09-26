import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/alert.dart';
import '../../core/services/alerts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../reports/photo_widgets.dart';

// ==============================================================================
// REVIEW QUEUE — pending reports for moderators, admins and super admins.
// Reports arrive after the automated filter. Any staff member can approve (live for
// 7 days) or reject with a reason. The database enforces who may do this
// (moderate_alert()); this screen is only reachable from the staff section of Account.
// ==============================================================================
class ModerationPage extends StatefulWidget {
  /// True when shown as the Review tab (no back button); false when pushed as a page.
  final bool asTab;
  const ModerationPage({super.key, this.asTab = false});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  List<Alert> _queue = [];
  bool _loading = true;
  bool _error = false;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = _queue.isEmpty);
    final queue = await AlertsService.fetchReviewQueue();
    if (!mounted) return;
    setState(() {
      if (queue != null) _queue = queue;
      _loading = false;
      _error = queue == null && _queue.isEmpty;
    });
  }

  Future<void> _decide(Alert alert, {String? rejectReason}) async {
    final t = context.t;
    setState(() => _busy.add(alert.id));
    final ok = rejectReason == null ? await AlertsService.approve(alert.id) : await AlertsService.reject(alert.id, rejectReason);
    if (!mounted) return;
    setState(() => _busy.remove(alert.id));

    if (ok) {
      setState(() => _queue.removeWhere((a) => a.id == alert.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.decisionFailed)));
      _load(); // resync: another moderator may have handled it
    }
  }

  Future<void> _askReason(Alert alert) async {
    final t = context.t;
    final reasons = {
      'spam': t.reasonSpam,
      'false': t.reasonFalse,
      'duplicate': t.reasonDuplicate,
      'low_quality': t.reasonLowQuality,
      'inappropriate': t.reasonInappropriate,
    };
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: Text(t.rejectTitle, style: AppTextStyles.title3)),
              GroupedSection(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                footer: alert.emergencyTagged ? t.rejectStrikeNote : null,
                children: [for (final e in reasons.entries) GroupedRow(title: e.value, onTap: () => Navigator.pop(ctx, e.key))],
              ),
            ],
          ),
        ),
      ),
    );
    if (reason != null) await _decide(alert, rejectReason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.reviewTitle, showBack: !widget.asTab),
          refreshSliver(_load),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())))
          else if (_error)
            SliverToBoxAdapter(child: EmptyState(icon: Icons.wifi_off_rounded, title: t.reviewLoadFailed, actionLabel: t.retry, onAction: _load))
          else if (_queue.isEmpty)
            SliverToBoxAdapter(child: EmptyState(icon: Icons.task_alt_rounded, title: t.allCaughtUp, body: t.nothingWaiting))
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(t.reviewCount(_queue.length), style: AppTextStyles.callout.copyWith(color: AppColors.secondaryLabel)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 32),
              sliver: SliverList.separated(
                itemCount: _queue.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ReviewCard(
                  alert: _queue[i],
                  busy: _busy.contains(_queue[i].id),
                  onApprove: () => _decide(_queue[i]),
                  onReject: () => _askReason(_queue[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Alert alert;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ReviewCard({required this.alert, required this.busy, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final flagLabels = {'dangerous_terms': t.flagDangerous, 'link': t.flagLink, 'phone_number': t.flagPhone};
    final flags = alert.moderationFlags.where(flagLabels.containsKey).map((f) => flagLabels[f]!).toList();

    return AppCard(
      color: alert.emergencyTagged ? const Color(0xFFFFF4F3) : AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: alert.category.categoryIconData, color: alert.category.categoryColor, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.categoryName(alert.category), style: AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.w600)),
                    Text([context.timeAgo(alert.createdAt), if ((alert.location?.text ?? '').trim().isNotEmpty) alert.location!.text.trim()].join(' · '), style: AppTextStyles.caption1, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (alert.emergencyTagged) Tag(label: t.emergency, color: AppColors.danger, icon: Icons.warning_amber_rounded),
            ],
          ),
          if (flags.isNotEmpty || alert.isOfficial || alert.isNews) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (alert.isNews) Tag(label: t.tagNews, color: AppColors.weatherBlue, icon: Icons.newspaper_rounded),
              if (alert.isOfficial) Tag(label: t.staffAuthor, color: AppColors.govt, icon: Icons.badge_rounded),
              for (final f in flags) Tag(label: f, color: AppColors.warning, icon: Icons.flag_rounded),
            ]),
          ],
          const SizedBox(height: 12),
          Text(alert.title, style: AppTextStyles.headline),
          const SizedBox(height: 4),
          Text(alert.body, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
          if (alert.linkUrl != null && alert.linkUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.link_rounded, size: 16, color: AppColors.tertiaryLabel),
                const SizedBox(width: 6),
                Expanded(child: Text(alert.linkUrl!, style: AppTextStyles.footnote, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          if (alert.imagePaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            PhotoStrip(paths: alert.imagePaths, height: 110),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: PrimaryButton(label: t.reject, tinted: true, color: AppColors.danger, onPressed: busy ? null : onReject)),
              const SizedBox(width: 10),
              Expanded(child: PrimaryButton(label: t.approve, loading: busy, onPressed: busy ? null : onApprove)),
            ],
          ),
        ],
      ),
    );
  }
}
