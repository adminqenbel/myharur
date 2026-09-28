import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// OTP SIGN-IN: one small flow — enter an e-mail or phone number, get a 6-digit code
// (delivered through Brevo, see docs/BREVO.md), verify it. Works for both a brand-new
// resident and someone signing back in; AuthService.signInWithOtp does the right thing
// either way, same as Google always has.
// ==============================================================================
class OtpSignInPage extends StatefulWidget {
  final bool isPhone;
  const OtpSignInPage({super.key, required this.isPhone});

  @override
  State<OtpSignInPage> createState() => _OtpSignInPageState();
}

class _OtpSignInPageState extends State<OtpSignInPage> {
  final _identifier = TextEditingController();
  final _code = TextEditingController();
  int _step = 0; // 0 = enter e-mail/phone, 1 = enter code
  bool _busy = false;
  String? _error;
  String _sentTo = '';
  Timer? _cooldownTimer;
  int _cooldown = 0;

  @override
  void dispose() {
    _identifier.dispose();
    _code.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  String? _sendErrorFor(OtpSendResult result) {
    final t = context.t;
    return switch (result) {
      OtpSendResult.ok => null,
      OtpSendResult.invalidInput => widget.isPhone ? t.otpInvalidPhone : t.otpInvalidEmail,
      OtpSendResult.rateLimited => t.otpRateLimited,
      OtpSendResult.network => t.authNetwork,
      OtpSendResult.error => t.otpSendFailed,
    };
  }

  /// India only: the field only ever collects the local 10-digit number, "+91" is fixed.
  String get _identifierValue => widget.isPhone ? '+91${_identifier.text.trim()}' : _identifier.text.trim();

  Future<void> _send() async {
    final raw = _identifierValue;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = widget.isPhone ? await AuthService.sendPhoneOtp(raw) : await AuthService.sendEmailOtp(raw);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = _sendErrorFor(result);
      if (result == OtpSendResult.ok) {
        _sentTo = raw;
        _step = 1;
        _startCooldown();
      }
    });
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = widget.isPhone ? await AuthService.sendPhoneOtp(_sentTo) : await AuthService.sendEmailOtp(_sentTo);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = _sendErrorFor(result);
      if (result == OtpSendResult.ok) _startCooldown();
    });
    if (result == OtpSendResult.ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.otpSentAgain)));
    }
  }

  Future<void> _verify() async {
    final t = context.t;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = widget.isPhone ? await AuthService.verifyPhoneOtp(_sentTo, _code.text) : await AuthService.verifyEmailOtp(_sentTo, _code.text);
    if (!mounted) return;
    if (result == OtpVerifyResult.ok) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _busy = false;
      _error = result == OtpVerifyResult.invalidCode ? t.otpInvalidCode : (result == OtpVerifyResult.network ? t.authNetwork : t.otpSendFailed);
      _code.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey(_step),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _step == 0 ? _identifierStep(t) : _codeStep(t),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _identifierStep(AppLocalizations t) => [
        Text(widget.isPhone ? t.continueWithPhone : t.continueWithEmail, style: AppTextStyles.title2),
        const SizedBox(height: 18),
        TextField(
          controller: _identifier,
          autofocus: true,
          keyboardType: widget.isPhone ? TextInputType.phone : TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _send(),
          inputFormatters: widget.isPhone ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)] : null,
          decoration: InputDecoration(
            labelText: widget.isPhone ? t.phoneField : t.emailField,
            hintText: widget.isPhone ? t.phoneHint : null,
            prefixText: widget.isPhone ? '+91 ' : null,
          ),
        ),
        if (_error != null)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
        const SizedBox(height: 18),
        PrimaryButton(label: t.continueLabel, loading: _busy, onPressed: _send),
      ];

  List<Widget> _codeStep(AppLocalizations t) => [
        Text(t.otpTitle, style: AppTextStyles.title2),
        const SizedBox(height: 8),
        Text(t.otpSubtitle(_sentTo), style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
        const SizedBox(height: 18),
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: AppTextStyles.title1,
          onSubmitted: (_) => _verify(),
          decoration: InputDecoration(labelText: t.otpCodeField, counterText: ''),
        ),
        if (_error != null)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
        const SizedBox(height: 18),
        PrimaryButton(label: t.otpVerify, loading: _busy, onPressed: _busy ? null : _verify),
        const SizedBox(height: 10),
        TextButton(onPressed: _cooldown > 0 || _busy ? null : _resend, child: Text(_cooldown > 0 ? t.otpResendIn(_cooldown) : t.otpResend)),
      ];
}
