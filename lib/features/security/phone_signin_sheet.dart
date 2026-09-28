import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// ADD PHONE SIGN-IN (Account > Sign-in): attaches a verified phone number to the CURRENTLY
// signed-in account, so it can also be used to sign in later. Two steps: enter the number, then
// the 6-digit code Brevo sends to it. Never creates a new account — see
// AuthService.startPhoneVerification/confirmPhoneVerification.
// ==============================================================================
void showPhoneSignInSheet(BuildContext context) {
  showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _PhoneSignInSheet());
}

class _PhoneSignInSheet extends StatefulWidget {
  const _PhoneSignInSheet();

  @override
  State<_PhoneSignInSheet> createState() => _PhoneSignInSheetState();
}

class _PhoneSignInSheetState extends State<_PhoneSignInSheet> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  int _step = 0;
  bool _busy = false;
  String? _error;
  String _sentTo = '';

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = context.t;
    final raw = _phone.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await AuthService.startPhoneVerification(raw);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = switch (result) {
        OtpSendResult.ok => null,
        OtpSendResult.invalidInput => t.otpInvalidPhone,
        OtpSendResult.rateLimited => t.otpRateLimited,
        OtpSendResult.network => t.authNetwork,
        OtpSendResult.error => t.otpSendFailed,
      };
      if (result == OtpSendResult.ok) {
        _sentTo = raw;
        _step = 1;
      }
    });
  }

  Future<void> _verify() async {
    final t = context.t;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await AuthService.confirmPhoneVerification(_sentTo, _code.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.phoneSignInAdded)));
      return;
    }
    setState(() {
      _busy = false;
      _error = t.otpInvalidCode;
      _code.clear();
    });
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
            children: _step == 0
                ? [
                    Text(t.addPhoneSignIn, style: AppTextStyles.title2),
                    const SizedBox(height: 6),
                    Text(t.addPhoneSignInSub, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phone,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(labelText: t.phoneField, hintText: t.phoneHint),
                    ),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
                    const SizedBox(height: 18),
                    PrimaryButton(label: t.continueLabel, loading: _busy, onPressed: _send),
                  ]
                : [
                    Text(t.otpTitle, style: AppTextStyles.title2),
                    const SizedBox(height: 6),
                    Text(t.otpSubtitle(_sentTo), style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
                    const SizedBox(height: 16),
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
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
                    const SizedBox(height: 18),
                    PrimaryButton(label: t.otpVerify, loading: _busy, onPressed: _busy ? null : _verify),
                  ],
          ),
        ),
      ),
    );
  }
}
