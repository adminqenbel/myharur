import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import 'ads_admin_page.dart';
import 'feature_flags_page.dart';
import 'locked_logins_page.dart';
import 'moderation_tools_pages.dart';

// ==============================================================================
// ADMIN PANEL — overview numbers, users & roles, word filters.
// Reachable from Account for admins and super admins. The database enforces every
// rule (who may grant which role, the 3-super-admin cap, ...); this UI just hides
// what the signed-in user cannot use.
// ==============================================================================
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AdminService.stats();
    if (!mounted) return;
    setState(() {
      _stats = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isSuper = AuthService.currentProfile.isSuperAdmin;
    final s = _stats;

    String n(String k) => s == null ? '–' : '${s[k] ?? 0}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.adminTitle, showBack: true),
          refreshSliver(_load),
          SliverList.list(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: Text(t.adminOverview, style: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (_loading)
              const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()))
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 22),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _Stat(label: t.statUsers, value: n('users'), color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _Stat(label: t.statStaff, value: n('staff'), color: AppColors.govt)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _Stat(label: t.statPending, value: n('pending_alerts'), color: AppColors.warning)),
                    const SizedBox(width: 12),
                    Expanded(child: _Stat(label: t.statPublished, value: n('published_alerts'), color: AppColors.success)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _Stat(label: t.statAutoRejected, value: n('auto_rejected'), color: AppColors.danger)),
                    const SizedBox(width: 12),
                    Expanded(child: _Stat(label: t.statNews, value: n('news_articles'), color: AppColors.weatherBlue)),
                  ]),
                ]),
              ),
            GroupedSection(
              dividerIndent: 58,
              children: [
                GroupedRow(
                  icon: Icons.groups_rounded,
                  iconColor: AppColors.primary,
                  title: t.adminUsers,
                  subtitle: t.adminUsersSub,
                  chevron: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUsersPage())),
                ),
                if (isSuper)
                  GroupedRow(
                    icon: Icons.filter_alt_rounded,
                    iconColor: AppColors.warning,
                    title: t.adminFilters,
                    subtitle: t.adminFiltersSub,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminFiltersPage())),
                  ),
                GroupedRow(
                  icon: Icons.flag_rounded,
                  iconColor: AppColors.warning,
                  title: t.reportedUsers,
                  subtitle: t.reportedUsersSub,
                  chevron: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportedUsersPage())),
                ),
                if (isSuper)
                  GroupedRow(
                    icon: Icons.bug_report_rounded,
                    iconColor: AppColors.road,
                    title: t.bugReports,
                    subtitle: t.bugReportsSub,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BugReportsPage())),
                  ),
                if (isSuper)
                  GroupedRow(
                    icon: Icons.lock_person_rounded,
                    iconColor: AppColors.danger,
                    title: t.adminLocked,
                    subtitle: t.adminLockedSub,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LockedLoginsPage())),
                  ),
              ],
            ),
            if (isSuper)
              GroupedSection(
                dividerIndent: 58,
                children: [
                  GroupedRow(
                    icon: Icons.toggle_on_rounded,
                    iconColor: AppColors.primary,
                    title: t.featureFlags,
                    subtitle: t.featureFlagsSub,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeatureFlagsPage())),
                  ),
                  GroupedRow(
                    icon: Icons.campaign_rounded,
                    iconColor: AppColors.weatherViolet,
                    title: t.adsAdmin,
                    subtitle: t.adsAdminSub,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdsAdminPage())),
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.title1.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.footnote, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Users & roles ──────────────────────────────────────────────────────────────
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<AdminUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final r = await AdminService.searchUsers(_search.text);
    if (!mounted) return;
    setState(() {
      _users = r ?? _users;
      _loading = false;
    });
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _run);
  }

  Future<void> _open(AdminUser u) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RoleSheet(user: u),
    );
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.adminUsers, showBack: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, 14),
              child: TextField(
                controller: _search,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: t.searchUsers,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.tertiaryLabel),
                  fillColor: AppColors.fill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
          else if (_users.isEmpty)
            SliverToBoxAdapter(child: EmptyState(icon: Icons.person_search_rounded, title: t.noResults))
          else
            SliverToBoxAdapter(
              child: GroupedSection(
                dividerIndent: 72,
                children: [
                  for (final u in _users)
                    InkWell(
                      onTap: () => _open(u),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Avatar(url: u.avatarUrl, name: u.fullName, size: 40),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.fullName, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(u.email ?? u.username ?? '', style: AppTextStyles.footnote, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (u.roles.any((r) => r != 'resident'))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(spacing: 4, children: [
                                        for (final r in u.roles.where((r) => r != 'resident')) Tag(label: _roleLabel(t, r), color: AppColors.govt),
                                      ]),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.quaternaryLabel),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

String _roleLabel(AppLocalizations t, String role) {
  switch (role) {
    case 'moderator': return t.roleModerator;
    case 'govt_official': return t.roleGovt;
    case 'admin': return t.roleAdmin;
    case 'superadmin': return t.roleSuperadmin;
    default: return t.roleResident;
  }
}

class _RoleSheet extends StatefulWidget {
  final AdminUser user;
  const _RoleSheet({required this.user});

  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends State<_RoleSheet> {
  late final Set<String> _roles = {...widget.user.roles};
  String? _busy;

  Future<void> _toggle(String role, bool grant) async {
    final t = context.t;
    setState(() => _busy = role);
    final err = await AdminService.setRole(widget.user.id, role, grant: grant);
    if (!mounted) return;
    setState(() {
      _busy = null;
      if (err == null) {
        grant ? _roles.add(role) : _roles.remove(role);
      }
    });
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendly(t, err))));
    } else if (widget.user.id == AuthService.currentUser?.id) {
      AuthService.refreshProfile();
    }
  }

  String _friendly(AppLocalizations t, String err) {
    if (err.contains('superadmin_limit_reached')) return '${t.roleFailed} (max 3)';
    if (err.contains('last_superadmin')) return '${t.roleFailed} (last super admin)';
    return t.roleFailed;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isSuper = AuthService.currentProfile.isSuperAdmin;
    final u = widget.user;

    Widget row(String role, IconData icon, Color color, {bool superOnly = false}) {
      final allowed = !superOnly || isSuper;
      return GroupedRow(
        icon: icon,
        iconColor: color,
        title: _roleLabel(t, role),
        trailing: _busy == role
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : Switch.adaptive(value: _roles.contains(role), onChanged: allowed && _busy == null ? (v) => _toggle(role, v) : null),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                Avatar(url: u.avatarUrl, name: u.fullName, size: 44),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.rolesFor(u.fullName), style: AppTextStyles.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (u.email != null) Text(u.email!, style: AppTextStyles.footnote, maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ),
            GroupedSection(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              dividerIndent: 58,
              children: [
                row('moderator', Icons.fact_check_rounded, AppColors.warning),
                row('govt_official', Icons.account_balance_rounded, AppColors.govt),
                row('admin', Icons.admin_panel_settings_rounded, AppColors.primary, superOnly: true),
                row('superadmin', Icons.shield_rounded, AppColors.weatherRed, superOnly: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Word filters ───────────────────────────────────────────────────────────────
class AdminFiltersPage extends StatefulWidget {
  const AdminFiltersPage({super.key});

  @override
  State<AdminFiltersPage> createState() => _AdminFiltersPageState();
}

class _AdminFiltersPageState extends State<AdminFiltersPage> {
  int _tab = 0; // 0 = blocked (profanity), 1 = flagged (danger)
  List<FilterTerm> _terms = [];
  bool _loading = true;

  String get _kind => _tab == 0 ? 'profanity' : 'danger';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await AdminService.filterTerms();
    if (!mounted) return;
    setState(() {
      _terms = r ?? _terms;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddWordSheet(kind: _kind),
    );
    if (added == true) _load();
  }

  Future<void> _remove(FilterTerm term) async {
    await AdminService.deleteTerm(term.kind, term.term);
    _load();
  }

  String _detail(AppLocalizations t, FilterTerm f) {
    if (f.kind == 'profanity') {
      switch (f.detail) {
        case 'tamil_unicode': return t.tamilScript;
        case 'tamil_tanglish': return t.tamilTanglish;
        default: return t.englishWord;
      }
    }
    return f.detail;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final shown = _terms.where((f) => f.kind == _kind).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.adminFilters, showBack: true, trailing: BarIconButton(icon: Icons.add_rounded, tooltip: t.addWord, onTap: _add)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, 8),
              child: SegmentedPill(labels: [t.blockedWords, t.flaggedWords], selected: _tab, onChanged: (i) => setState(() => _tab = i)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Text(_tab == 0 ? t.blockedWordsNote : t.flaggedWordsNote, style: AppTextStyles.footnote),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
          else if (shown.isEmpty)
            SliverToBoxAdapter(child: EmptyState(icon: Icons.filter_alt_off_rounded, title: t.noWords, actionLabel: t.addWord, onAction: _add))
          else
            SliverToBoxAdapter(
              child: GroupedSection(
                children: [
                  for (final f in shown)
                    GroupedRow(
                      title: f.term,
                      subtitle: _detail(t, f),
                      trailing: GestureDetector(
                        onTap: () => _remove(f),
                        child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove_circle_rounded, color: AppColors.danger, size: 22)),
                      ),
                    ),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _AddWordSheet extends StatefulWidget {
  final String kind;
  const _AddWordSheet({required this.kind});

  @override
  State<_AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends State<_AddWordSheet> {
  final _ctrl = TextEditingController();
  String _script = 'tamil_tanglish';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t;
    if (_ctrl.text.trim().length < 2) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    final ok = await AdminService.saveTerm(widget.kind, _ctrl.text, widget.kind == 'profanity' ? _script : 'flag');
    if (!mounted) return;
    if (ok) {
      nav.pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = t.wordFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.addWord, style: AppTextStyles.title2),
              const SizedBox(height: 14),
              TextField(controller: _ctrl, autofocus: true, decoration: InputDecoration(labelText: t.addWordHint)),
              if (widget.kind == 'profanity') ...[
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilterPill(label: t.tamilTanglish, selected: _script == 'tamil_tanglish', onTap: () => setState(() => _script = 'tamil_tanglish')),
                  FilterPill(label: t.tamilScript, selected: _script == 'tamil_unicode', onTap: () => setState(() => _script = 'tamil_unicode')),
                  FilterPill(label: t.englishWord, selected: _script == 'english', onTap: () => setState(() => _script = 'english')),
                ]),
              ],
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
              const SizedBox(height: 18),
              PrimaryButton(label: t.addWord, loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
