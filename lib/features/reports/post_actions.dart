import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/alert.dart';
import '../../core/services/alerts_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/safety_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// What a person can do with a post: delete it (author, or staff with a reason), report it, or hide its
// author. The database enforces every rule; these flows only ask the right question and say what happened.
// Each returns true when something changed, so the caller can refresh its list.
// ==============================================================================

bool isMine(Alert a) => a.createdByUid != null && a.createdByUid == AuthService.currentProfile.id;

/// Everything the "More" menu offers for [alert] to the signed-in person.
class PostPermissions {
  final bool canDelete;
  final bool canReport;
  const PostPermissions({required this.canDelete, required this.canReport});

  factory PostPermissions.of(Alert a) {
    final me = AuthService.currentProfile;
    final mine = isMine(a);
    return PostPermissions(
      canDelete: mine || me.isStaff,
      canReport: !mine && a.isPublished && !me.isGuest,
    );
  }

  bool get any => canDelete || canReport;
}

String reportReasonLabel(AppLocalizations t, String r) => switch (r) {
      'spam' => t.rrSpam,
      'false' => t.rrFalse,
      'abuse' => t.rrAbuse,
      'harassment' => t.rrHarassment,
      'inappropriate' => t.rrInappropriate,
      _ => t.rrOther,
    };

Future<bool> deletePostFlow(BuildContext context, Alert alert) async {
  final t = context.t;
  final messenger = ScaffoldMessenger.of(context);
  String? reason;
  if (isMine(alert)) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deletePost),
        content: Text(t.deletePostBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete, style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return false;
  } else {
    reason = await _askText(context, title: t.deletePost, label: t.deleteReasonLabel, confirm: t.delete, minLength: 5);
    if (reason == null) return false;
  }
  final err = await AlertsService.deleteContent(alert.id, reason: reason);
  messenger.showSnackBar(SnackBar(content: Text(err == null ? t.postDeleted : t.deleteFailed2)));
  return err == null;
}

Future<bool> reportPostFlow(BuildContext context, Alert alert) async {
  final t = context.t;
  final messenger = ScaffoldMessenger.of(context);
  final reason = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: Text(t.reportWhy, style: AppTextStyles.title3)),
            GroupedSection(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              children: [for (final r in reportReasons) GroupedRow(title: reportReasonLabel(t, r), onTap: () => Navigator.pop(ctx, r))],
            ),
          ],
        ),
      ),
    ),
  );
  if (reason == null) return false;
  final res = await SafetyService.reportContent(alert.id, reason);
  messenger.showSnackBar(SnackBar(
    content: Text(switch (res) {
      SafetyResult.ok => t.reportedMsg,
      SafetyResult.rateLimited => t.reportLimit,
      _ => t.reportFailed,
    }),
  ));
  return res == SafetyResult.ok;
}

Future<bool> blockAuthorFlow(BuildContext context, Alert alert) async {
  final t = context.t;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.blockAuthor),
      content: Text(t.blockBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.blockAuthor, style: const TextStyle(color: AppColors.danger))),
      ],
    ),
  );
  if (ok != true) return false;
  final res = await SafetyService.blockAuthor(alert.id);
  messenger.showSnackBar(SnackBar(content: Text(res == SafetyResult.ok ? t.blockedMsg : t.blockFailed)));
  return res == SafetyResult.ok;
}

/// A small text prompt. Returns the trimmed text, or null when cancelled.
Future<String?> _askText(BuildContext context, {required String title, required String label, required String confirm, int minLength = 1}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, autofocus: true, maxLength: 200, minLines: 1, maxLines: 3, decoration: InputDecoration(labelText: label), onChanged: (_) => setState(() {})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.t.cancel)),
          TextButton(
            onPressed: ctrl.text.trim().length >= minLength ? () => Navigator.pop(ctx, ctrl.text.trim()) : null,
            child: Text(confirm, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    ),
  );
}
