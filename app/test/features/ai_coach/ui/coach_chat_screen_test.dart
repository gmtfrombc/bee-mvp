import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/ai_coach/ui/coach_chat_screen.dart';
import 'package:app/features/ai_coach/ui/message_bubble.dart';
import 'package:app/features/ai_coach/ui/coaching_card.dart';
import 'package:app/core/theme/app_theme.dart';

void main() {
  group('CoachChatScreen', () {
    testWidgets('renders with correct title and initial welcome message', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoachChatScreen(),
          ),
        ),
      );

      // Verify app bar title
      expect(find.text('Coach'), findsOneWidget);

      // Verify welcome message exists
      expect(find.byType(MessageBubble), findsOneWidget);

      // Verify input field exists
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask your coach...'), findsOneWidget);

      // Verify send button exists
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('shows coaching suggestion cards initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoachChatScreen(),
          ),
        ),
      );

      // Verify suggestion chips rendered
      expect(find.byType(CompactCoachingCard), findsAtLeastNWidgets(2));
      expect(find.text('How am I doing?'), findsOneWidget);
      expect(find.text("What's next?"), findsOneWidget);
    });

    testWidgets('sends message when send button is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoachChatScreen(),
          ),
        ),
      );

      const testMessage = 'How can I build better habits?';

      // Enter text
      await tester.enterText(find.byType(TextField), testMessage);

      // Verify text was entered
      expect(find.text(testMessage), findsOneWidget);

      // Tap send button
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Verify message appears in chat (should find it in a MessageBubble now)
      expect(find.text(testMessage), findsAtLeastNWidgets(1));

      // Verify text field is cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      // Wait for any pending operations and clean up
      await tester.pumpAndSettle();
    });

    testWidgets('shows typing indicator immediately after sending message', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoachChatScreen(),
          ),
        ),
      );

      // Send a message
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send_rounded));

      // Pump once to trigger the setState
      await tester.pump();

      // Add a small duration pump to allow animations to start
      await tester.pump(const Duration(milliseconds: 50));

      // Try scrolling to the bottom manually
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // First check for the text content which should be easier to find
      expect(find.text('Coach is typing...'), findsOneWidget);

      // Then check for the widget type
      expect(find.byType(TypingIndicatorBubble), findsOneWidget);

      // Verify we have the expected messages at this point
      // Should be: welcome message + user message = 2 messages
      expect(find.byType(MessageBubble), findsNWidgets(2));

      // Clean up pending timers (this will complete the AI response)
      await tester.pumpAndSettle();

      // After the response completes, typing indicator should be gone and we should have 3 messages
      expect(find.byType(TypingIndicatorBubble), findsNothing);
      expect(find.byType(MessageBubble), findsNWidgets(3));
    });

    testWidgets('handles coaching card tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoachChatScreen(),
          ),
        ),
      );

      // Tap on a coaching card
      await tester.tap(find.text('How am I doing?'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Verify the suggestion text appears both in the bubble and still on
      // the persistent coaching card.
      expect(find.text('How am I doing?'), findsAtLeastNWidgets(2));

      // Clean up pending timers
      await tester.pumpAndSettle();
    });

    testWidgets('handles multiple messages and rate limiting', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoachChatScreen(),
          ),
        ),
      );

      // Send multiple messages quickly
      for (int i = 0; i < 3; i++) {
        await tester.enterText(find.byType(TextField), 'Message $i');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pump();
      }

      // Verify at least some messages were sent
      expect(find.text('Message 0'), findsAtLeastNWidgets(1));

      // Clean up all pending timers
      await tester.pumpAndSettle();
    });
  });

  group('ChatMessage', () {
    test('creates instance with correct properties', () {
      final timestamp = DateTime.now();
      final message = ChatMessage(
        text: 'Test message',
        isUser: true,
        timestamp: timestamp,
      );

      expect(message.text, equals('Test message'));
      expect(message.isUser, isTrue);
      expect(message.timestamp, equals(timestamp));
    });
  });
}
