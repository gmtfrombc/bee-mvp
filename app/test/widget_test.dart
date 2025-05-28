// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('BEE app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: BEEApp()));

    // Verify that the app loads without crashing
    expect(find.text('Welcome back, Sarah!'), findsOneWidget);

    // Wait for the momentum data to load
    await tester.pump(const Duration(seconds: 2));

    // Verify momentum content appears
    expect(find.text('YOUR MOMENTUM'), findsOneWidget);

    // Wait for all animations to complete
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
