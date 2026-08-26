import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_components.dart';

// ==============================================================================
// ONBOARDING FLOW — Blocking state machine
// Steps: PENDING_USERNAME → PENDING_PROFILE → PENDING_OCCUPATION → PENDING_SOURCE → COMPLETE
// Cannot reach home screen mid-flow. Staff accounts skip (seeded as COMPLETE).
// ==============================================================================

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  Widget build(BuildContext context) {
    final state = AuthService.currentProfile.onboardingState;
    return switch (state) {
      'PENDING_USERNAME'   => const _UsernameStep(),
      'PENDING_PROFILE'    => const _ProfileStep(),
      'PENDING_OCCUPATION' => const _OccupationStep(),
      'PENDING_SOURCE'     => const _SourceStep(),
      _ => const _UsernameStep(),  // fallback
    };
  }
}

// ── Base scaffold for all onboarding steps ──────────────────────────────────────
class _OnboardingScaffold extends StatelessWidget {
  final String stepLabel;
  final String title;
  final String subtitle;
  final Widget content;
  final String buttonLabel;
  final VoidCallback? onNext;
  final bool loading;
  final String? error;
  final int currentStep; // 1-4
  final bool canSkip;
  final VoidCallback? onSkip;

  const _OnboardingScaffold({
    required this.stepLabel,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.buttonLabel,
    this.onNext,
    this.loading = false,
    this.error,
    required this.currentStep,
    this.canSkip = false,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      body: AtmosphericBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Step progress
                Row(
                  children: List.generate(4, (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i < currentStep ? AppColors.primary : AppColors.separator,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 8),
                Text(stepLabel, style: AppTextStyles.caption2),
                const SizedBox(height: 24),

                Text(title, style: AppTextStyles.title1),
                const SizedBox(height: 8),
                Text(subtitle, style: AppTextStyles.footnote),
                const SizedBox(height: 32),

                Expanded(child: SingleChildScrollView(child: content)),

                if (error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      error!,
                      style: AppTextStyles.caption1.copyWith(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                ElevatedButton(
                  onPressed: loading ? null : onNext,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(buttonLabel),
                ),

                if (canSkip) ...[
                  const SizedBox(height: 10),
                  TextButton(onPressed: onSkip, child: const Text('Skip for now')),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step 1: Choose Username ────────────────────────────────────────────────────
class _UsernameStep extends StatefulWidget {
  const _UsernameStep();
  @override
  State<_UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends State<_UsernameStep> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  static final _reserved = {
    'admin', 'superadmin', 'qenbel', 'official',
    'govt', 'police', 'harur', 'support',
  };
  static final _badWords = {
    'fuck', 'shit', 'bitch', 'thevidiya', 'thevadiya', 'otha', 'pundai',
  };

  String? _validate(String raw) {
    final u = raw.trim().toLowerCase().replaceAll('@', '');
    if (u.length < 3) return 'Username must be at least 3 characters.';
    if (u.length > 30) return 'Username cannot exceed 30 characters.';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(u)) {
      return 'Only letters, numbers, and _ allowed.';
    }
    final stripped = u.replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final r in _reserved) {
      if (stripped == r || (stripped.startsWith(r) && stripped.length <= r.length + 4)) {
        return 'This username is reserved for system officials.';
      }
    }
    for (final b in _badWords) {
      if (stripped.contains(b)) return 'Username contains prohibited words.';
    }
    return null;
  }

  Future<void> _next() async {
    final err = _validate(_ctrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() { _loading = true; _error = null; });
    final ok = await AuthService.saveProfile(
      fullName: AuthService.currentProfile.fullName,
      phone: AuthService.currentProfile.phone,
      username: '@${_ctrl.text.trim().toLowerCase()}',
      onboardingState: 'PENDING_PROFILE',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) setState(() => _error = 'Could not save username. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      stepLabel: 'STEP 1 OF 4',
      title: 'Choose your\nusername',
      subtitle: 'This is your public handle in MyHarur. It cannot be changed later.',
      currentStep: 1,
      buttonLabel: 'Continue',
      onNext: _next,
      loading: _loading,
      error: _error,
      content: Column(
        children: [
          TextFormField(
            controller: _ctrl,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              prefixText: '@',
              hintText: 'your_handle',
              labelText: 'Username',
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.tertiaryLabel),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Letters, numbers, and underscores only. No profanity or reserved names.',
                style: AppTextStyles.caption2,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Step 2: Profile details ────────────────────────────────────────────────────
class _ProfileStep extends StatefulWidget {
  const _ProfileStep();
  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int? _selectedWardId;
  String _bloodGroup = 'O+';
  bool _loading = false;
  String? _error;

  final _bloodGroups = ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-'];
  final _wards = List.generate(18, (i) => {'id': i + 1, 'name': 'Ward ${i + 1}'});

  @override
  void initState() {
    super.initState();
    final p = AuthService.currentProfile;
    _nameCtrl.text = p.fullName == 'Harur Resident' ? '' : p.fullName;
    _phoneCtrl.text = p.phone;
    _selectedWardId = p.wardId;
    if (p.bloodGroup.isNotEmpty) _bloodGroup = p.bloodGroup;
  }

  Future<void> _next() async {
    if (_nameCtrl.text.trim().length < 2) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final ok = await AuthService.saveProfile(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      wardId: _selectedWardId,
      bloodGroup: _bloodGroup,
      onboardingState: 'PENDING_OCCUPATION',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) setState(() => _error = 'Could not save. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      stepLabel: 'STEP 2 OF 4',
      title: 'Tell us\nabout yourself',
      subtitle: 'Help the town know you. Your ward helps us show relevant alerts.',
      currentStep: 2,
      buttonLabel: 'Continue',
      onNext: _next,
      loading: _loading,
      error: _error,
      content: Column(
        children: [
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Your real name',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number (optional)',
              hintText: '+91 9XXXXXXXX',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _selectedWardId,
            decoration: const InputDecoration(labelText: 'Your Ward (Harur)'),
            hint: const Text('Select ward'),
            items: _wards.map((w) => DropdownMenuItem<int>(
              value: w['id'] as int,
              child: Text(w['name'] as String),
            )).toList(),
            onChanged: (v) => setState(() => _selectedWardId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _bloodGroup,
            decoration: const InputDecoration(labelText: 'Blood Group'),
            items: _bloodGroups
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _bloodGroup = v ?? 'O+'),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Occupation ──────────────────────────────────────────────────────────
class _OccupationStep extends StatefulWidget {
  const _OccupationStep();
  @override
  State<_OccupationStep> createState() => _OccupationStepState();
}

class _OccupationStepState extends State<_OccupationStep> {
  String? _selected;
  bool _loading = false;

  final _options = [
    {'value': 'student',      'label': 'Student',       'icon': '\u{1F393}'},
    {'value': 'shop_owner',   'label': 'Shop Owner',    'icon': '\u{1F3EA}'},
    {'value': 'employee',     'label': 'Employee',      'icon': '\u{1F4BC}'},
    {'value': 'govt_employee','label': 'Govt Employee', 'icon': '\u{1F3DB}'},
    {'value': 'farmer',       'label': 'Farmer',        'icon': '\u{1F33E}'},
    {'value': 'other',        'label': 'Other',         'icon': '\u2728'},
  ];

  Future<void> _next() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    await AuthService.saveProfile(
      fullName: AuthService.currentProfile.fullName,
      phone: AuthService.currentProfile.phone,
      occupation: _selected,
      onboardingState: 'PENDING_SOURCE',
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      stepLabel: 'STEP 3 OF 4',
      title: 'What do\nyou do?',
      subtitle: 'Helps us show more relevant alerts and services for you.',
      currentStep: 3,
      buttonLabel: 'Continue',
      onNext: _selected != null ? _next : null,
      loading: _loading,
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _options.map((opt) {
          final selected = _selected == opt['value'];
          return GestureDetector(
            onTap: () => setState(() => _selected = opt['value']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.separator,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.20),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(opt['icon']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    opt['label']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Step 4: How'd you hear (SKIPPABLE) ─────────────────────────────────────────
class _SourceStep extends StatefulWidget {
  const _SourceStep();
  @override
  State<_SourceStep> createState() => _SourceStepState();
}

class _SourceStepState extends State<_SourceStep> {
  String? _selected;
  bool _loading = false;

  final _sources = [
    'Friend / Family',
    'Social Media',
    'Local News',
    'Poster / Banner',
    'Government notice',
    'Other',
  ];

  Future<void> _complete({bool skip = false}) async {
    setState(() => _loading = true);
    await AuthService.saveProfile(
      fullName: AuthService.currentProfile.fullName,
      phone: AuthService.currentProfile.phone,
      onboardingState: 'COMPLETE',
    );
    if (mounted) setState(() => _loading = false);
    // AuthNotifier fires → MyHarurApp rebuilds → TownShell appears
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      stepLabel: 'STEP 4 OF 4',
      title: 'How did you\nhear about us?',
      subtitle: 'Optional \u2014 this helps us spread the word more effectively.',
      currentStep: 4,
      buttonLabel: 'Get Started',
      onNext: () => _complete(),
      loading: _loading,
      canSkip: true,
      onSkip: () => _complete(skip: true),
      content: Column(
        children: _sources.map((s) {
          final selected = _selected == s;
          return GestureDetector(
            onTap: () => setState(() => _selected = s),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.separator,
                  width: selected ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(s, style: AppTextStyles.subheadline)),
                  if (selected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
