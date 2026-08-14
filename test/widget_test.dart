import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/main.dart';

void main() {
  testWidgets('shows the MyHarur home shell', (tester) async {
    await tester.pumpWidget(const MyHarurApp());

    expect(find.text('Harur is happening.'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
  });
}
