import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/place.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/account_store.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../admin/admin_panel_page.dart';
import '../common/language_switch.dart';
import '../help/help_page.dart';
import '../support/support_bot_page.dart';
import '../map/address_picker.dart';
import '../security/mfa_pages.dart';
import '../security/phone_signin_sheet.dart';
import 'bug_report_sheet.dart';
import 'my_posts_page.dart';
import 'notifications_page.dart';
import 'switch_account_sheet.dart';
import 'privacy_page.dart';

// ==============================================================================
// ACCOUNT: Google profile, security by QenShar, profile details, language, sign-in options,
// help. Staff tools live here too (admin panel); the Review queue is its own tab.
// ==============================================================================
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Future<void> _refresh() async {
    await AuthService.refreshProfile();
    await AuthService.refreshMfa();
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _signOut() async {
    final t = context.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.signOut),
        content: Text(t.signOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.signOut, style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) await AuthService.signOut();
  }

  Future<void> _deleteAccount() async {
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteTitle),
        content: Text(t.deleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete, style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await AuthService.deleteAccount();
    if (!deleted) messenger.showSnackBar(SnackBar(content: Text(t.deleteFailed)));
  }

  Future<void> _editAddress() async {
    final picked = await pickLocation(context, initial: AuthService.currentProfile.address);
    if (picked == null) return; // cancelled
    final ok = await AuthService.saveProfile(address: picked, clearAddress: picked.isEmpty);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? context.t.profileUpdated : context.t.saveFailed)));
  }

  void _editProfile() => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _EditProfileSheet());

  void _setPassword() => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _PasswordSheet());

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AuthNotifier.instance, AuthService.mfa]),
      builder: (context, _) {
        final t = context.t;
        final p = AuthService.currentProfile;
        final email = p.email.isNotEmpty ? p.email : (AuthService.currentUser?.email ?? '');
        final google = AuthService.hasGoogleIdentity;
        final mfa = AuthService.mfa.value;
        final mfaOn = mfa == MfaStatus.satisfied || mfa == MfaStatus.needsChallenge;

        String value(String v) => v.isEmpty ? t.notSet : v;

        return CustomScrollView(
          slivers: [
            LargeTitleSliver(title: t.accountTitle),
            refreshSliver(_refresh),
            SliverList.list(children: [
              // Google profile
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, 14),
                child: AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Avatar(url: AuthService.avatarUrl, name: p.fullName, size: 68),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.fullName, style: AppTextStyles.title3, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (email.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(email, style: AppTextStyles.footnote, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              Tag(label: _roleName(t, p), color: p.isSuperAdmin ? AppColors.weatherRed : (p.isStaff ? AppColors.govt : AppColors.primary), icon: p.isStaff ? Icons.shield_rounded : null),
                              Tag(label: google ? 'Google' : 'Email', color: AppColors.tertiaryLabel, icon: google ? Icons.verified_user_rounded : Icons.mail_rounded),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Security by QenShar
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 22),
                child: AppCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPage())),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: ShapeDecoration(color: AppColors.background, shape: squircle(14)),
                        child: Image.asset('assets/brand/qenshar.png', height: 40, fit: BoxFit.contain, semanticLabel: 'QenShar'),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.qenSharTitle, style: AppTextStyles.headline),
                            Text(t.qenSharSub, style: AppTextStyles.footnote),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.quaternaryLabel),
                    ],
                  ),
                ),
              ),

              if (p.isAdmin)
                GroupedSection(
                  header: t.staffTools,
                  dividerIndent: 58,
                  children: [
                    GroupedRow(
                      icon: Icons.admin_panel_settings_rounded,
                      iconColor: AppColors.govt,
                      title: t.adminPanel,
                      chevron: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPanelPage())),
                    ),
                  ],
                ),

              GroupedSection(
                header: t.profileSection,
                children: [
                  GroupedRow(title: t.username, value: p.username.startsWith('@') ? p.username : '@${p.username}'),
                  GroupedRow(title: t.memberId, value: p.mmid),
                  GroupedRow(title: t.phone, value: value(p.phone)),
                  GroupedRow(title: t.bloodGroup, value: value(p.bloodGroup)),
                  GroupedRow(title: t.address, value: p.address == null ? t.notSet : p.address!.label, chevron: true, onTap: _editAddress),
                  GroupedRow(
                    title: t.emergencyContact,
                    value: p.emergencyContactName.isEmpty && p.emergencyContactPhone.isEmpty ? t.notSet : [p.emergencyContactName, p.emergencyContactPhone].where((s) => s.isNotEmpty).join(' · '),
                  ),
                  GroupedRow(title: t.editProfile, titleColor: AppColors.primary, onTap: _editProfile),
                ],
              ),

              GroupedSection(
                header: t.preferences,
                children: [GroupedRow(title: t.language, trailing: const LanguageSwitch(width: 168))],
              ),

              GroupedSection(
                header: t.signInSection,
                dividerIndent: 58,
                children: [
                  GroupedRow(
                    icon: Icons.key_rounded,
                    iconColor: AppColors.tertiaryLabel,
                    title: t.passwordForUsername,
                    subtitle: t.passwordForUsernameSub,
                    value: AuthService.hasPasswordLogin ? '✓' : null,
                    chevron: true,
                    onTap: _setPassword,
                  ),
                  GroupedRow(
                    icon: Icons.sms_outlined,
                    iconColor: p.phoneVerified ? AppColors.success : AppColors.tertiaryLabel,
                    title: t.addPhoneSignIn,
                    subtitle: t.addPhoneSignInSub,
                    value: p.phoneVerified ? '✓' : null,
                    chevron: !p.phoneVerified,
                    onTap: p.phoneVerified ? null : () => showPhoneSignInSheet(context),
                  ),
                  GroupedRow(
                    icon: Icons.shield_rounded,
                    iconColor: mfaOn ? AppColors.success : (p.requiresMfa ? AppColors.danger : AppColors.tertiaryLabel),
                    title: t.mfaTitle,
                    subtitle: p.requiresMfa ? t.mfaRequired : null,
                    value: mfaOn ? t.mfaEnabled : t.notSet,
                    chevron: !mfaOn,
                    onTap: mfaOn ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MfaEnrollPage())),
                  ),
                ],
              ),

              GroupedSection(
                header: t.safetySection,
                dividerIndent: 58,
                children: [
                  GroupedRow(
                    icon: Icons.notifications_rounded,
                    iconColor: AppColors.danger,
                    title: t.notifications,
                    subtitle: t.notificationsSub,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
                  ),
                  GroupedRow(
                    icon: Icons.edit_note_rounded,
                    iconColor: AppColors.primary,
                    title: t.myPosts,
                    subtitle: t.myPostsSub,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyPostsPage())),
                  ),
                  GroupedRow(
                    icon: Icons.block_rounded,
                    iconColor: AppColors.tertiaryLabel,
                    title: t.blockedAuthors,
                    subtitle: t.blockedAuthorsSub,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BlockedAuthorsPage())),
                  ),
                  GroupedRow(
                    icon: Icons.bug_report_outlined,
                    iconColor: AppColors.road,
                    title: t.reportBug,
                    subtitle: t.reportBugSub,
                    chevron: true,
                    onTap: () => showBugReportSheet(context),
                  ),
                ],
              ),

              GroupedSection(
                dividerIndent: 58,
                children: [
                  GroupedRow(
                    icon: Icons.support_agent_rounded,
                    iconColor: AppColors.success,
                    title: t.supportChat,
                    subtitle: t.supportChatSub,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportBotPage())),
                  ),
                  GroupedRow(
                    icon: Icons.help_outline_rounded,
                    iconColor: AppColors.primary,
                    title: t.helpAndSupport,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpPage())),
                  ),
                ],
              ),

              if (AccountStore.supported)
                GroupedSection(
                  dividerIndent: 58,
                  children: [
                    GroupedRow(
                      icon: Icons.swap_horiz_rounded,
                      iconColor: AppColors.primary,
                      title: t.switchAccount,
                      subtitle: t.switchAccountSub,
                      chevron: true,
                      onTap: () => showSwitchAccountSheet(context),
                    ),
                  ],
                ),

              GroupedSection(
                children: [
                  GroupedRow(title: t.signOut, titleColor: AppColors.danger, onTap: _signOut),
                  GroupedRow(title: t.deleteAccount, titleColor: AppColors.danger, onTap: _deleteAccount),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 34),
                child: Column(children: [
                  const Opacity(opacity: 0.9, child: BrandLogo(width: 64)),
                  const SizedBox(height: 8),
                  Text(t.appVersion, style: AppTextStyles.caption2),
                ]),
              ),
            ]),
          ],
        );
      },
    );
  }

  static String _roleName(AppLocalizations t, UserProfile p) {
    if (p.isSuperAdmin) return t.roleSuperadmin;
    if (p.isAdmin) return t.roleAdmin;
    if (p.isModerator) return t.roleModerator;
    if (p.isGovtOfficial) return t.roleGovt;
    return t.roleResident;
  }
}

// ── Edit profile ───────────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _ecName;
  late final TextEditingController _ecPhone;
  PickedLocation? _address;
  String? _blood;
  bool _saving = false;
  String? _error;

  static const _groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    final p = AuthService.currentProfile;
    _name = TextEditingController(text: p.fullName);
    _phone = TextEditingController(text: p.phone);
    _ecName = TextEditingController(text: p.emergencyContactName);
    _ecPhone = TextEditingController(text: p.emergencyContactPhone);
    _address = p.address;
    _blood = p.bloodGroup.isEmpty ? null : p.bloodGroup;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _ecName, _ecPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t;
    if (_name.text.trim().length < 2) {
      setState(() => _error = t.nameRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final ok = await AuthService.saveProfile(
      fullName: _name.text,
      phone: _phone.text,
      address: _address,
      clearAddress: _address == null,
      bloodGroup: _blood ?? '',
      emergencyContactName: _ecName.text,
      emergencyContactPhone: _ecPhone.text,
    );
    if (!mounted) return;
    if (ok) {
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(t.profileUpdated)));
    } else {
      setState(() {
        _saving = false;
        _error = t.saveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.editProfile, style: AppTextStyles.title2),
              const SizedBox(height: 16),
              TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: t.fullName)),
              const SizedBox(height: 10),
              TextField(controller: _phone, keyboardType: TextInputType.phone, maxLength: 20, decoration: InputDecoration(labelText: t.phone, counterText: '')),
              const SizedBox(height: 10),
              GroupedSection(
                margin: EdgeInsets.zero,
                children: [
                  GroupedRow(
                    title: t.addressOptional,
                    value: _address == null ? t.notSet : _address!.label,
                    chevron: true,
                    onTap: () async {
                      final picked = await pickLocation(context, initial: _address);
                      if (picked != null) setState(() => _address = picked.isEmpty ? null : picked);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(t.bloodGroup, style: AppTextStyles.footnote)),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final g in _groups) FilterPill(label: g, selected: _blood == g, onTap: () => setState(() => _blood = _blood == g ? null : g)),
              ]),
              const SizedBox(height: 18),
              TextField(controller: _ecName, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: t.emergencyContactName)),
              const SizedBox(height: 10),
              TextField(controller: _ecPhone, keyboardType: TextInputType.phone, maxLength: 20, decoration: InputDecoration(labelText: t.emergencyContactPhone, counterText: '')),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
              const SizedBox(height: 18),
              PrimaryButton(label: t.save, loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Password for username sign-in ──────────────────────────────────────────────
class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t;
    final username = AuthService.currentProfile.username;
    if (!AuthService.isStrongPassword(_pw.text, username: username)) return setState(() => _error = t.passwordWeak);
    if (_pw.text != _confirm.text) return setState(() => _error = t.passwordMismatch);
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final ok = await AuthService.setPassword(_pw.text);
    if (!mounted) return;
    if (ok) {
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(t.passwordSaved(username.startsWith('@') ? username : '@$username'))));
    } else {
      setState(() {
        _saving = false;
        _error = t.passwordFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.passwordForUsername, style: AppTextStyles.title2),
              const SizedBox(height: 6),
              Text(t.passwordForUsernameSub, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
              const SizedBox(height: 16),
              TextField(
                controller: _pw,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: t.newPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.tertiaryLabel),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: _confirm, obscureText: _obscure, decoration: InputDecoration(labelText: t.confirmPassword)),
              Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: Text(t.passwordRules, style: AppTextStyles.caption1)),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
              const SizedBox(height: 18),
              PrimaryButton(label: t.save, loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
