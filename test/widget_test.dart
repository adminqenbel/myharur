import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/main.dart';
import 'package:myharur/features/onboarding_page.dart';

void main() {
  testWidgets('shows the MyHarur home shell and components', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TownShell(),
      ),
    );

    expect(find.text('Harur is happening.'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
  });

  testWidgets('shows the onboarding setup flow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TownOnboardingFlowPage(),
      ),
    );

    expect(find.text('Welcome to Harur'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
