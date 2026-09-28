import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/error_reporter.dart';
import '../../core/services/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../common/language_switch.dart';
import 'otp_signin_page.dart';

// ==============================================================================
// AUTH PAGE: two clearly separate paths.
//   Register: Google only (new account). A username + password can be added afterwards.
//   Sign in:  Google, or @username + password (for accounts that set a password).
// There is no e-mail sign-up: the database refuses it.
// ==============================================================================
class AuthPage extends StatefulWidget {
  /// True when opened from "Add another account": shows a close button and closes itself once a
  /// different account is signed in.
  final bool addingAccount;
  const AuthPage({super.key, this.addingAccount = false});

  /// Bumped by the failure page's "Use username instead" to jump to the username form.
  static final ValueNotifier<int> showUsernameIntent = ValueNotifier<int>(0);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with WidgetsBindingObserver {
  final _username = TextEditingController();
  final _password = TextEditingController();
  int _tab = 0; // 0 = sign in, 1 = register
  bool _obscure = true;
  bool _googleBusy = false;
  bool _usernameBusy = false;
  bool _awaitingBrowser = false;
  Timer? _timeout;
  String? _error;
  late final String _startedAs = AuthService.currentProfile.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthPage.showUsernameIntent.addListener(_onUsernameIntent);
    if (widget.addingAccount) AuthNotifier.instance.addListener(_onAccountChanged);
  }

  /// Add-account mode: a different person is now signed in, so this page is done.
  void _onAccountChanged() {
    final id = AuthService.currentProfile.id;
    if (!mounted || id == 'guest' || id == _startedAs) return;
    AuthNotifier.instance.removeListener(_onAccountChanged);
    Navigator.of(context).maybePop();
    AppErrors.restart(); // fresh screens for the new account
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthPage.showUsernameIntent.removeListener(_onUsernameIntent);
    AuthNotifier.instance.removeListener(_onAccountChanged);
    _timeout?.cancel();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onUsernameIntent() => setState(() {
        _tab = 0;
        _error = null;
      });

  /// Coming back from the Google browser without a session means the person cancelled or it failed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_awaitingBrowser) return;
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!mounted || !_awaitingBrowser || AuthService.isAuthenticated) return;
      _awaitingBrowser = false;
      _timeout?.cancel();
      setState(() => _googleBusy = false);
      AuthService.reportFailure(AuthFailureReason.cancelled);
    });
  }

  Future<void> _google() async {
    setState(() {
      _googleBusy = true;
      _error = null;
    });
    final launched = await AuthService.signInWithGoogle();
    if (!mounted) return;
    if (!launched) {
      setState(() => _googleBusy = false);
      AuthService.reportFailure(AuthFailureReason.failed);
      return;
    }
    _awaitingBrowser = true;
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 120), () {
      if (!mounted || AuthService.isAuthenticated) return;
      _awaitingBrowser = false;
      setState(() => _googleBusy = false);
      AuthService.reportFailure(AuthFailureReason.timeout);
    });
    // the browser is open now; the busy state ends when the session arrives or the person comes back
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _googleBusy = false);
    });
  }

  void _openOtp(bool isPhone) {
    Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => OtpSignInPage(isPhone: isPhone)));
  }

  Future<void> _usernameSignIn() async {
    final t = context.t;
    final u = _username.text.trim();
    final p = _password.text;
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = t.wrongCredentials);
      return;
    }
    setState(() {
      _usernameBusy = true;
      _error = null;
    });
    final result = await AuthService.signInWithUsername(u, p);
    if (!mounted) return;
    setState(() {
      _usernameBusy = false;
      _error = switch (result) {
        UsernameLoginResult.ok => null,
        UsernameLoginResult.invalid => t.wrongCredentials,
        UsernameLoginResult.tooManyAttempts => t.tooManyAttempts((AuthService.lastRetryAfterSeconds / 60).ceil().clamp(1, 999)),
        UsernameLoginResult.locked => AuthService.lockedPermanently || AuthService.lockedUntil == null
            ? t.passwordLoginOff
            : t.passwordLoginPaused(DateFormat.MMMd(Localizations.localeOf(context).languageCode).add_jm().format(AuthService.lockedUntil!)),
        UsernameLoginResult.network => t.authNetwork,
        UsernameLoginResult.error => t.authFailedBody,
      };
      if (result != UsernameLoginResult.ok) _password.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final configured = SupabaseConfig.isConfigured;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // Scrolls when the screen is short (small phones, keyboard open); when there is room the
        // two blocks sit at the top and bottom of the screen.
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── top block: language + brand ───────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          widget.addingAccount
                              ? IconButton(tooltip: t.closeAction, icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).maybePop())
                              : const SizedBox.shrink(),
                          const LanguageSwitch(width: 168),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Center(child: BrandLogo(width: 170)),
                      const SizedBox(height: 10),
                      Text(t.appName, textAlign: TextAlign.center, style: AppTextStyles.title1),
                      const SizedBox(height: 24),
                    ],
                  ),

                  // ── bottom block: sign in / register ──────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!configured) ...[
                        Banner2(icon: Icons.cloud_off_rounded, text: t.noBackend, color: AppColors.warning),
                        const SizedBox(height: 12),
                      ],
                      SegmentedPill(
                        labels: [t.tabSignIn, t.tabRegister],
                        selected: _tab,
                        onChanged: (i) => setState(() {
                          _tab = i;
                          _error = null;
                        }),
                      ),
                      const SizedBox(height: 18),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _tab == 0 ? _signIn(context, configured) : _register(context, configured),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger)),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 14),
                        child: Text(t.authFooter, textAlign: TextAlign.center, style: AppTextStyles.caption2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sign in ────────────────────────────────────────────────────────────────
  Widget _signIn(BuildContext context, bool configured) {
    final t = context.t;
    return Column(
      key: const ValueKey('signin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.signInExplain, textAlign: TextAlign.center, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
        const SizedBox(height: 14),
        _GoogleButton(label: t.continueWithGoogle, loading: _googleBusy, onTap: configured ? _google : null),
        _orDivider(t.orMoreWays),
        _OtpChoiceRow(enabled: configured, onEmail: () => _openOtp(false), onPhone: () => _openOtp(true)),
        _orDivider(t.orDivider),
        TextField(
          controller: _username,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          decoration: InputDecoration(labelText: t.usernameField, prefixText: '@'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _usernameSignIn(),
          decoration: InputDecoration(
            labelText: t.password,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.tertiaryLabel),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(label: t.usernameSignIn, loading: _usernameBusy, onPressed: configured ? _usernameSignIn : null),
        const SizedBox(height: 10),
        Text(t.noPasswordYet, textAlign: TextAlign.center, style: AppTextStyles.caption1),
      ],
    );
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Widget _register(BuildContext context, bool configured) {
    final t = context.t;
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.registerWelcome, textAlign: TextAlign.center, style: AppTextStyles.title3),
        const SizedBox(height: 8),
        Text(t.registerExplain, textAlign: TextAlign.center, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
        const SizedBox(height: 18),
        _GoogleButton(label: t.registerWithGoogle, loading: _googleBusy, onTap: configured ? _google : null),
        _orDivider(t.orMoreWays),
        _OtpChoiceRow(enabled: configured, onEmail: () => _openOtp(false), onPhone: () => _openOtp(true)),
      ],
    );
  }

  Widget _orDivider(String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          const Expanded(child: Divider()),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(label, style: AppTextStyles.caption1)),
          const Expanded(child: Divider()),
        ]),
      );
}

class _OtpChoiceRow extends StatelessWidget {
  final bool enabled;
  final VoidCallback onEmail;
  final VoidCallback onPhone;
  const _OtpChoiceRow({required this.enabled, required this.onEmail, required this.onPhone});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(children: [
      Expanded(child: PrimaryButton(label: t.continueWithEmail, tinted: true, icon: Icons.mail_outline_rounded, onPressed: enabled ? onEmail : null)),
      const SizedBox(width: 10),
      Expanded(child: PrimaryButton(label: t.continueWithPhone, tinted: true, icon: Icons.sms_outlined, onPressed: enabled ? onPhone : null)),
    ]);
  }
}

class _GoogleButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _GoogleButton({required this.label, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? null : onTap,
      haptic: true,
      scale: 0.98,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: SoftShadow(
          radius: 17,
          shadows: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))],
          child: Container(
            height: 54,
            decoration: ShapeDecoration(color: Colors.white, shape: squircle(17)),
            child: Center(
              child: loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (r) => const SweepGradient(
                            colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335), Color(0xFF4285F4)],
                            startAngle: -0.4,
                            endAngle: 5.9,
                          ).createShader(r),
                          child: const Text('G', style: TextStyle(fontFamily: 'Inter', fontSize: 25, fontWeight: FontWeight.w700, color: Colors.white, height: 1)),
                        ),
                        const SizedBox(width: 12),
                        Text(label, style: AppTextStyles.headline),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
