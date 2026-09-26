import 'package:flutter/material.dart';
import '../../core/util/safe_launch.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// HELP — national / state helplines that work from any phone. Tap a row to call.
// (Local landline numbers are intentionally not hard-coded: they must be verified
// with the town office first; add them here once confirmed.)
// ==============================================================================
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Future<void> _call(String number) async {
    await safeLaunch(Uri(scheme: 'tel', path: number).toString());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    final emergency = <_Line>[
      _Line('108', Icons.medical_services_rounded, AppColors.danger, t.hlAmbulance, t.hlAmbulanceDesc),
      _Line('100', Icons.local_police_rounded, const Color(0xFF3A5BD9), t.hlPolice, t.hlPoliceDesc),
      _Line('101', Icons.local_fire_department_rounded, const Color(0xFFFF6A00), t.hlFire, t.hlFireDesc),
      _Line('112', Icons.sos_rounded, AppColors.danger, t.hlUnified, t.hlUnifiedDesc),
    ];
    final civic = <_Line>[
      _Line('1912', Icons.bolt_rounded, AppColors.electricity, t.hlPower, t.hlPowerDesc),
      _Line('1070', Icons.flood_rounded, AppColors.weatherBlue, t.hlDisaster, t.hlDisasterDesc),
      _Line('1033', Icons.add_road_rounded, AppColors.road, t.hlHighway, t.hlHighwayDesc),
      _Line('181', Icons.woman_rounded, const Color(0xFFD6409F), t.hlWomen, t.hlWomenDesc),
      _Line('1098', Icons.child_care_rounded, AppColors.success, t.hlChild, t.hlChildDesc),
    ];

    Widget group(String header, List<_Line> lines, {String? footer}) => GroupedSection(
          header: header,
          footer: footer,
          dividerIndent: 58,
          children: [
            for (final l in lines)
              GroupedRow(
                icon: l.icon,
                iconColor: l.color,
                title: l.title,
                subtitle: l.desc,
                onTap: () => _call(l.number),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: ShapeDecoration(color: AppColors.primaryTint, shape: squircle(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.call_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(l.number, style: AppTextStyles.subheadline.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
          ],
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
      slivers: [
        LargeTitleSliver(title: t.helpTitle, showBack: true),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
            child: Text(t.helpSubtitle, style: AppTextStyles.callout.copyWith(color: AppColors.secondaryLabel)),
          ),
        ),
        SliverList.list(children: [
          group(t.helpEmergency, emergency),
          group(t.helpCivic, civic, footer: t.helpNote),
          const SizedBox(height: 24),
        ]),
      ],
      ),
    );
  }
}

class _Line {
  final String number;
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _Line(this.number, this.icon, this.color, this.title, this.desc);
}
