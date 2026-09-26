import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/core/models/user_profile.dart';
import 'package:myharur/core/services/auth_service.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/features/admin/locked_logins_page.dart';
import 'package:myharur/features/security/force_password_page.dart';

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

void main() {
  test('the profile carries the "must change password" flag from the database row', () {
    final p = UserProfile.fromJson({'id': 'u1', 'must_change_password': true});
    expect(p.mustChangePassword, isTrue);
    expect(UserProfile.fromJson({'id': 'u1'}).mustChangePassword, isFalse);
    expect(p.copyWith(mustChangePassword: false).mustChangePassword, isFalse);
  });

  testWidgets('after a recovery the person must pick a strong password that matches', (tester) async {
    AuthService.debugSetProfile(const UserProfile(id: 'u1', mmid: '1', username: '@hema', fullName: 'Hema', email: 'h@example.com'));
    await tester.pumpWidget(_app(const ForcePasswordPage()));
    expect(find.text('Choose a new password'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'short');
    await tester.enterText(fields.at(1), 'short');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Use at least 10 characters with letters and numbers.'), findsOneWidget);

    await tester.enterText(fields.at(0), 'Correct1Horse9');
    await tester.enterText(fields.at(1), 'Different1Horse9');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text("The passwords don't match."), findsOneWidget);
  });

  testWidgets('the locked sign-ins screen has an empty state and needs no backend to render', (tester) async {
    await tester.pumpWidget(_app(const LockedLoginsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Locked sign-ins'), findsWidgets);
    expect(find.text('No locked accounts.'), findsOneWidget);
  });
}
