import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/error_reporter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// FRIENDLY FAILURE PAGES: crash, sign-in failure, offline, page not found.
// They explain what happened in plain words, say nothing was lost, and offer the next step.
// ==============================================================================

class _ErrorScaffold extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final List<Widget> actions;

  const _ErrorScaffold({required this.icon, required this.color, required this.title, required this.body, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: ShapeDecoration(color: color.withValues(alpha: 0.12), shape: squircle(26)),
                      child: Icon(icon, size: 42, color: color),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(title, textAlign: TextAlign.center, style: AppTextStyles.title1),
                  const SizedBox(height: 10),
                  Text(body, textAlign: TextAlign.center, style: AppTextStyles.callout.copyWith(color: AppColors.secondaryLabel)),
                  const SizedBox(height: 30),
                  for (final a in actions) ...[a, const SizedBox(height: 10)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Crash ──────────────────────────────────────────────────────────────────────
class CrashPage extends StatefulWidget {
  final CrashInfo info;
  const CrashPage({super.key, required this.info});

  @override
  State<CrashPage> createState() => _CrashPageState();
}

class _CrashPageState extends State<CrashPage> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _report() async {
    setState(() => _sending = true);
    final ok = await AppErrors.reportNow(widget.info);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = ok;
    });
    if (ok) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.t.problemReported)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return _ErrorScaffold(
      icon: Icons.error_outline_rounded,
      color: AppColors.danger,
      title: t.crashTitle,
      body: t.crashBody,
      actions: [
        PrimaryButton(label: t.restartApp, icon: Icons.refresh_rounded, onPressed: AppErrors.restart),
        if (AuthService.isAuthenticated)
          PrimaryButton(label: _sent ? t.problemReported : t.reportProblem, tinted: true, loading: _sending, onPressed: _sent ? null : _report),
      ],
    );
  }
}

// ── Sign-in failure ────────────────────────────────────────────────────────────
class AuthFailurePage extends StatelessWidget {
  final AuthFailureReason reason;

  /// Called when the user chooses "Use username instead".
  final VoidCallback onUseUsername;

  const AuthFailurePage({super.key, required this.reason, required this.onUseUsername});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (icon, body) = switch (reason) {
      AuthFailureReason.cancelled => (Icons.person_off_outlined, t.authCancelled),
      AuthFailureReason.timeout => (Icons.hourglass_disabled_rounded, t.authTimeout),
      AuthFailureReason.network => (Icons.wifi_off_rounded, t.authNetwork),
      AuthFailureReason.failed => (Icons.lock_outline_rounded, t.authFailedBody),
    };

    return _ErrorScaffold(
      icon: icon,
      color: AppColors.warning,
      title: t.authFailedTitle,
      body: body,
      actions: [
        PrimaryButton(
          label: t.tryAgain,
          icon: Icons.refresh_rounded,
          onPressed: () {
            AuthService.clearFailure();
            AuthService.signInWithGoogle();
          },
        ),
        PrimaryButton(label: t.useUsernameInstead, tinted: true, onPressed: onUseUsername),
        TextButton(onPressed: AuthService.clearFailure, child: Text(t.cancel)),
      ],
    );
  }
}

// ── Offline ────────────────────────────────────────────────────────────────────
class OfflinePage extends StatelessWidget {
  final VoidCallback onRetry;
  const OfflinePage({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return _ErrorScaffold(
      icon: Icons.wifi_off_rounded,
      color: AppColors.tertiaryLabel,
      title: t.offlineTitle,
      body: t.offlineBody,
      actions: [PrimaryButton(label: t.tryAgain, icon: Icons.refresh_rounded, onPressed: onRetry)],
    );
  }
}

// ── Not found ──────────────────────────────────────────────────────────────────
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return _ErrorScaffold(
      icon: Icons.explore_off_outlined,
      color: AppColors.primary,
      title: t.notFoundTitle,
      body: t.notFoundBody,
      actions: [
        PrimaryButton(label: t.goHome, icon: Icons.home_rounded, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
      ],
    );
  }
}

/// Replaces Flutter's red error screen in release builds when a single widget fails to build.
class FriendlyErrorBox extends StatelessWidget {
  const FriendlyErrorBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: const Icon(Icons.error_outline_rounded, color: AppColors.tertiaryLabel, size: 32),
    );
  }
}
