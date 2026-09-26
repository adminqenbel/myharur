import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/device_info.dart';
import '../../core/services/safety_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

/// "Report a bug": anyone signed in can send one; only super admins can read them.
/// The app version and phone model are attached automatically. Nothing personal.
Future<void> showBugReportSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _BugReportSheet(),
    );

class _BugReportSheet extends StatefulWidget {
  const _BugReportSheet();

  @override
  State<_BugReportSheet> createState() => _BugReportSheetState();
}

class _BugReportSheetState extends State<_BugReportSheet> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (_title.text.trim().length < 5 || _details.text.trim().length < 10) {
      setState(() => _error = t.bugTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await SafetyService.reportBug(_title.text, _details.text, appVersion: await DeviceInfo.appVersion(), os: await DeviceInfo.osDescription());
    if (!mounted) return;
    if (res == SafetyResult.ok) {
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(t.bugSent)));
    } else {
      setState(() {
        _busy = false;
        _error = switch (res) {
          SafetyResult.rateLimited => t.bugLimit,
          SafetyResult.invalid => t.bugTooShort,
          _ => t.reportFailed,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.reportBug, style: AppTextStyles.title2),
              const SizedBox(height: 4),
              Text(t.bugNote, style: AppTextStyles.footnote),
              const SizedBox(height: 14),
              TextField(controller: _title, maxLength: 100, decoration: InputDecoration(labelText: t.bugTitleHint)),
              TextField(controller: _details, maxLength: 2000, minLines: 3, maxLines: 6, decoration: InputDecoration(labelText: t.bugDetailsHint)),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 6, bottom: 4), child: Text(_error!, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
              const SizedBox(height: 10),
              PrimaryButton(label: t.send, loading: _busy, onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}
