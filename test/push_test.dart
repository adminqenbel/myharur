import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/core/services/push_service.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/features/account/notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for Firebase: no plugin, no network.
class FakePush implements PushBackend {
  bool ready;
  bool granted;
  bool grantWhenAsked;
  int permissionRequests = 0;
  final _opened = StreamController<void>.broadcast();
  final _refresh = StreamController<String>.broadcast();
  FakePush({this.ready = true, this.granted = false, this.grantWhenAsked = true});

  void tapNotification() => _opened.add(null);

  @override
  Future<bool> firebaseReady() async => ready;
  @override
  Future<bool> permissionGranted() async => granted;
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (grantWhenAsked) granted = true;
    return grantWhenAsked;
  }

  @override
  Future<String?> token() async => 'fake-token-fake-token-fake-token';
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<String> get onTokenRefresh => _refresh.stream;
  @override
  Stream<void> get onNotificationOpened => _opened.stream;
  @override
  Future<bool> launchedFromNotification() async => false;
}

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('state', () {
    test('without a Firebase config the service reports "unavailable" and never asks for permission', () async {
      final fake = FakePush(ready: false);
      PushService.debugUseBackend(fake);
      expect(await PushService.refresh(), PushState.unavailable);
      expect(await PushService.turnOn(), PushState.unavailable);
      expect(fake.permissionRequests, 0);
    });

    test('turning on asks the system once; a refusal is reported as blocked', () async {
      final fake = FakePush(grantWhenAsked: false);
      PushService.debugUseBackend(fake);
      expect(await PushService.turnOn(), PushState.blocked);
      expect(fake.permissionRequests, 1);
    });

    test('an allowed permission turns notifications on', () async {
      final fake = FakePush();
      PushService.debugUseBackend(fake);
      expect(await PushService.turnOn(), PushState.on);
      expect(PushService.state.value, PushState.on);
    });

    test('tapping a notification asks the app to open Reports', () async {
      final fake = FakePush();
      PushService.debugUseBackend(fake);
      final before = PushService.openReportsRequests.value;
      await PushService.syncOnSignIn();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      fake.tapNotification();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(PushService.openReportsRequests.value, before + 1);
    });
  });

  group('settings page', () {
    testWidgets('says so plainly when this build cannot send notifications, and the switch is disabled', (tester) async {
      PushService.debugUseBackend(FakePush(ready: false));
      await tester.pumpWidget(_app(const NotificationsPage()));
      await tester.pumpAndSettle();
      expect(find.text("Notifications aren't set up in this version of the app yet."), findsWidgets);
      final master = tester.widget<Switch>(find.byType(Switch).first);
      expect(master.onChanged, isNull);
    });

    testWidgets('shows the promise: one summary a day, two event alerts a week, quiet at night', (tester) async {
      PushService.debugUseBackend(FakePush());
      await tester.pumpWidget(_app(const NotificationsPage()));
      await tester.pumpAndSettle();
      expect(find.textContaining('At most one report summary a day and two event alerts a week'), findsOneWidget);
      expect(find.text('New reports (daily summary)'), findsOneWidget);
      expect(find.text('Events (coming soon)'), findsOneWidget);
    });

    testWidgets('the per-kind switches are disabled until notifications are on', (tester) async {
      PushService.debugUseBackend(FakePush());
      await tester.pumpWidget(_app(const NotificationsPage()));
      await tester.pumpAndSettle();
      final kinds = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(kinds.length, 3);
      expect(kinds[1].onChanged, isNull);
      expect(kinds[2].onChanged, isNull);
    });

    testWidgets('a refused system permission explains how to fix it', (tester) async {
      PushService.debugUseBackend(FakePush(grantWhenAsked: false));
      await tester.pumpWidget(_app(const NotificationsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(find.textContaining("Allow them in your phone's settings"), findsOneWidget);
    });
  });

  group('one-time prompt', () {
    testWidgets('is not shown when the build cannot send notifications, and is not used up', (tester) async {
      PushService.debugUseBackend(FakePush(ready: false));
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      await maybeAskAboutNotifications(ctx);
      await tester.pumpAndSettle();
      expect(find.text('Stay in the loop?'), findsNothing);
      expect((await SharedPreferences.getInstance()).getBool('push_prompted_v1'), isNull);
    });

    testWidgets('asks once; "Not now" is remembered and it does not ask again', (tester) async {
      PushService.debugUseBackend(FakePush());
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      unawaited(maybeAskAboutNotifications(ctx));
      await tester.pumpAndSettle();
      expect(find.text('Stay in the loop?'), findsOneWidget);
      expect(find.textContaining('one short summary a day'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect((await SharedPreferences.getInstance()).getBool('push_prompted_v1'), isTrue);

      unawaited(maybeAskAboutNotifications(ctx));
      await tester.pumpAndSettle();
      expect(find.text('Stay in the loop?'), findsNothing);
    });
  });
}
