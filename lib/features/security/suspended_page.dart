import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/safe_launch.dart';
import '../../core/widgets/ui.dart';

/// Shown instead of the app when an admin banned the account. Sign out and support are the only actions.
class SuspendedPage extends StatelessWidget {
  const SuspendedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_rounded, size: 56, color: AppColors.danger),
                const SizedBox(height: 20),
                Text(t.suspendedTitle, textAlign: TextAlign.center, style: AppTextStyles.title1),
                const SizedBox(height: 10),
                Text(t.suspendedBody, textAlign: TextAlign.center, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
                const SizedBox(height: 28),
                PrimaryButton(label: t.contactSupport, tinted: true, icon: Icons.mail_rounded, onPressed: () => safeLaunch('mailto:adminqenbel@gmail.com?subject=MyHarur%20account%20suspended')),
                const SizedBox(height: 8),
                TextButton(onPressed: AuthService.signOut, child: Text(t.signOut)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
