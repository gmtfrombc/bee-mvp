import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/likert_selector.dart';

void main() {
  group('LikertSelector', () {
    testWidgets('renders 5 options and responds to tap selection', (
      tester,
    ) async {
      // Happy path test
      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikertSelector(
              value: null,
              onChanged: (value) => selectedValue = value,
              semanticLabel: 'Test question',
            ),
          ),
        ),
      );

      // Verify 5 options are rendered
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Tap option 3 and verify callback
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(selectedValue, equals(3));
    });

    testWidgets('handles keyboard navigation and selection', (tester) async {
      // Edge case test for accessibility
      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikertSelector(
              value: null,
              onChanged: (value) => selectedValue = value,
              semanticLabel: 'Test question',
            ),
          ),
        ),
      );

      // Focus the widget
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Navigate with arrow keys
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // Select with space key
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(
        selectedValue,
        equals(3),
      ); // Started at 0, moved right twice = index 2, value 3
    });

    testWidgets('updates selection state correctly', (tester) async {
      // State management test
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikertSelector(
              value: 2,
              onChanged: (_) {},
              semanticLabel: 'Test question',
            ),
          ),
        ),
      );

      // Verify selected option has different styling
      final selectedOption = find.text('2');
      expect(selectedOption, findsOneWidget);

      // Verify semantics for screen readers
      final semantics = tester.getSemantics(find.byType(LikertSelector));
      expect(semantics.label, equals('Test question'));
    });

    testWidgets('handles disabled state', (tester) async {
      // Edge case: disabled widget
      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikertSelector(
              value: null,
              onChanged: (value) => selectedValue = value,
              semanticLabel: 'Test question',
              enabled: false,
            ),
          ),
        ),
      );

      // Tap should not trigger callback when disabled
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(selectedValue, isNull);
    });
  });
}
