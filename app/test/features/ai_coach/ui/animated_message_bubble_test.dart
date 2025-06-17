import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/ai_coach/ui/animated_message_bubble.dart';

void main() {
  testWidgets('AnimatedMessageBubble renders and animates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedMessageBubble(
            isUser: false,
            text: '<tone celebratory>Great job!',
            timestamp: null,
          ),
        ),
      ),
    );

    // Initial frame (opacity 0), pump first animation frame
    await tester.pump(const Duration(milliseconds: 50));

    // Expect the celebratory emoji to eventually appear
    expect(find.text('🎉 Great job!'), findsOneWidget);

    // Finish animations
    await tester.pumpAndSettle();
  });
}
