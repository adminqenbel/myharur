import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../common/language_switch.dart';

// ==============================================================================
// ONBOARDING — a short, blocking flow: username -> about you -> occupation.
// State lives in profiles.onboarding_state: PENDING_USERNAME -> PENDING_PROFILE ->
// PENDING_OCCUPATION -> COMPLETE. Ward is NOT part of onboarding (optional, set later).
// ==============================================================================
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  /// The optional password step is offered once per launch, right after the username.
  static bool _passwordOffered = false;

  @visibleForTesting
  static void debugReset() => _passwordOffered = false;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  Widget build(BuildContext context) {
    // _AuthShell hands us a const widget, which Flutter never rebuilds on its own, so we
    // listen ourselves; otherwise the flow stays stuck on the step it started at even
    // though the new onboarding_state was saved.
    return ListenableBuilder(
      listenable: AuthNotifier.instance,
      builder: (context, _) {
        final state = AuthService.currentProfile.onboardingState;
        return switch (state) {
          'PENDING_USERNAME' => const _UsernameStep(),
          'PENDING_PROFILE' => OnboardingPage._passwordOffered
              ? const _ProfileStep()
              : _PasswordStep(onDone: () => setState(() => OnboardingPage._passwordOffered = true)),
          'PENDING_OCCUPATION' => const _OccupationStep(),
          'PENDING_SOURCE' => const _AutoComplete(), // legacy state from an older flow
          _ => const _UsernameStep(),
        };
      },
    );
  }
}

const _totalSteps = 4;

// ── Shared scaffold ────────────────────────────────────────────────────────────
class _StepScaffold extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final Widget content;
  final String buttonLabel;
  final VoidCallback? onNext;
  final bool loading;
  final String? error;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _StepScaffold({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.buttonLabel,
    required this.onNext,
    this.loading = false,
    this.error,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(
                        _totalSteps,
                        (i) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            height: 4,
                            margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: i < step ? AppColors.primary : AppColors.separator,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const LanguageSwitch(width: 132),
                ],
              ),
              const SizedBox(height: 22),
              Text(t.stepOf(step, _totalSteps), style: AppTextStyles.footnote),
              const SizedBox(height: 6),
              Text(title, style: AppTextStyles.title1),
              const SizedBox(height: 8),
              Text(subtitle, style: AppTextStyles.callout.copyWith(color: AppColors.secondaryLabel)),
              const SizedBox(height: 26),
              Expanded(child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, child: content)),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger)),
                ),
              PrimaryButton(label: buttonLabel, onPressed: onNext, loading: loading),
              if (secondaryLabel != null) TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 1: username ───────────────────────────────────────────────────────────
enum _UsernameProblem { short, long, chars, reserved, bad }

class _UsernameStep extends StatefulWidget {
  const _UsernameStep();
  @override
  State<_UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends State<_UsernameStep> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  static const _reserved = {'admin', 'superadmin', 'qenbel', 'official', 'govt', 'police', 'harur', 'support', 'moderator', 'myharur'};
  static const _bad = {'fuck', 'shit', 'bitch', 'thevidiya', 'thevadiya', 'otha', 'pundai'};

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static _UsernameProblem? validate(String raw) {
    final u = raw.trim().toLowerCase().replaceAll('@', '');
    if (u.length < 3) return _UsernameProblem.short;
    if (u.length > 30) return _UsernameProblem.long;
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(u)) return _UsernameProblem.chars;
    final stripped = u.replaceAll('_', '');
    for (final r in _reserved) {
      if (stripped == r || (stripped.startsWith(r) && stripped.length <= r.length + 4)) return _UsernameProblem.reserved;
    }
    for (final b in _bad) {
      if (stripped.contains(b)) return _UsernameProblem.bad;
    }
    return null;
  }

  Future<void> _next() async {
    final t = context.t;
    final problem = validate(_ctrl.text);
    if (problem != null) {
      setState(() => _error = switch (problem) {
            _UsernameProblem.short => t.usernameShort,
            _UsernameProblem.long => t.usernameLong,
            _UsernameProblem.chars => t.usernameChars,
            _UsernameProblem.reserved => t.usernameReserved,
            _UsernameProblem.bad => t.usernameBad,
          });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await AuthService.saveProfile(
      username: '@${_ctrl.text.trim().toLowerCase().replaceAll('@', '')}',
      onboardingState: 'PENDING_PROFILE',
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!ok) {
        final code = AuthService.lastSaveErrorCode;
        final msg = AuthService.lastSaveErrorMessage ?? '';
        _error = code == '23505'
            ? t.usernameTaken
            : msg.contains('username_reserved')
                ? t.usernameReserved
                : msg.contains('username_bad')
                    ? t.usernameBad
                    : msg.contains('username_invalid')
                        ? t.usernameChars
                        : t.saveFailed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return _StepScaffold(
      step: 1,
      title: t.obUsernameTitle,
      subtitle: t.obUsernameSub,
      buttonLabel: t.continueLabel,
      onNext: _next,
      loading: _loading,
      error: _error,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _next(),
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(prefixText: '@', hintText: 'your_name', labelText: t.username),
          ),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(t.usernameHint, style: AppTextStyles.caption1)),
        ],
      ),
    );
  }
}

// ── Step 2: optional password (for username sign-in) ───────────────────────────
class _PasswordStep extends StatefulWidget {
  final VoidCallback onDone;
  const _PasswordStep({required this.onDone});
  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep> {
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
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
    if (!AuthService.isStrongPassword(_pw.text, username: username)) {
      setState(() => _error = t.passwordWeak);
      return;
    }
    if (_pw.text != _confirm.text) {
      setState(() => _error = t.passwordMismatch);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await AuthService.setPassword(_pw.text);
    if (!mounted) return;
    if (ok) {
      widget.onDone();
    } else {
      setState(() {
        _loading = false;
        _error = t.passwordFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return _StepScaffold(
      step: 2,
      title: t.obPasswordTitle,
      subtitle: t.obPasswordSub,
      buttonLabel: t.save,
      onNext: _save,
      loading: _loading,
      error: _error,
      secondaryLabel: t.skipForNow,
      onSecondary: widget.onDone,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }
}

// ── Step 2: about you ──────────────────────────────────────────────────────────
class _ProfileStep extends StatefulWidget {
  const _ProfileStep();
  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _blood; // optional: null = not set
  bool _loading = false;
  String? _error;

  static const _groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    final p = AuthService.currentProfile;
    // Pre-fill from the Google account so most people just tap Continue.
    final google = AuthService.googleName;
    _nameCtrl.text = p.fullName != 'Harur Resident' ? p.fullName : (google ?? '');
    _phoneCtrl.text = p.phone;
    if (p.bloodGroup.isNotEmpty) _blood = p.bloodGroup;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final t = context.t;
    if (_nameCtrl.text.trim().length < 2) {
      setState(() => _error = t.nameRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await AuthService.saveProfile(
      fullName: _nameCtrl.text,
      phone: _phoneCtrl.text,
      bloodGroup: _blood ?? '',
      onboardingState: 'PENDING_OCCUPATION',
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!ok) _error = t.saveFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return _StepScaffold(
      step: 3,
      title: t.obProfileTitle,
      subtitle: t.obProfileSub,
      buttonLabel: t.continueLabel,
      onNext: _next,
      loading: _loading,
      error: _error,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: t.fullName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: t.phoneOptional, hintText: '+91'),
          ),
          const SizedBox(height: 22),
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(t.bloodGroupOptional, style: AppTextStyles.footnote)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in _groups)
                FilterPill(
                  label: g,
                  selected: _blood == g,
                  onTap: () => setState(() => _blood = _blood == g ? null : g),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 3: occupation ─────────────────────────────────────────────────────────
class _OccupationStep extends StatefulWidget {
  const _OccupationStep();
  @override
  State<_OccupationStep> createState() => _OccupationStepState();
}

class _OccupationStepState extends State<_OccupationStep> {
  String? _selected;
  bool _loading = false;
  String? _error;

  Future<void> _finish() async {
    final t = context.t;
    if (_selected == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await AuthService.saveProfile(occupation: _selected, onboardingState: 'COMPLETE');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!ok) _error = t.saveFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final options = <(String, String, IconData)>[
      ('student', t.occStudent, Icons.school_rounded),
      ('shop_owner', t.occShopOwner, Icons.storefront_rounded),
      ('employee', t.occEmployee, Icons.work_rounded),
      ('govt_employee', t.occGovtEmployee, Icons.account_balance_rounded),
      ('farmer', t.occFarmer, Icons.agriculture_rounded),
      ('other', t.occOther, Icons.more_horiz_rounded),
    ];
    const colors = [Color(0xFF5E5CE6), Color(0xFFFF9500), Color(0xFF007AFF), Color(0xFF34AADC), Color(0xFF30B350), Color(0xFF8E8E93)];

    return _StepScaffold(
      step: 4,
      title: t.obOccupationTitle,
      subtitle: t.obOccupationSub,
      buttonLabel: t.getStarted,
      onNext: _selected == null ? null : _finish,
      loading: _loading,
      error: _error,
      content: GroupedSection(
        margin: EdgeInsets.zero,
        dividerIndent: 58,
        children: [
          for (var i = 0; i < options.length; i++)
            GroupedRow(
              icon: options[i].$3,
              iconColor: colors[i],
              title: options[i].$2,
              trailing: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _selected == options[i].$1 ? 1 : 0,
                child: const Icon(Icons.check_rounded, color: AppColors.primary),
              ),
              onTap: () => setState(() => _selected = options[i].$1),
            ),
        ],
      ),
    );
  }
}

// ── Legacy state: finish silently ──────────────────────────────────────────────
class _AutoComplete extends StatefulWidget {
  const _AutoComplete();
  @override
  State<_AutoComplete> createState() => _AutoCompleteState();
}

class _AutoCompleteState extends State<_AutoComplete> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => AuthService.saveProfile(onboardingState: 'COMPLETE'));
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
}
