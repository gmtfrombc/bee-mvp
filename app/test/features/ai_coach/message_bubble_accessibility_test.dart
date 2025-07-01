import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/ai_coach/ui/message_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessageBubble Accessibility', () {
    testWidgets('provides correct semantic label for user message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MessageBubble(isUser: true, text: 'Hello Coach'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Your message: Hello Coach'),
        findsOneWidget,
      );
    });

    testWidgets(
      'provides correct semantic label for celebratory assistant message',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: MessageBubble(
                isUser: false,
                text: '<tone celebratory>Great job on your workout!',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(
            'Celebratory message: celebration Great job on your workout!',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
