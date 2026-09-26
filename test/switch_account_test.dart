import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/core/models/user_profile.dart';
import 'package:myharur/core/services/account_store.dart';
import 'package:myharur/core/services/auth_service.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/features/account/switch_account_sheet.dart';

SavedAccount _a(String id, String name) => SavedAccount(id: id, name: name, username: '@$id', refreshToken: 'rt-$id');

Widget _app() => MaterialApp(
      theme: AppTheme.light,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(builder: (context) => Scaffold(body: Center(child: TextButton(onPressed: () => showSwitchAccountSheet(context), child: const Text('open'))))),
    );

void main() {
  setUp(() {
    AuthService.debugSetProfile(const UserProfile(id: 'u1', mmid: '1', username: '@u1', fullName: 'Hema', email: 'h@example.com'));
  });

  test('saved accounts survive a round trip and reject malformed entries', () {
    final a = _a('u1', 'Hema');
    final back = SavedAccount.tryParse(a.toJson())!;
    expect(back.id, 'u1');
    expect(back.refreshToken, 'rt-u1');
    expect(SavedAccount.tryParse({'id': 'x'}), isNull); // no token
    expect(SavedAccount.tryParse('nope'), isNull);
    expect(a.copyWith(refreshToken: 'new').refreshToken, 'new');
  });

  testWidgets('the sheet lists the people on this phone, marks the current one, and offers "Add another account"', (tester) async {
    AccountStore.debugSet([_a('u1', 'Hema'), _a('u2', 'Ravi')]);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Switch account'), findsOneWidget);
    expect(find.text('Hema'), findsOneWidget);
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text('@u2'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget); // only the current account
    expect(find.text('Add another account'), findsOneWidget);
  });

  testWidgets('at three accounts "Add another account" explains the limit instead of opening sign-in', (tester) async {
    AccountStore.debugSet([_a('u1', 'Hema'), _a('u2', 'Ravi'), _a('u3', 'Meena')]);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add another account'));
    await tester.pumpAndSettle();
    expect(find.text('You can keep up to 3 accounts on this phone. Remove one first.'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('with room left, "Add another account" opens the sign-in page with a close button', (tester) async {
    AccountStore.debugSet([_a('u1', 'Hema')]);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add another account'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsNothing);
  });
}
