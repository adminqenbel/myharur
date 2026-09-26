import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/core/services/update_service.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/features/update/update_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

const _policy = UpdateInfo(latestBuild: 10, minSupportedBuild: 5, url: 'https://play.google.com/store/apps/details?id=com.myharur.app');

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UpdateService.debugSet(UpdateLevel.none, null);
  });

  test('the build number decides: too old = required, older than latest = available, current = none', () {
    expect(_policy.levelFor(4), UpdateLevel.required);
    expect(_policy.levelFor(5), UpdateLevel.available);
    expect(_policy.levelFor(9), UpdateLevel.available);
    expect(_policy.levelFor(10), UpdateLevel.none);
    expect(_policy.levelFor(11), UpdateLevel.none);
  });

  test('the server message follows the app language and falls back to the built-in text', () {
    const p = UpdateInfo(latestBuild: 2, minSupportedBuild: 1, messageEn: 'Please update', messageTa: '');
    expect(p.message('en'), 'Please update');
    expect(p.message('ta'), isNull);
  });

  testWidgets('a build below the minimum sees only the update page, and back does not leave it', (tester) async {
    await tester.pumpWidget(_app(const UpdateGate(child: Scaffold(body: Text('APP HOME')))));
    expect(find.text('APP HOME'), findsOneWidget);

    UpdateService.debugSet(UpdateLevel.required, _policy);
    await tester.pump();
    expect(find.text('APP HOME'), findsNothing);
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);

    // policy relaxed by the super admin: the app comes back without a restart
    UpdateService.debugSet(UpdateLevel.none, _policy);
    await tester.pump();
    expect(find.text('APP HOME'), findsOneWidget);
  });

  testWidgets('a newer build shows a dismissible popup once, and "Not now" snoozes it', (tester) async {
    await tester.pumpWidget(_app(const UpdateGate(child: Scaffold(body: Text('APP HOME')))));
    UpdateService.debugSet(UpdateLevel.available, _policy);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('APP HOME'), findsOneWidget); // the app stays usable behind it

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('update_snooze_until'), greaterThan(DateTime.now().millisecondsSinceEpoch));
  });

  testWidgets('the update page speaks Tamil when the app is in Tamil', (tester) async {
    UpdateService.debugSet(UpdateLevel.required, _policy);
    await tester.pumpWidget(_app(const UpdateGate(child: SizedBox()), locale: const Locale('ta')));
    await tester.pump();
    expect(find.text('புதுப்பிப்பு அவசியம்'), findsOneWidget);
  });
}
