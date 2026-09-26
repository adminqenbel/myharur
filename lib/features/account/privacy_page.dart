import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// PRIVACY AND PROTECTION: what we store, who can see it, what protects it, and the
// services involved. Only states protections the app really has (see docs/SECURITY.md).
// ==============================================================================
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final protections = [t.prot1, t.prot2, t.prot3, t.prot4, t.prot5];

    Widget text(String header, String body) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter + 4, 0, AppSpacing.gutter + 4, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(header, style: AppTextStyles.headline),
              const SizedBox(height: 6),
              Text(body, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel, height: 1.4)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.privacyTitle, showBack: true),
          SliverList.list(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, 20),
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Column(children: [
                  Image.asset('assets/brand/qenshar.png', height: 96, fit: BoxFit.contain, semanticLabel: 'QenShar'),
                  const SizedBox(height: 12),
                  Text(t.qenSharTitle, style: AppTextStyles.title3),
                  const SizedBox(height: 2),
                  Text(t.qenSharSub, style: AppTextStyles.footnote),
                ]),
              ),
            ),
            GroupedSection(
              dividerIndent: 58,
              children: [
                for (final line in protections)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const IconTile(icon: Icons.check_rounded, color: AppColors.success, size: 26),
                        const SizedBox(width: 12),
                        Expanded(child: Text(line, style: AppTextStyles.subheadline)),
                      ],
                    ),
                  ),
              ],
            ),
            text(t.whatWeStore, t.whatWeStoreBody),
            text(t.whoCanSee, t.whoCanSeeBody),
            text(t.yourControl, t.yourControlBody),
            text(t.servicesWeUse, t.servicesWeUseBody),
            const SizedBox(height: 20),
          ]),
        ],
      ),
    );
  }
}
