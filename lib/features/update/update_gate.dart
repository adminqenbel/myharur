import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/update_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/safe_launch.dart';
import '../../core/widgets/ui.dart';

/// Wraps the app. Shows the blocking page when the installed build is too old, and a dismissible popup
/// (snoozed for 24 h) when a newer build exists.
class UpdateGate extends StatefulWidget {
  final Widget child;
  const UpdateGate({super.key, required this.child});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  static const _snoozeKey = 'update_snooze_until';
  bool _popupShownThisLaunch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UpdateService.level.addListener(_maybePopup);
    UpdateService.check();
    _maybePopup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UpdateService.level.removeListener(_maybePopup);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) UpdateService.check();
  }

  Future<bool> _snoozed() async {
    try {
      final until = (await SharedPreferences.getInstance()).getInt(_snoozeKey) ?? 0;
      return DateTime.now().millisecondsSinceEpoch < until;
    } catch (_) {
      return false;
    }
  }

  Future<void> _snooze() async {
    try {
      final until = DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
      await (await SharedPreferences.getInstance()).setInt(_snoozeKey, until);
    } catch (_) {}
  }

  Future<void> _maybePopup() async {
    if (UpdateService.level.value != UpdateLevel.available || _popupShownThisLaunch) return;
    if (await _snoozed() || !mounted) return;
    _popupShownThisLaunch = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final t = context.t;
      final lang = Localizations.localeOf(context).languageCode;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.updateAvailableTitle),
          content: Text(UpdateService.info?.message(lang) ?? t.updateAvailableBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.updateLater)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.updateNow)),
          ],
        ),
      );
      if (go == true) {
        safeLaunch(UpdateService.info?.url);
      } else {
        _snooze();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UpdateLevel>(
      valueListenable: UpdateService.level,
      builder: (context, level, _) => level == UpdateLevel.required ? const UpdateRequiredPage() : widget.child,
    );
  }
}

/// This version is no longer supported: the only action is to update.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final lang = Localizations.localeOf(context).languageCode;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.system_update_rounded, size: 56, color: AppColors.primary),
                  const SizedBox(height: 20),
                  Text(t.updateRequiredTitle, textAlign: TextAlign.center, style: AppTextStyles.title1),
                  const SizedBox(height: 10),
                  Text(UpdateService.info?.message(lang) ?? t.updateRequiredBody,
                      textAlign: TextAlign.center, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
                  const SizedBox(height: 28),
                  PrimaryButton(label: t.updateNow, icon: Icons.download_rounded, onPressed: () => safeLaunch(UpdateService.info?.url)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
