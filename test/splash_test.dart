import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/features/splash/splash_gate.dart';

Widget _app(Widget home) => MaterialApp(
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

double _opacityOf(WidgetTester tester, String text) =>
    tester.widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first).opacity;

TextDecoration _decoration(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style?.decoration ?? TextDecoration.none;

void main() {
  const total = Duration(milliseconds: 1000);

  setUp(SplashGate.debugReset);

  testWidgets('page 1 draws the logo then shows MyHarur; page 2 credits QenBel; then the app opens', (tester) async {
    await tester.pumpWidget(_app(const SplashGate(duration: total, child: Scaffold(body: Text('APP HOME')))));

    // first frame: blank white, nothing drawn yet (the native splash is also blank)
    expect(find.text('APP HOME'), findsNothing);
    expect(_opacityOf(tester, 'MyHarur'), 0);
    expect(_opacityOf(tester, 'Developed and managed by'), 0);

    // page 1: the wordmark appears after the line drawing
    await tester.pump(const Duration(milliseconds: 620));
    expect(_opacityOf(tester, 'MyHarur'), greaterThan(0.9));
    expect(_opacityOf(tester, 'Developed and managed by'), 0);

    // page 2: "Developed and managed by" + QenBel
    await tester.pump(const Duration(milliseconds: 260));
    expect(_opacityOf(tester, 'Developed and managed by'), greaterThan(0.9));

    // finished: cross-fade into the app
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('APP HOME'), findsOneWidget);
    expect(find.text('MyHarur'), findsNothing);
  });

  testWidgets('regression: no yellow underline on either page (text needs a Material ancestor)', (tester) async {
    await tester.pumpWidget(_app(const SplashGate(duration: total, child: SizedBox())));
    expect(_decoration(tester, 'MyHarur'), TextDecoration.none);
    expect(_decoration(tester, 'Developed and managed by'), TextDecoration.none);
    await tester.pumpAndSettle();
  });

  testWidgets('tapping the splash skips straight to the app', (tester) async {
    await tester.pumpWidget(_app(const SplashGate(duration: Duration(seconds: 30), child: Scaffold(body: Text('APP HOME')))));
    expect(find.text('APP HOME'), findsNothing);
    await tester.tapAt(const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('APP HOME'), findsOneWidget);
  });

  testWidgets('the splash plays once per launch', (tester) async {
    const gate = SplashGate(duration: Duration(milliseconds: 300), child: Scaffold(body: Text('APP HOME')));
    await tester.pumpWidget(_app(gate));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('APP HOME'), findsOneWidget);

    // a second gate in the same launch (e.g. after a restart) opens immediately
    await tester.pumpWidget(_app(const SizedBox()));
    await tester.pumpWidget(_app(gate));
    await tester.pump();
    expect(find.text('APP HOME'), findsOneWidget);
    expect(find.text('MyHarur'), findsNothing);
  });

  testWidgets('reduced-motion users get a short, static credits page', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(_app(const SplashGate(child: Scaffold(body: Text('APP HOME')))));
    expect(_opacityOf(tester, 'Developed and managed by'), 1); // already at its end state, nothing animates
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(find.text('APP HOME'), findsOneWidget);
  });
}
