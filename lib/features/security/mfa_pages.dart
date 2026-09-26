import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// TWO-FACTOR (authenticator app). Admins and super admins MUST set this up; everyone else may.
// The database also refuses admin actions without it, so these screens are the way in, not the lock.
// ==============================================================================

/// Set up an authenticator app. [mandatory] = shown as a gate (no close button, sign-out offered).
class MfaEnrollPage extends StatefulWidget {
  final bool mandatory;
  const MfaEnrollPage({super.key, this.mandatory = false});

  @override
  State<MfaEnrollPage> createState() => _MfaEnrollPageState();
}

class _MfaEnrollPageState extends State<MfaEnrollPage> {
  final _code = TextEditingController();
  MfaEnrollment? _enrollment;
  bool _loading = true;
  bool _failed = false;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final e = await AuthService.startMfaEnrollment();
    if (!mounted) return;
    setState(() {
      _enrollment = e;
      _loading = false;
      _failed = e == null;
    });
  }

  Future<void> _verify() async {
    final t = context.t;
    final e = _enrollment;
    if (e == null || _code.text.trim().length != 6) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    final ok = await AuthService.verifyMfaCode(e.factorId, _code.text);
    if (!mounted) return;
    if (ok) {
      if (!widget.mandatory) Navigator.of(context).maybePop(); // as a gate, the shell moves on by itself
    } else {
      setState(() {
        _verifying = false;
        _error = t.mfaBadCode;
        _code.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.mandatory ? null : AppBar(title: Text(t.mfaTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _failed
                ? Center(child: EmptyState(icon: Icons.shield_outlined, title: t.mfaSetupFailed, actionLabel: t.tryAgain, onAction: _start))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    children: [
                      if (widget.mandatory) ...[
                        Text(t.mfaTitle, style: AppTextStyles.title1),
                        const SizedBox(height: 8),
                        Text(t.mfaRequired, style: AppTextStyles.callout.copyWith(color: AppColors.secondaryLabel)),
                        const SizedBox(height: 22),
                      ],
                      Text(t.mfaScan, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: ShapeDecoration(color: Colors.white, shape: squircle(20), shadows: kCardShadow),
                          child: QrImageView(data: _enrollment!.uri, size: 200, backgroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(t.mfaManualKey, textAlign: TextAlign.center, style: AppTextStyles.footnote),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _enrollment!.secret));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.copied)));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: ShapeDecoration(color: AppColors.fill, shape: squircle(14)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(child: SelectableText(_enrollment!.secret, textAlign: TextAlign.center, style: AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.2))),
                              const SizedBox(width: 10),
                              const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: AppTextStyles.title2.copyWith(letterSpacing: 8),
                        onChanged: (v) {
                          setState(() => _error = null);
                          if (v.length == 6) _verify();
                        },
                        decoration: InputDecoration(labelText: t.mfaEnterCode, counterText: ''),
                      ),
                      if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
                      const SizedBox(height: 16),
                      PrimaryButton(label: t.mfaVerify, loading: _verifying, onPressed: _code.text.length == 6 ? _verify : null),
                      if (widget.mandatory) ...[
                        const SizedBox(height: 8),
                        TextButton(onPressed: AuthService.signOut, child: Text(t.signOut, style: const TextStyle(color: AppColors.danger))),
                      ],
                    ],
                  ),
      ),
    );
  }
}

/// Enter the 6-digit code after signing in (session is AAL1 until this succeeds).
class MfaChallengePage extends StatefulWidget {
  const MfaChallengePage({super.key});

  @override
  State<MfaChallengePage> createState() => _MfaChallengePageState();
}

class _MfaChallengePageState extends State<MfaChallengePage> {
  final _code = TextEditingController();
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final t = context.t;
    if (_code.text.trim().length != 6) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    final factor = await AuthService.verifiedFactorId();
    final ok = factor != null && await AuthService.verifyMfaCode(factor, _code.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _verifying = false;
        _error = t.mfaBadCode;
        _code.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 76, height: 76, decoration: ShapeDecoration(color: AppColors.primaryTint, shape: squircle(24)), child: const Icon(Icons.shield_rounded, size: 38, color: AppColors.primary))),
                  const SizedBox(height: 22),
                  Text(t.mfaChallengeTitle, textAlign: TextAlign.center, style: AppTextStyles.title1),
                  const SizedBox(height: 8),
                  Text(t.mfaChallengeSub, textAlign: TextAlign.center, style: AppTextStyles.callout.copyWith(color: AppColors.secondaryLabel)),
                  const SizedBox(height: 26),
                  TextField(
                    controller: _code,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTextStyles.title2.copyWith(letterSpacing: 8),
                    onChanged: (v) {
                      setState(() => _error = null);
                      if (v.length == 6) _verify();
                    },
                    decoration: InputDecoration(labelText: t.mfaEnterCode, counterText: ''),
                  ),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
                  const SizedBox(height: 16),
                  PrimaryButton(label: t.mfaVerify, loading: _verifying, onPressed: _code.text.length == 6 ? _verify : null),
                  const SizedBox(height: 8),
                  TextButton(onPressed: AuthService.signOut, child: Text(t.signOut, style: const TextStyle(color: AppColors.danger))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
