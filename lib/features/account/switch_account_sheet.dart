import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/account_store.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../auth/auth_page.dart';

/// "Switch account": the people signed in on this phone (up to three), plus "Add another account".
Future<void> showSwitchAccountSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SwitchAccountSheet(),
    );

class _SwitchAccountSheet extends StatefulWidget {
  const _SwitchAccountSheet();

  @override
  State<_SwitchAccountSheet> createState() => _SwitchAccountSheetState();
}

class _SwitchAccountSheetState extends State<_SwitchAccountSheet> {
  String? _switchingTo;
  String? _message;

  Future<void> _switch(SavedAccount a) async {
    final t = context.t;
    if (_switchingTo != null) return;
    setState(() {
      _switchingTo = a.id;
      _message = null;
    });
    final ok = await AuthService.switchTo(a.id);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _switchingTo = null;
        _message = t.switchFailed;
      });
    }
  }

  Future<void> _add() async {
    final t = context.t;
    final full = AccountStore.accounts.value.where((a) => a.id != AuthService.currentProfile.id).length >= AccountStore.maxAccounts - 1;
    if (full) {
      setState(() => _message = t.accountsLimit);
      return;
    }
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const AuthPage(addingAccount: true)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SafeArea(
      child: ValueListenableBuilder<List<SavedAccount>>(
        valueListenable: AccountStore.accounts,
        builder: (context, saved, _) {
          final current = AuthService.currentProfile;
          // the signed-in account is always listed first, even before it has been saved
          final list = [
            if (!saved.any((a) => a.id == current.id))
              SavedAccount(id: current.id, name: current.fullName, username: current.username, avatarUrl: AuthService.avatarUrl, refreshToken: '-'),
            ...saved,
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text(t.switchAccount, style: AppTextStyles.title2),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(t.switchAccountSub, style: AppTextStyles.footnote),
                ),
                for (final a in list)
                  ListTile(
                    key: ValueKey('acct-${a.id}'),
                    leading: Avatar(url: a.avatarUrl, name: a.name, size: 40),
                    title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(a.username.startsWith('@') ? a.username : '@${a.username}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: a.id == current.id
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : _switchingTo == a.id
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
                            : IconButton(
                                tooltip: t.removeFromPhone,
                                icon: const Icon(Icons.close_rounded, color: AppColors.tertiaryLabel),
                                onPressed: () => AccountStore.remove(a.id),
                              ),
                    onTap: a.id == current.id ? null : () => _switch(a),
                  ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.fill, child: Icon(Icons.add_rounded, color: AppColors.primary)),
                  title: Text(t.addAccount, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  onTap: _add,
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(_message!, style: AppTextStyles.footnote.copyWith(color: AppColors.danger)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
