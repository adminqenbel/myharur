import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/admin_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../reports/post_actions.dart' show reportReasonLabel;

// ==============================================================================
// REPORTED USERS (admins): residents flag posts; 3 distinct reporters within 7 days restrict the author
// until an admin decides here. Dismiss / warn lift the automatic restriction; restrict / ban / reinstate need a
// written note (audit log). Staff accounts can only be acted on by a super admin. The database enforces all of it.
// ==============================================================================
class ReportedUsersPage extends StatefulWidget {
  const ReportedUsersPage({super.key});

  @override
  State<ReportedUsersPage> createState() => _ReportedUsersPageState();
}

class _ReportedUsersPageState extends State<ReportedUsersPage> {
  List<ReportedUser>? _users;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await AdminService.reportedUsers();
    if (!mounted) return;
    setState(() {
      _users = r ?? _users;
      _loading = false;
    });
  }

  Future<void> _open(ReportedUser u) async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _DecisionSheet(user: u));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final users = _users ?? const <ReportedUser>[];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.reportedUsers, showBack: true),
          refreshSliver(_load),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
          else if (users.isEmpty)
            SliverToBoxAdapter(child: EmptyState(icon: Icons.verified_user_rounded, title: t.ruNone))
          else
            SliverToBoxAdapter(
              child: GroupedSection(
                dividerIndent: 58,
                children: [
                  for (final u in users)
                    GroupedRow(
                      icon: u.restriction == 'banned' ? Icons.block_rounded : (u.restriction == 'restricted' ? Icons.lock_rounded : Icons.flag_rounded),
                      iconColor: u.restriction == 'none' ? AppColors.warning : AppColors.danger,
                      title: '${u.username}  ·  ${u.fullName}',
                      subtitle: [
                        t.ruReporters(u.reporters),
                        if (u.restriction == 'restricted') t.ruRestricted,
                        if (u.restriction == 'banned') t.ruBanned,
                        u.reasons.map((r) => reportReasonLabel(t, r)).join(', '),
                      ].where((e) => e.isNotEmpty).join(' · '),
                      chevron: true,
                      onTap: () => _open(u),
                    ),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _DecisionSheet extends StatefulWidget {
  final ReportedUser user;
  const _DecisionSheet({required this.user});

  @override
  State<_DecisionSheet> createState() => _DecisionSheetState();
}

class _DecisionSheetState extends State<_DecisionSheet> {
  final _note = TextEditingController();
  String? _busy;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _decide(String action) async {
    final t = context.t;
    final needsNote = action == 'restrict' || action == 'ban' || action == 'reinstate';
    if (needsNote && _note.text.trim().length < 5) {
      setState(() => _error = t.ruNeedNote);
      return;
    }
    setState(() {
      _busy = action;
      _error = null;
    });
    final err = await AdminService.resolveUserReport(widget.user.userId, action, note: _note.text.trim());
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = null;
        _error = switch (err) {
          'reason_required' => t.ruNeedNote,
          'superadmin_required' => t.ruSuperOnly,
          _ => t.ruFailed,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final u = widget.user;
    final restricted = u.restriction != 'none';
    Widget action(String key, String label, {Color? color, bool tinted = true}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PrimaryButton(label: label, tinted: tinted, color: color ?? AppColors.primary, loading: _busy == key, onPressed: _busy == null ? () => _decide(key) : null),
        );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${u.username}  ·  ${u.fullName}', style: AppTextStyles.title3),
              const SizedBox(height: 4),
              Text([t.ruReporters(u.reporters), u.reasons.map((r) => reportReasonLabel(t, r)).join(', ')].where((e) => e.isNotEmpty).join(' · '), style: AppTextStyles.footnote),
              if (u.sampleTitle != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('“${u.sampleTitle}”', style: AppTextStyles.subheadline)),
              const SizedBox(height: 14),
              TextField(controller: _note, maxLength: 200, decoration: InputDecoration(labelText: t.ruNoteLabel)),
              if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
              action('dismiss', t.ruDismiss),
              action('warn', t.ruWarn),
              action('restrict', t.ruRestrict, color: AppColors.warning),
              action('ban', t.ruBan, color: AppColors.danger),
              if (restricted) action('reinstate', t.ruReinstate, color: AppColors.success),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// BUG REPORTS (super admins only): what users sent through "Report a bug", plus the crash and sign-in
// error reports the app files by itself. Mark them seen / fixed as you work through them.
// ==============================================================================
class BugReportsPage extends StatefulWidget {
  const BugReportsPage({super.key});

  @override
  State<BugReportsPage> createState() => _BugReportsPageState();
}

class _BugReportsPageState extends State<BugReportsPage> {
  List<BugReport>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await AdminService.bugReports();
    if (!mounted) return;
    setState(() {
      _items = r ?? _items;
      _loading = false;
    });
  }

  Future<void> _open(BugReport b) async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _BugSheet(report: b));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final items = _items ?? const <BugReport>[];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.bugReports, showBack: true),
          refreshSliver(_load),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
          else if (items.isEmpty)
            SliverToBoxAdapter(child: EmptyState(icon: Icons.bug_report_outlined, title: t.bugNone))
          else
            SliverToBoxAdapter(
              child: GroupedSection(
                dividerIndent: 58,
                children: [
                  for (final b in items)
                    GroupedRow(
                      icon: b.kind == 'bug' ? Icons.bug_report_rounded : Icons.error_outline_rounded,
                      iconColor: b.status == 'fixed' ? AppColors.success : (b.status == 'seen' ? AppColors.tertiaryLabel : AppColors.warning),
                      title: b.message.isEmpty ? b.kind : b.message,
                      subtitle: '${_statusName(t, b.status)} · ${context.timeAgo(b.createdAt)} · ${b.appVersion}',
                      chevron: true,
                      onTap: () => _open(b),
                    ),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

String _statusName(AppLocalizations t, String s) => switch (s) {
      'fixed' => t.bugFixed,
      'seen' => t.bugSeen,
      _ => t.bugNew,
    };

class _BugSheet extends StatelessWidget {
  final BugReport report;
  const _BugSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    Future<void> mark(String status) async {
      final nav = Navigator.of(context);
      await AdminService.setBugStatus(report.id, status);
      nav.pop();
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(report.message, style: AppTextStyles.title3),
            const SizedBox(height: 4),
            Text('${report.kind} · ${report.appVersion} · ${report.os}', style: AppTextStyles.footnote),
            if (report.details.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(report.details, style: AppTextStyles.body),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: PrimaryButton(label: t.bugSeen, tinted: true, onPressed: () => mark('seen'))),
              const SizedBox(width: 10),
              Expanded(child: PrimaryButton(label: t.bugFixed, onPressed: () => mark('fixed'))),
            ]),
          ],
        ),
      ),
    );
  }
}
