import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/core/models/user_profile.dart';
import 'package:myharur/core/services/auth_service.dart';
import 'package:myharur/core/services/support_service.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/features/support/support_bot_page.dart';
import 'package:myharur/features/support/support_faq.dart';

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

void main() {
  setUp(() => AuthService.debugSetProfile(const UserProfile(id: 'u1', mmid: 'MM-1', username: '@hema', fullName: 'Hema', email: 'h@example.com')));

  group('FAQ data', () {
    test('every entry has both languages, a topic, and keywords', () {
      final topics = supportTopics.map((t) => t.$1).toSet();
      final ids = <String>{};
      for (final e in faqEntries) {
        expect(ids.add(e.id), isTrue, reason: 'duplicate id ${e.id}');
        expect(topics, contains(e.topic), reason: e.id);
        expect(e.qEn.trim(), isNotEmpty);
        expect(e.qTa.trim(), isNotEmpty);
        expect(e.aEn.trim().length, greaterThan(20), reason: e.id);
        expect(e.aTa.trim().length, greaterThan(20), reason: e.id);
        expect(e.keywords, isNotEmpty, reason: e.id);
      }
      for (final t in topics) {
        expect(faqForTopic(t), isNotEmpty, reason: 'topic $t has no questions');
      }
    });

    test('answers name real screens, not invented ones', () {
      final all = faqEntries.map((e) => e.aEn).join('\n');
      expect(all, contains('"Username password"'));
      expect(all, contains('"Security by QenShar"'));
      expect(all, isNot(contains('Protected by QenShar')));
      expect(all, isNot(contains('Password for username sign-in')));
    });

    test('no answer asks people to share a password, code or number', () {
      for (final e in faqEntries) {
        expect(e.aEn.toLowerCase(), isNot(contains('send us your password')));
        expect(e.aEn.toLowerCase(), isNot(contains('tell us your otp')));
      }
    });
  });

  group('matching', () {
    test('finds the right answer for typical questions', () {
      expect(bestFaqMatch('how do I login')?.id, 'signin');
      expect(bestFaqMatch('i forgot my password')?.id, 'forgot');
      expect(bestFaqMatch('how do i set a password for username login')?.id, 'username');
      expect(bestFaqMatch('why is my post not showing')?.id, 'review');
      expect(bestFaqMatch('how to add photos to a report')?.id, anyOf('photos', 'report_how'));
      expect(bestFaqMatch('ambulance number')?.id, 'emergency');
      expect(bestFaqMatch('the app crashed')?.id, 'bug');
    });

    test('matches Tamil questions', () {
      expect(bestFaqMatch('கடவுச்சொல்லை மறந்துவிட்டேன்')?.id, 'forgot');
      expect(bestFaqMatch('அவசர எண்கள் என்ன')?.id, 'emergency');
      expect(bestFaqMatch('மொழியை மாற்று')?.id, 'language');
    });

    test('nonsense and one-letter input match nothing', () {
      expect(bestFaqMatch('zzzz qqqq'), isNull);
      expect(bestFaqMatch('a'), isNull);
      expect(bestFaqMatch('   '), isNull);
    });
  });

  group('the e-mail to the team', () {
    test('goes to both addresses with the details the team needs, and nothing secret', () async {
      final link = await SupportService.buildSupportMailto(
        profile: AuthService.currentProfile,
        accountEmail: 'h@example.com',
        language: 'en',
        intro: 'Please describe your problem above this line.',
        autoHeader: 'Details added automatically (no passwords or tokens):',
        subject: 'MyHarur support',
        now: DateTime.utc(2026, 9, 27, 10, 30),
      );
      expect(link, startsWith('mailto:adminqenbel@gmail.com,connectwithhemapriyan@gmail.com?'));
      final uri = Uri.parse(link);
      final params = Uri.splitQueryString(uri.query.replaceAll('+', '%2B'));
      expect(params['subject'], 'MyHarur support');
      final body = params['body']!;
      expect(body, contains('Username: @hema'));
      expect(body, contains('Member ID: MM-1'));
      expect(body, contains('Account e-mail: h@example.com'));
      expect(body, contains('App version:'));
      expect(body, contains('Phone:'));
      expect(body, contains('Language: en'));
      expect(body, contains('Time: 2026-09-27T10:30:00.000Z'));
      expect(body, isNot(contains('Bearer')));
      expect(body.toLowerCase(), isNot(contains('access_token')));
      expect(body.toLowerCase(), isNot(contains('refresh')));
      expect(link, isNot(contains('+'))); // spaces are %20, so mail apps do not show plus signs
      expect(link.length, lessThan(2000));
    });
  });

  group('chat', () {
    testWidgets('starts with a greeting and the four topics', (tester) async {
      await tester.pumpWidget(_app(const SupportBotPage()));
      await tester.pump();
      expect(find.textContaining("I'm the MyHarur help assistant"), findsOneWidget);
      expect(find.text('Sign-in & account'), findsOneWidget);
      expect(find.text('Reports & news'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);
      expect(find.text('The app'), findsOneWidget);
      expect(find.text('E-mail support'), findsOneWidget);
    });

    testWidgets('a topic lists its questions and a question shows its answer with "did this help?"', (tester) async {
      await tester.pumpWidget(_app(const SupportBotPage()));
      await tester.pump();
      await tester.tap(find.text('Sign-in & account'));
      await tester.pumpAndSettle();
      expect(find.text('How do I sign in?'), findsOneWidget);
      await tester.tap(find.text('I forgot my password'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sign in with Google (it always works)'), findsOneWidget);
      expect(find.text('Yes, thanks'), findsOneWidget);
      expect(find.text('Not really'), findsOneWidget);
    });

    testWidgets('typing a question that matches answers from the FAQ, without the AI', (tester) async {
      await tester.pumpWidget(_app(const SupportBotPage()));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'why is my post not showing');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(find.textContaining('reviewed by a moderator or admin'), findsOneWidget);
      expect(find.text('Ask the AI assistant'), findsNothing); // only offered after "Not really"
    });

    testWidgets('"Not really" offers the AI and e-mail; an unmatched question does too', (tester) async {
      await tester.pumpWidget(_app(const SupportBotPage()));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'how do I sign in');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not really'));
      await tester.pumpAndSettle();
      expect(find.text('Ask the AI assistant'), findsOneWidget);
      expect(find.text('E-mail support'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzz qqqq');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(find.textContaining("couldn't find that in our help topics"), findsOneWidget);
      expect(find.text('Ask the AI assistant'), findsOneWidget);
    });

    testWidgets('asking the AI with no backend explains that it is unavailable and offers e-mail', (tester) async {
      await tester.pumpWidget(_app(const SupportBotPage()));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'zzzz qqqq');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ask the AI assistant'));
      await tester.pumpAndSettle();
      expect(find.textContaining("isn't available right now"), findsOneWidget);
      expect(find.text('E-mail support'), findsOneWidget);
    });

    testWidgets('the whole chat renders in Tamil', (tester) async {
      await tester.pumpWidget(_app(const SupportBotPage(), locale: const Locale('ta')));
      await tester.pump();
      expect(find.text('ஆதரவு அரட்டை'), findsOneWidget);
      expect(find.text('உள்நுழைவு & கணக்கு'), findsOneWidget);
    });
  });
}
