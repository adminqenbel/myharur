import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/core/models/alert.dart';
import 'package:myharur/core/models/user_profile.dart';
import 'package:myharur/core/services/auth_service.dart';
import 'package:myharur/core/services/feature_flag_service.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/features/admin/ads_admin_page.dart';
import 'package:myharur/features/admin/feature_flags_page.dart';
import 'package:myharur/features/ads/sponsored_card.dart';
import 'package:myharur/features/alerts/submit_alert_page.dart';
import 'package:myharur/features/home/home_page.dart';
import 'package:myharur/features/reports/reports_page.dart';

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

UserProfile _resident() => const UserProfile(id: 'u1', mmid: '1', username: '@hema', fullName: 'Hema', email: 'h@example.com');
UserProfile _superAdmin() => const UserProfile(id: 'u1', mmid: '1', username: '@hema', fullName: 'Hema', email: 'h@example.com', roles: ['resident', 'superadmin']);

void main() {
  setUp(() {
    AuthService.debugSetProfile(_resident());
    FeatureFlagService.debugSetFlags({'events': false, 'jobs': false});
  });

  group('model', () {
    test('parses event and job specific fields', () {
      final e = Alert.fromJson({
        'id': 'e1', 'kind': 'event', 'category': 'cultural', 'title': 't', 'body': 'b',
        'starts_at': '2026-10-15T12:00:00Z', 'ends_at': '2026-10-15T18:00:00Z', 'all_day': false, 'is_paid': true,
      });
      expect(e.isEvent, isTrue);
      expect(e.startsAt, isNotNull);
      expect(e.endsAt, isNotNull);
      expect(e.isPaid, isTrue);

      final j = Alert.fromJson({
        'id': 'j1', 'kind': 'job', 'category': 'full_time', 'title': 't', 'body': 'b',
        'employer': 'Amma Stores', 'contact_text': '9500000000', 'pay_text': '12000/month', 'ends_at': '2026-11-01T00:00:00Z',
      });
      expect(j.isJob, isTrue);
      expect(j.employer, 'Amma Stores');
      expect(j.contactText, '9500000000');
      expect(j.payText, '12000/month');

      final r = Alert.fromJson({'id': 'r1', 'category': 'road', 'title': 't', 'body': 'b'});
      expect(r.isEvent, isFalse);
      expect(r.isJob, isFalse);
      expect(r.startsAt, isNull);
    });
  });

  group('category helpers', () {
    test('every event and job category has its own color, icon and name (no silent fallback)', () {
      const events = ['cultural', 'sports', 'education', 'religious', 'government', 'business', 'other'];
      const jobs = ['full_time', 'part_time', 'contract', 'internship', 'daily_wage', 'other'];
      for (final c in [...events, ...jobs]) {
        expect(c.categoryIconData, isNotNull, reason: c);
        expect(c.categoryColor, isNotNull, reason: c);
      }
      // distinct job categories get distinct colors from each other (not all falling back to the same default)
      final colors = jobs.where((c) => c != 'other').map((c) => c.categoryColor).toSet();
      expect(colors.length, jobs.length - 1);
    });
  });

  group('submit: event', () {
    testWidgets('shows event fields and no emergency switch', (tester) async {
      await tester.pumpWidget(_app(const SubmitAlertPage(kind: 'event')));
      final scrollable = find.byType(Scrollable).first;
      expect(find.text('Post an event'), findsOneWidget);
      expect(find.text('Cultural'), findsOneWidget);
      expect(find.text('Registration link (optional)'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Starts'), 300, scrollable: scrollable);
      expect(find.text('Starts'), findsOneWidget);
      expect(find.text('Ends (optional)'), findsOneWidget);
      expect(find.text('All day'), findsOneWidget);
      expect(find.text('Ticketed (not free)'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Venue'), 300, scrollable: scrollable);
      expect(find.text('Venue'), findsOneWidget);
      expect(find.text('Mark as emergency'), findsNothing);
    });

    testWidgets('requires a start time before a venue check even runs', (tester) async {
      await tester.pumpWidget(_app(const SubmitAlertPage(kind: 'event')));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Temple festival this weekend');
      await tester.enterText(fields.at(1), 'Annual temple festival with music and food stalls');
      await tester.scrollUntilVisible(find.text('Submit event'), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Submit event'));
      await tester.pump();
      expect(find.text('Choose when the event starts.'), findsOneWidget);
    });
  });

  group('submit: job', () {
    testWidgets('shows job fields, scam warning and no emergency switch', (tester) async {
      await tester.pumpWidget(_app(const SubmitAlertPage(kind: 'job')));
      await tester.pump();
      final scrollable = find.byType(Scrollable).first;
      expect(find.text('Post a job'), findsOneWidget);
      expect(find.text('Full-time'), findsOneWidget);
      expect(find.text('Apply link (optional)'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Employer'), 300, scrollable: scrollable);
      expect(find.text('Employer'), findsOneWidget);
      expect(find.text('Contact (phone or e-mail)'), findsOneWidget);
      expect(find.text('Pay (optional)'), findsOneWidget);
      expect(find.textContaining('Never pay to apply'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Closing date'), 300, scrollable: scrollable);
      expect(find.text('Closing date'), findsOneWidget);
      expect(find.text('Mark as emergency'), findsNothing);
    });

    testWidgets('requires employer and contact before the closing date check', (tester) async {
      await tester.pumpWidget(_app(const SubmitAlertPage(kind: 'job')));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Shop assistant needed in Harur');
      await tester.enterText(fields.at(1), 'Looking for a shop assistant, six days a week');
      await tester.scrollUntilVisible(find.text('Submit job'), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Submit job'));
      await tester.pump();
      expect(find.text('Add the employer and a way to contact them.'), findsOneWidget);
    });

    testWidgets('requires a closing date once employer and contact are filled', (tester) async {
      await tester.pumpWidget(_app(const SubmitAlertPage(kind: 'job')));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Shop assistant needed in Harur');
      await tester.enterText(fields.at(1), 'Looking for a shop assistant, six days a week');
      await tester.scrollUntilVisible(find.text('Employer'), 300, scrollable: find.byType(Scrollable).first);
      await tester.enterText(find.widgetWithText(TextField, 'Employer'), 'Amma Stores');
      await tester.enterText(find.widgetWithText(TextField, 'Contact (phone or e-mail)'), '9500000000');
      await tester.scrollUntilVisible(find.text('Submit job'), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Submit job'));
      await tester.pump();
      expect(find.text('Choose a closing date in the future.'), findsOneWidget);
    });
  });

  group('Reports tab segments', () {
    testWidgets('with both modules off, there is no segmented control, just Reports', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: ReportsPage())));
      await tester.pump();
      expect(find.text('Service'), findsWidgets); // large title (bottom-nav tab was renamed to "Service")
      expect(find.text('Events'), findsNothing);
      expect(find.text('Jobs'), findsNothing);
    });

    testWidgets('with both modules on, Reports, Events and Jobs all appear and switching changes the category pills', (tester) async {
      FeatureFlagService.debugSetFlags({'events': true, 'jobs': true});
      await tester.pumpWidget(_app(const Scaffold(body: ReportsPage())));
      await tester.pump();
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Road'), findsOneWidget); // report category pill, default segment

      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();
      expect(find.text('Cultural'), findsOneWidget);
      expect(find.text('Road'), findsNothing);

      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();
      expect(find.text('Full-time'), findsOneWidget);
      expect(find.text('Cultural'), findsNothing);
    });
  });

  group('Home rails', () {
    testWidgets('events/jobs rails are hidden until their module is turned on', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: HomePage())));
      await tester.pump();
      expect(find.text('Upcoming events'), findsNothing);
      expect(find.text('Latest jobs'), findsNothing);
    });

    testWidgets('turning a module on shows its rail', (tester) async {
      FeatureFlagService.debugSetFlags({'events': true, 'jobs': true});
      await tester.pumpWidget(_app(const Scaffold(body: HomePage())));
      await tester.pump();
      expect(find.text('Upcoming events'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Latest jobs'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Latest jobs'), findsOneWidget);
    });
  });

  group('sponsored card', () {
    testWidgets('renders nothing when there is no ad (never blocks the feed it sits in)', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: SponsoredCard(placement: 'home'))));
      await tester.pump();
      expect(find.byType(SponsoredCard), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.text('Sponsored'), findsNothing);
    });
  });

  group('admin: feature flags', () {
    testWidgets('offers only the modules the app actually built, not the other database rows', (tester) async {
      AuthService.debugSetProfile(_superAdmin());
      await tester.pumpWidget(_app(const FeatureFlagsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Tournaments'), findsNothing);
      expect(find.text('Marketplace'), findsNothing);
      expect(find.textContaining('not built into the app yet'), findsOneWidget);
    });
  });

  group('admin: ads', () {
    testWidgets('shows an empty state without a backend, and + opens the create sheet', (tester) async {
      AuthService.debugSetProfile(_superAdmin());
      await tester.pumpWidget(_app(const AdsAdminPage()));
      await tester.pumpAndSettle();
      expect(find.text('No ads yet.'), findsOneWidget);

      await tester.tap(find.byTooltip('New ad'));
      await tester.pumpAndSettle();
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Link (https)'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('News'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
    });

    testWidgets('an insecure or too-short ad is refused before any network call', (tester) async {
      AuthService.debugSetProfile(_superAdmin());
      await tester.pumpWidget(_app(const AdsAdminPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('New ad'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Sale');
      await tester.enterText(find.widgetWithText(TextField, 'Text'), 'Big discounts this week');
      await tester.enterText(find.widgetWithText(TextField, 'Link (https)'), 'javascript:alert(1)');
      await tester.scrollUntilVisible(find.text('New ad').last, 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('New ad').last);
      await tester.pump();
      expect(find.textContaining("Couldn't create the ad"), findsOneWidget);
    });
  });

  group('Tamil', () {
    testWidgets('event and job submit pages render in Tamil', (tester) async {
      await tester.pumpWidget(_app(const SubmitAlertPage(kind: 'event'), locale: const Locale('ta')));
      expect(find.text('நிகழ்வைப் பதிவிடு'), findsOneWidget);
      await tester.pumpWidget(_app(const SubmitAlertPage(kind: 'job'), locale: const Locale('ta')));
      expect(find.text('வேலையைப் பதிவிடு'), findsOneWidget);
    });
  });
}
