import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:confetti/confetti.dart';
import 'package:app/features/action_steps/widgets/confetti_overlay.dart';

void main() {
  group('ConfettiOverlay.show', () {
    testWidgets('renders ConfettiWidget when reducedMotion is false', (
      tester,
    ) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(key: key);
              },
            ),
          ),
        ),
      );

      ConfettiOverlay.show(key.currentContext!, reducedMotion: false);
      await tester.pump(); // Build overlay

      expect(find.byType(ConfettiWidget), findsOneWidget);
    });

    testWidgets('does not render ConfettiWidget when reducedMotion is true', (
      tester,
    ) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(key: key);
                },
              ),
            ),
          ),
        ),
      );

      ConfettiOverlay.show(key.currentContext!, reducedMotion: true);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byType(ConfettiWidget), findsNothing);
    });
  });
}
