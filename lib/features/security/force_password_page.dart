import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

/// Shown right after a super admin recovered the account: the temporary password must be replaced
/// before anything else. The only other way out is signing out.
class ForcePasswordPage extends StatefulWidget {
  const ForcePasswordPage({super.key});

  @override
  State<ForcePasswordPage> createState() => _ForcePasswordPageState();
}

class _ForcePasswordPageState extends State<ForcePasswordPage> {
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
    if (!AuthService.isStrongPassword(_pw.text, username: AuthService.currentProfile.username)) {
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
    if (!ok) {
      setState(() {
        _loading = false;
        _error = t.passwordFailed;
      });
    }
    // on success setPassword clears the flag and notifies; the shell moves on by itself
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.forcePwTitle, style: AppTextStyles.title1),
              const SizedBox(height: 8),
              Text(t.forcePwSub, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
              const SizedBox(height: 24),
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
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: AppTextStyles.footnote.copyWith(color: AppColors.danger)),
                ),
              const SizedBox(height: 20),
              PrimaryButton(label: t.save, loading: _loading, onPressed: _save),
              const SizedBox(height: 8),
              TextButton(onPressed: AuthService.signOut, child: Text(t.signOut)),
            ],
          ),
        ),
      ),
    );
  }
}
