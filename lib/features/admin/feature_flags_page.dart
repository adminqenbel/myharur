import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/feature_flag_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// FEATURE FLAGS (super admin, two-factor session required). Turns Events and Jobs on or off for
// everyone, instantly — no app update needed. Only modules the app actually knows how to show are
// offered here; the database holds a few more (tournaments, chat, marketplace…) for later modules
// that are not built into the app yet, so turning them on here would do nothing visible.
// ==============================================================================
class FeatureFlagsPage extends StatefulWidget {
  const FeatureFlagsPage({super.key});

  @override
  State<FeatureFlagsPage> createState() => _FeatureFlagsPageState();
}

class _FeatureFlagsPageState extends State<FeatureFlagsPage> {
  bool _loading = true;
  final Set<String> _busy = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await FeatureFlagService.refresh();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(String module, bool value) async {
    final t = context.t;
    setState(() {
      _busy.add(module);
      _error = null;
    });
    final err = await FeatureFlagService.adminSetFlag(module, value);
    if (!mounted) return;
    setState(() {
      _busy.remove(module);
      if (err != null) _error = t.flagChangeFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rows = {
      'events': (title: t.flagEvents, subtitle: t.flagEventsSub, icon: Icons.event_rounded),
      'jobs': (title: t.flagJobs, subtitle: t.flagJobsSub, icon: Icons.work_rounded),
    };
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.featureFlags, showBack: true),
          refreshSliver(_load),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
          else ...[
            SliverToBoxAdapter(
              child: GroupedSection(
                footer: _error ?? t.flagOtherNote,
                dividerIndent: 58,
                children: [
                  for (final e in rows.entries)
                    GroupedRow(
                      icon: e.value.icon,
                      iconColor: AppColors.primary,
                      title: e.value.title,
                      subtitle: e.value.subtitle,
                      trailing: _busy.contains(e.key)
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
                          : Switch.adaptive(value: FeatureFlagService.isEnabled(e.key), onChanged: (v) => _toggle(e.key, v)),
                    ),
                ],
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
