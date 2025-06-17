import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/ai_coach/ui/chat_history_widget.dart';
import 'package:app/core/services/ai_coaching_service.dart';
import 'package:app/features/ai_coach/ui/message_bubble.dart';

void main() {
  group('ChatHistoryWidget', () {
    testWidgets('renders provided conversation history', (tester) async {
      final now = DateTime.now();
      final mockMessages = [
        ConversationMessage(
          userId: 'u1',
          role: 'user',
          content: 'Hi coach!',
          persona: null,
          timestamp: now.subtract(const Duration(minutes: 1)),
        ),
        ConversationMessage(
          userId: 'u1',
          role: 'assistant',
          content: 'Hello! How can I help?',
          persona: 'supportive',
          timestamp: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatHistoryProvider.overrideWith((ref) async => mockMessages),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: ChatHistoryWidget()),
          ),
        ),
      );

      // Resolve any futures / animations
      await tester.pumpAndSettle();

      // Expect both messages to be visible
      expect(find.text('Hi coach!'), findsOneWidget);
      expect(find.text('Hello! How can I help?'), findsOneWidget);

      // Verify correct number of message bubbles rendered
      expect(find.byType(MessageBubble), findsNWidgets(2));
    });
  });
}
