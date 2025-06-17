import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/ai_coach/ui/typing_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TypingIndicator', () {
    testWidgets('renders three bouncing dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TypingIndicator())),
      );

      // Resolve initial frame
      await tester.pump();

      // There should be exactly 3 circle containers
      final circleFinder = find.descendant(
        of: find.byType(TypingIndicator),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );

      expect(circleFinder, findsNWidgets(3));
    });
  });
}
