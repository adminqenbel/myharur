import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/alert.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/safe_launch.dart';
import '../../core/widgets/ui.dart';
import '../map/location_preview.dart';
import 'photo_widgets.dart';
import 'post_actions.dart';

/// "Tue, 15 Sep" or, with a time, "Tue, 15 Sep · 6:30 PM".
String _formatWhen(BuildContext context, DateTime d, {required bool withTime}) {
  final lang = Localizations.localeOf(context).languageCode;
  final date = DateFormat('EEE, d MMM', lang).format(d);
  return withTime ? '$date · ${DateFormat.jm(lang).format(d)}' : date;
}

// ── Alert card ─────────────────────────────────────────────────────────────────
/// A report or news card. [compact] is the fixed-height variant used in Home's sliding rail.
class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;
  final bool compact;
  const AlertCard({super.key, required this.alert, this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = alert.category.categoryColor;
    final emergency = alert.emergencyTagged;
    final place = alert.location?.text.trim() ?? '';
    final subtitle = switch (alert.kind) {
      'event' when alert.startsAt != null => _formatWhen(context, alert.startsAt!, withTime: !alert.allDay),
      'job' when alert.employer != null && alert.employer!.isNotEmpty => alert.employer!,
      _ => [context.timeAgo(alert.createdAt), if (place.isNotEmpty) place].join(' · '),
    };

    return AppCard(
      onTap: onTap,
      color: emergency ? const Color(0xFFFFF4F3) : AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact && alert.imagePaths.isNotEmpty) ...[
            NetworkPhoto(path: alert.imagePaths.first, height: 150, width: double.infinity),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              IconTile(icon: alert.category.categoryIconData, color: color, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.categoryName(alert.category), style: AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: AppTextStyles.caption1, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (emergency) Tag(label: t.emergency, color: AppColors.danger, icon: Icons.warning_amber_rounded),
              if (alert.isOfficial && !emergency) Tag(label: t.official, color: AppColors.primary, icon: Icons.verified_rounded),
              if (alert.isNews && !alert.isOfficial) Tag(label: t.tagCommunity, color: AppColors.tertiaryLabel, icon: Icons.groups_rounded),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          Text(alert.title, style: AppTextStyles.headline, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            alert.body,
            style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel),
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Alert detail (bottom sheet) ────────────────────────────────────────────────
/// [onChanged] runs after the post was deleted, reported or its author hidden, so the list can refresh.
void showAlertDetail(BuildContext context, Alert alert, {VoidCallback? onChanged}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => AlertDetail(alert: alert, onChanged: onChanged),
  );
}

class AlertDetail extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onChanged;
  const AlertDetail({super.key, required this.alert, this.onChanged});

  Future<void> _act(BuildContext context, Future<bool> Function(BuildContext, Alert) flow, {bool closeOnDone = true}) async {
    final nav = Navigator.of(context);
    final changed = await flow(context, alert);
    if (!changed) return;
    onChanged?.call();
    if (closeOnDone) nav.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = alert.category.categoryColor;
    final perms = PostPermissions.of(alert);
    final link = alert.linkUrl;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconTile(icon: alert.category.categoryIconData, color: color, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.categoryName(alert.category), style: AppTextStyles.headline),
                      Text(context.timeAgo(alert.createdAt), style: AppTextStyles.footnote),
                    ],
                  ),
                ),
                if (alert.emergencyTagged) Tag(label: t.emergency, color: AppColors.danger, icon: Icons.warning_amber_rounded),
                if (perms.any)
                  PopupMenuButton<String>(
                    tooltip: t.postActions,
                    icon: const Icon(Icons.more_horiz_rounded, color: AppColors.secondaryLabel),
                    onSelected: (v) {
                      switch (v) {
                        case 'report':
                          _act(context, reportPostFlow, closeOnDone: false);
                        case 'block':
                          _act(context, blockAuthorFlow);
                        case 'delete':
                          _act(context, deletePostFlow);
                      }
                    },
                    itemBuilder: (_) => [
                      if (perms.canReport) PopupMenuItem(value: 'report', child: Text(t.reportPost)),
                      if (perms.canReport) PopupMenuItem(value: 'block', child: Text(t.blockAuthor)),
                      if (perms.canDelete) PopupMenuItem(value: 'delete', child: Text(t.deletePost, style: const TextStyle(color: AppColors.danger))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (alert.imagePaths.isNotEmpty) ...[
              PhotoStrip(paths: alert.imagePaths),
              const SizedBox(height: 16),
            ],
            Text(alert.title, style: AppTextStyles.title2),
            const SizedBox(height: 10),
            Text(alert.body, style: AppTextStyles.body.copyWith(color: AppColors.secondaryLabel, height: 1.45)),
            if (alert.isEvent) ...[
              const SizedBox(height: 16),
              GroupedSection(
                margin: EdgeInsets.zero,
                dividerIndent: 58,
                children: [
                  if (alert.startsAt != null)
                    GroupedRow(icon: Icons.event_rounded, iconColor: AppColors.primary, title: t.eventStarts, value: _formatWhen(context, alert.startsAt!, withTime: !alert.allDay)),
                  if (alert.endsAt != null)
                    GroupedRow(icon: Icons.event_available_rounded, iconColor: AppColors.tertiaryLabel, title: t.eventEnds, value: _formatWhen(context, alert.endsAt!, withTime: !alert.allDay)),
                  if (alert.isPaid)
                    GroupedRow(icon: Icons.confirmation_number_outlined, iconColor: AppColors.warning, title: t.eventPaid),
                ],
              ),
            ],
            if (alert.isJob) ...[
              const SizedBox(height: 16),
              GroupedSection(
                margin: EdgeInsets.zero,
                dividerIndent: 58,
                footer: t.jobScamWarning,
                children: [
                  if (alert.employer != null && alert.employer!.isNotEmpty)
                    GroupedRow(icon: Icons.storefront_rounded, iconColor: AppColors.primary, title: t.jobEmployer, value: alert.employer),
                  if (alert.contactText != null && alert.contactText!.isNotEmpty)
                    GroupedRow(icon: Icons.call_rounded, iconColor: AppColors.tertiaryLabel, title: t.jobContact, value: alert.contactText),
                  if (alert.payText != null && alert.payText!.isNotEmpty)
                    GroupedRow(icon: Icons.payments_outlined, iconColor: AppColors.tertiaryLabel, title: t.jobPay, value: alert.payText),
                  if (alert.endsAt != null)
                    GroupedRow(icon: Icons.event_busy_rounded, iconColor: AppColors.danger, title: t.closesOn, value: _formatWhen(context, alert.endsAt!, withTime: true)),
                ],
              ),
            ],
            if (link != null && link.isNotEmpty) ...[
              const SizedBox(height: 16),
              PrimaryButton(label: t.openLink, tinted: true, icon: Icons.open_in_new_rounded, onPressed: () => safeLaunch(link)),
            ],
            if (alert.location != null) ...[
              const SizedBox(height: 20),
              LocationPreview(location: alert.location!),
            ],
            if (alert.publishedAsRole != null) ...[
              const SizedBox(height: 20),
              GroupedSection(
                margin: EdgeInsets.zero,
                dividerIndent: 58,
                children: [GroupedRow(icon: Icons.verified_rounded, iconColor: AppColors.primary, title: t.source, value: alert.publishedAsRole)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FeedSkeleton extends StatelessWidget {
  final int count;
  const FeedSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [SkeletonBox(width: 34, height: 34, radius: 10), SizedBox(width: 10), SkeletonBox(width: 110, height: 14)]),
                SizedBox(height: 14),
                SkeletonBox(height: 16),
                SizedBox(height: 8),
                SkeletonBox(height: 12),
                SizedBox(height: 6),
                SkeletonBox(width: 180, height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
