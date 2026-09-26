import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/admin_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// LOCKED SIGN-INS (super admin). Accounts whose @username + password sign-in was paused after repeated
// wrong guesses. Recovering one needs a written reason and a two-factor session; the database checks both.
// Google sign-in is never affected by these locks.
// ==============================================================================
class LockedLoginsPage extends StatefulWidget {
  const LockedLoginsPage({super.key});

  @override
  State<LockedLoginsPage> createState() => _LockedLoginsPageState();
}

class _LockedLoginsPageState extends State<LockedLoginsPage> {
  List<LockedLogin>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await AdminService.lockedLogins();
    if (!mounted) return;
    setState(() {
      _items = r ?? _items;
      _loading = false;
    });
  }

  Future<void> _open(LockedLogin l) async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _RecoverSheet(login: l));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final items = _items ?? const <LockedLogin>[];
    final fmt = DateFormat.MMMd(Localizations.localeOf(context).languageCode).add_jm();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.adminLocked, showBack: true),
          refreshSliver(_load),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
          else if (items.isEmpty)
            SliverToBoxAdapter(child: EmptyState(icon: Icons.lock_open_rounded, title: t.lockedNone))
          else
            SliverToBoxAdapter(
              child: GroupedSection(
                dividerIndent: 58,
                children: [
                  for (final l in items)
                    GroupedRow(
                      icon: l.permanent ? Icons.lock_rounded : Icons.timer_outlined,
                      iconColor: l.permanent ? AppColors.danger : AppColors.warning,
                      title: '${l.username}  ·  ${l.fullName}',
                      subtitle: l.permanent || l.lockedUntil == null ? t.lockedOff : t.lockedPaused(fmt.format(l.lockedUntil!)),
                      chevron: true,
                      onTap: () => _open(l),
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

class _RecoverSheet extends StatefulWidget {
  final LockedLogin login;
  const _RecoverSheet({required this.login});

  @override
  State<_RecoverSheet> createState() => _RecoverSheetState();
}

class _RecoverSheetState extends State<_RecoverSheet> {
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _password; // shown once

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _recover() async {
    final t = context.t;
    if (_reason.text.trim().length < 10) {
      setState(() => _error = t.recoverErrReason);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await AdminService.recoverLogin(widget.login.userId, _reason.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _password = r.temporaryPassword;
      _error = r.ok
          ? null
          : switch (r.error) {
              'aal2_required' => t.recoverErrAal2,
              'reason_required' => t.recoverErrReason,
              'network' => t.authNetwork,
              _ => t.recoverErrGeneric,
            };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: _password != null ? _shown(context, _password!) : _form(context),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.recoverTitle, style: AppTextStyles.title2),
        const SizedBox(height: 4),
        Text('${widget.login.username}  ·  ${widget.login.fullName}', style: AppTextStyles.subheadline),
        const SizedBox(height: 12),
        Text(t.recoverBody, style: AppTextStyles.footnote),
        const SizedBox(height: 14),
        TextField(controller: _reason, maxLength: 300, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: t.recoverReason)),
        if (_error != null)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
        const SizedBox(height: 8),
        PrimaryButton(label: t.recoverAction, loading: _busy, onPressed: _recover),
      ],
    );
  }

  Widget _shown(BuildContext context, String password) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.tempPasswordTitle, style: AppTextStyles.title2),
        const SizedBox(height: 8),
        Text(t.tempPasswordBody, style: AppTextStyles.footnote),
        const SizedBox(height: 16),
        Center(
          child: SelectableText(password, style: AppTextStyles.title2.copyWith(letterSpacing: 1.5, fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: t.copyAction,
          tinted: true,
          icon: Icons.copy_rounded,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: password));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.copied)));
          },
        ),
        const SizedBox(height: 8),
        PrimaryButton(label: t.done, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
