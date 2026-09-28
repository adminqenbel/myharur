import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/core/models/place.dart';
import 'package:myharur/core/models/user_profile.dart';
import 'package:myharur/core/services/auth_service.dart';
import 'package:myharur/core/services/error_reporter.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/core/util/safe_launch.dart';
import 'package:myharur/core/widgets/ui.dart';
import 'package:myharur/features/auth/auth_page.dart';
import 'package:myharur/features/auth/otp_signin_page.dart';
import 'package:myharur/features/errors/error_pages.dart';
import 'package:myharur/features/home/home_page.dart' show Rail;
import 'package:myharur/features/map/location_preview.dart';

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: home),
    );

void main() {
  group('Link safety', () {
    test('only https, tel, mailto and geo are opened', () {
      expect(parseSafeUri('https://www.thehindu.com/news'), isNotNull);
      expect(parseSafeUri('tel:108'), isNotNull);
      expect(parseSafeUri('mailto:adminqenbel@gmail.com'), isNotNull);
      expect(parseSafeUri('geo:12.06,78.49'), isNotNull);

      for (final bad in [
        'http://insecure.example.com', // plain http
        'javascript:alert(1)',
        'file:///sdcard/secret.txt',
        'intent://scan/#Intent;scheme=zxing;end',
        'content://contacts/people',
        'data:text/html,<script>1</script>',
        'https://trusted.com@evil.example.com/login', // credentials trick
        'https://', // no host
        '',
        '   ',
      ]) {
        expect(parseSafeUri(bad), isNull, reason: bad);
      }
      expect(parseSafeUri(null), isNull);
      expect(parseSafeUri('https://a.com/${'x' * 3000}'), isNull, reason: 'over-long links are refused');
    });

    test('Google Maps deep links carry the coordinates', () {
      expect(googleMapsUri(12.0624, 78.4983).toString(), 'https://www.google.com/maps/search/?api=1&query=12.0624%2C78.4983');
      expect(googleMapsDirectionsUri(12.0624, 78.4983).queryParameters['destination'], '12.0624,78.4983');
    });
  });

  group('Places', () {
    test('a location can be a pin, typed text, or both', () {
      expect(const PickedLocation().isEmpty, isTrue);
      expect(const PickedLocation(text: '  ').isEmpty, isTrue);
      expect(const PickedLocation(text: '12 Bazaar St').hasCoordinates, isFalse);
      const pin = PickedLocation(lat: 12.06, lng: 78.49, source: 'map');
      expect(pin.hasCoordinates, isTrue);
      expect(pin.label, '12.0600, 78.4900');
      expect(const PickedLocation(lat: 12.06, lng: 78.49, text: 'Temple gate').label, 'Temple gate');
    });

    test('database columns round-trip, and empty means null', () {
      const p = PickedLocation(lat: 12.0624, lng: 78.4983, text: ' Temple gate ', source: 'gps');
      final cols = p.toColumns('location');
      expect(cols, {'location_text': 'Temple gate', 'location_lat': 12.0624, 'location_lng': 78.4983, 'location_source': 'gps'});
      expect(PickedLocation.fromColumns(text: 'Temple gate', lat: 12.0624, lng: 78.4983, source: 'gps'), isNotNull);
      expect(PickedLocation.fromColumns(), isNull);
      expect(const PickedLocation().toColumns('address')['address_source'], isNull);
    });

    test('the map opens on Harur', () {
      expect(kHarurLat, closeTo(12.0624, 0.0001));
      expect(kHarurLng, closeTo(78.4983, 0.0001));
    });

    test('profiles have no ward and an address that is null for existing users', () {
      final p = UserProfile.fromJson({'id': 'u1', 'email': 'a@b.c', 'ward_id': 4}); // old rows may still carry ward_id: ignored
      expect(p.address, isNull);
      final q = UserProfile.fromJson({'id': 'u2', 'address_text': 'Bazaar St', 'address_lat': 12.06, 'address_lng': 78.49, 'address_source': 'map'});
      expect(q.address!.text, 'Bazaar St');
      expect(q.address!.hasCoordinates, isTrue);
      expect(q.copyWith(clearAddress: true).address, isNull);
    });

    testWidgets('a typed-only location shows its text and a Google Maps action, no map', (tester) async {
      await tester.pumpWidget(_app(const LocationPreview(location: PickedLocation(text: 'Near the bus stand, Harur'))));
      expect(find.text('Near the bus stand, Harur'), findsOneWidget);
      expect(find.text('Open in Google Maps'), findsOneWidget);
      expect(find.text('Directions'), findsNothing); // directions need coordinates
    });
  });

  group('Passwords and roles', () {
    test('strong password rules', () {
      expect(AuthService.isStrongPassword('correct-horse-9', username: '@hema'), isTrue);
      expect(AuthService.isStrongPassword('short1'), isFalse);
      expect(AuthService.isStrongPassword('onlylettersnodigits'), isFalse);
      expect(AuthService.isStrongPassword('1234567890123'), isFalse, reason: 'needs letters too');
      expect(AuthService.isStrongPassword('hemapriyan12345', username: '@hemapriyan'), isFalse, reason: 'must not contain the username');
      expect(AuthService.isStrongPassword('a1' * 70), isFalse, reason: 'over 128 characters');
    });

    test('admins and super admins must use two-factor; residents and moderators need not', () {
      UserProfile with_(List<String> roles) => UserProfile(id: 'u', mmid: '1', username: '@u', fullName: 'U', email: 'u@x', roles: roles);
      expect(with_(['resident']).requiresMfa, isFalse);
      expect(with_(['resident', 'moderator']).requiresMfa, isFalse);
      expect(with_(['resident', 'admin']).requiresMfa, isTrue);
      expect(with_(['resident', 'superadmin']).requiresMfa, isTrue);
    });
  });

  group('Error reporting', () {
    test('tokens and e-mail addresses are removed before anything is sent', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abcDEF123_-xyz';
      final clean = AppErrors.sanitize('failed for hema@example.com token $jwt key ${'A' * 40}');
      expect(clean, isNot(contains('hema@example.com')));
      expect(clean, isNot(contains('eyJ')));
      expect(clean, isNot(contains('AAAAAAAAAAAAAAAA')));
      expect(clean, allOf(contains('[email]'), contains('[token]'), contains('[redacted]')));
      expect(AppErrors.sanitize('x' * 5000, max: 100).length, lessThanOrEqualTo(100));
    });

    test('a crash loop (3 different errors in 10 s) shows the crash page; one error does not', () {
      AppErrors.crash.value = null;
      AppErrors.handle(StateError('first problem'), null);
      expect(AppErrors.crash.value, isNull);
      AppErrors.handle(StateError('second problem'), null);
      expect(AppErrors.crash.value, isNull);
      AppErrors.handle(StateError('third problem'), null);
      expect(AppErrors.crash.value, isNotNull);
      AppErrors.restart();
      expect(AppErrors.crash.value, isNull);
    });
  });

  group('Sign in vs register', () {
    testWidgets('sign in offers Google and username + password; register offers Google only', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AuthPage(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign in with username'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // username + password
      expect(find.text('Register with Google'), findsNothing);

      await tester.tap(find.text('Register').last);
      await tester.pumpAndSettle();

      expect(find.text('Register with Google'), findsOneWidget);
      expect(find.byType(TextField), findsNothing, reason: 'there is no email/username sign-up form');
      expect(find.text('Sign in with username'), findsNothing);
    });

    testWidgets('both tabs also offer e-mail/phone codes', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AuthPage(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Continue with email'), findsOneWidget);
      expect(find.text('Continue with phone'), findsOneWidget);

      await tester.tap(find.text('Register').last);
      await tester.pumpAndSettle();
      expect(find.text('Continue with email'), findsOneWidget);
      expect(find.text('Continue with phone'), findsOneWidget);
    });

    testWidgets('the OTP code screen catches an invalid e-mail/phone before ever trying to send one', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const OtpSignInPage(isPhone: false),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Continue with email'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'not-an-email');
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Enter a valid e-mail address.'), findsOneWidget);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const OtpSignInPage(isPhone: true),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Continue with phone'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1234567890'); // Indian mobiles never start 0-5
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Enter a valid 10-digit Indian mobile number.'), findsOneWidget);
    });

    testWidgets('the failure page explains each reason and offers a way forward', (tester) async {
      for (final (reason, text) in [
        (AuthFailureReason.cancelled, 'Sign-in was cancelled.'),
        (AuthFailureReason.timeout, 'Sign-in took too long. Please try again.'),
        (AuthFailureReason.network, 'No internet connection. Check your connection and try again.'),
        (AuthFailureReason.failed, 'Something went wrong while signing in. Nothing was changed on your account.'),
      ]) {
        await tester.pumpWidget(_app(AuthFailurePage(reason: reason, onUseUsername: () {})));
        expect(find.text("Couldn't sign you in"), findsOneWidget);
        expect(find.text(text), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.text('Use username instead'), findsOneWidget);
      }
    });
  });

  group('Error pages', () {
    testWidgets('crash page: restart, and the whole thing works in Tamil', (tester) async {
      await tester.pumpWidget(_app(const CrashPage(info: CrashInfo('boom', null))));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
      await tester.pumpWidget(_app(const CrashPage(info: CrashInfo('boom', null)), locale: const Locale('ta')));
      expect(find.text('ஏதோ தவறு நடந்துவிட்டது'), findsOneWidget);
    });

    testWidgets('offline and not-found pages', (tester) async {
      var retried = 0;
      await tester.pumpWidget(_app(OfflinePage(onRetry: () => retried++)));
      expect(find.text("You're offline"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);

      await tester.pumpWidget(_app(const NotFoundPage()));
      expect(find.text('Page not found'), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);
    });
  });

  group('Navigation and Home', () {
    testWidgets('six-tab bar with a badge: switching never changes any size', (tester) async {
      var selected = 0;
      final tabs = [
        const TabSpec('Home', Icons.home_outlined, Icons.home_rounded),
        const TabSpec('News', Icons.newspaper_outlined, Icons.newspaper_rounded),
        const TabSpec('Weather', Icons.cloud_outlined, Icons.cloud_rounded),
        const TabSpec('Reports', Icons.campaign_outlined, Icons.campaign_rounded),
        const TabSpec('Review', Icons.fact_check_outlined, Icons.fact_check_rounded, badge: 7),
        const TabSpec('Account', Icons.person_outline_rounded, Icons.person_rounded),
      ];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) => AppTabBar(selected: selected, tabs: tabs, onTap: (i) => setState(() => selected = i)),
          ),
        ),
      ));
      expect(find.text('7'), findsOneWidget); // the pending-review badge

      final barSize = tester.getSize(find.byType(AppTabBar));
      final labelSizes = {for (final t in tabs) t.label: tester.getSize(find.text(t.label))};
      for (final label in ['Review', 'Account', 'Reports', 'Home']) {
        await tester.tap(find.text(label));
        await tester.pump(const Duration(milliseconds: 120));
        expect(tester.getSize(find.byType(AppTabBar)), barSize);
        await tester.pumpAndSettle();
        for (final t in tabs) {
          expect(tester.getSize(find.text(t.label)), labelSizes[t.label], reason: '${t.label} resized after selecting $label');
        }
      }
      expect(selected, 0);
    });

    testWidgets('a Home rail shows its cards, "See all", and an empty state', (tester) async {
      var seeAll = 0;
      await tester.pumpWidget(_app(SingleChildScrollView(
        child: Column(children: [
          Rail(title: 'Latest reports', height: 100, onSeeAll: () => seeAll++, children: const [Text('card one'), Text('card two')]),
          Rail(title: 'Latest news', height: 100, onSeeAll: () {}, emptyText: 'No news yet', children: const []),
        ]),
      )));
      expect(find.text('Latest reports'), findsOneWidget);
      expect(find.text('card one'), findsOneWidget);
      expect(find.text('No news yet'), findsOneWidget);
      await tester.tap(find.text('See all').first);
      expect(seeAll, 1);
    });
  });
}
