import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/core/models/user_profile.dart';
import 'package:myharur/core/services/auth_service.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/features/onboarding/onboarding_page.dart';

UserProfile _at(String state) => UserProfile(
      id: 'u1',
      mmid: '1',
      username: state == 'PENDING_USERNAME' ? 'resident' : '@hema',
      fullName: 'Hema',
      email: 'h@example.com',
      onboardingState: state,
    );

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

void main() {
  setUp(OnboardingPage.debugReset);

  testWidgets('onboarding advances when the saved state changes (regression: stuck on step 1)', (tester) async {
    AuthService.debugSetProfile(_at('PENDING_USERNAME'));
    // Same const instance the real app uses in _AuthShell.
    await tester.pumpWidget(_app(const OnboardingPage()));
    expect(find.text('Step 1 of 4'), findsOneWidget);

    AuthService.debugSetProfile(_at('PENDING_PROFILE'));
    await tester.pump();
    expect(find.text('Step 1 of 4'), findsNothing);
    // the optional password step comes first (once), then "about you"
    expect(find.text('Step 2 of 4'), findsOneWidget);
    await tester.tap(find.text('Skip for now'));
    await tester.pump();
    expect(find.text('Step 3 of 4'), findsOneWidget);

    AuthService.debugSetProfile(_at('PENDING_OCCUPATION'));
    await tester.pump();
    expect(find.text('Step 4 of 4'), findsOneWidget);
  });

  testWidgets('ward is not part of onboarding and blood group is not pre-selected', (tester) async {
    AuthService.debugSetProfile(_at('PENDING_PROFILE'));
    await tester.pumpWidget(_app(const OnboardingPage()));
    await tester.tap(find.text('Skip for now')); // past the optional password step
    await tester.pump();
    expect(find.textContaining('Ward'), findsNothing);
    // No blood-group pill is selected by default (previously everyone silently got O+).
    final pills = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).where((c) {
      final d = c.decoration;
      return d is ShapeDecoration && d.color == AppColors.primary;
    });
    expect(pills, isEmpty);
  });

  testWidgets('the whole flow renders in Tamil', (tester) async {
    AuthService.debugSetProfile(_at('PENDING_USERNAME'));
    await tester.pumpWidget(_app(const OnboardingPage(), locale: const Locale('ta')));
    expect(find.text('படி 1 / 4'), findsOneWidget);
    expect(find.text('பயனர்பெயரைத் தேர்வுசெய்க'), findsOneWidget);
  });
}
