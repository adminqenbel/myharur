import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/widgets/ui.dart';

/// English | தமிழ் segmented switch. Applies immediately and is remembered.
class LanguageSwitch extends StatelessWidget {
  final double? width;
  const LanguageSwitch({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    final ctl = LocaleController.instance;
    return ListenableBuilder(
      listenable: ctl,
      builder: (context, _) => SizedBox(
        width: width,
        child: SegmentedPill(
          labels: const ['English', 'தமிழ்'],
          selected: ctl.isTamil ? 1 : 0,
          onChanged: (i) => ctl.setLanguage(i == 1 ? 'ta' : 'en'),
        ),
      ),
    );
  }
}
