import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/push_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// NOTIFICATIONS: master switch and one switch per kind. The limits (one report summary a day, two event
// alerts a week, quiet 10 pm - 7 am) are enforced by the server and stated here so nobody is surprised.
// ==============================================================================
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationPrefs _prefs = const NotificationPrefs();
  bool _loading = true;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await PushService.refresh();
    final p = await PushService.prefs();
    if (!mounted) return;
    setState(() {
      if (p != null) _prefs = p;
      _loading = false;
    });
  }

  Future<void> _master(bool on) async {
    final t = context.t;
    setState(() {
      _busy = true;
      _message = null;
    });
    final s = on ? await PushService.turnOn() : await PushService.turnOff();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _prefs = _prefs.copyWith(enabled: s == PushState.on);
      _message = s == PushState.blocked ? t.notifDenied : (s == PushState.unavailable ? t.notifUnavailable : null);
    });
  }

  Future<void> _kind({bool? reports, bool? events}) async {
    final next = _prefs.copyWith(reports: reports, events: events);
    setState(() => _prefs = next);
    if (!await PushService.savePrefs(next) && mounted) {
      setState(() => _message = context.t.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ValueListenableBuilder<PushState>(
      valueListenable: PushService.state,
      builder: (context, state, _) {
        final unavailable = state == PushState.unavailable;
        final on = state == PushState.on && _prefs.enabled;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              LargeTitleSliver(title: t.notifications, showBack: true),
              if (_loading)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
              else ...[
                if (unavailable) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 14), child: Banner2(icon: Icons.notifications_off_outlined, text: t.notifUnavailable, color: AppColors.warning))),
                SliverToBoxAdapter(
                  child: GroupedSection(
                    footer: _message ?? t.notifCaps,
                    dividerIndent: 58,
                    children: [
                      GroupedRow(
                        icon: Icons.notifications_active_rounded,
                        iconColor: AppColors.primary,
                        title: t.notifMaster,
                        trailing: Switch.adaptive(value: on, onChanged: unavailable || _busy ? null : _master),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Opacity(
                    opacity: on ? 1 : 0.45,
                    child: GroupedSection(
                      dividerIndent: 58,
                      children: [
                        GroupedRow(
                          icon: Icons.campaign_rounded,
                          iconColor: AppColors.road,
                          title: t.notifReports,
                          trailing: Switch.adaptive(value: _prefs.reports, onChanged: on ? (v) => _kind(reports: v) : null),
                        ),
                        GroupedRow(
                          icon: Icons.event_rounded,
                          iconColor: AppColors.govt,
                          title: t.notifEvents,
                          trailing: Switch.adaptive(value: _prefs.events, onChanged: on ? (v) => _kind(events: v) : null),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

/// A one-time, plain-language question after sign-in. Asked once per install (accepting or declining both count),
/// and only if this build can send notifications at all.
Future<void> maybeAskAboutNotifications(BuildContext context) async {
  const key = 'push_prompted_v1';
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) == true) return;
    if (await PushService.refresh() == PushState.unavailable) return; // nothing to offer yet
    if (!context.mounted) return;
    final t = context.t;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.notifPromptTitle),
        content: Text(t.notifPromptBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.notifPromptNo)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.notifPromptYes)),
        ],
      ),
    );
    await prefs.setBool(key, true);
    if (yes == true) await PushService.turnOn();
  } catch (_) {}
}
