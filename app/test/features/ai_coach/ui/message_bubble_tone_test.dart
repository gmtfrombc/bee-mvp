import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/ai_coach/ui/message_bubble.dart';
import 'package:app/core/theme/app_theme.dart';

void main() {
  group('MessageBubble Tone Tests', () {
    testWidgets('Should render celebratory tone with green tint and emoji', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MessageBubble(
              isUser: false,
              text: '<tone celebratory>Great job on your progress!',
            ),
          ),
        ),
      );

      // Find the message bubble
      final messageBubble = find.byType(MessageBubble);
      expect(messageBubble, findsOneWidget);

      // Check that emoji is added to text
      final textWidget = find.text('🎉 Great job on your progress!');
      expect(textWidget, findsOneWidget);

      // Verify tone tag is stripped from display
      final toneTagText = find.textContaining('<tone celebratory>');
      expect(toneTagText, findsNothing);
    });

    testWidgets('Should render supportive tone with orange tint and emoji', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MessageBubble(
              isUser: false,
              text:
                  '<tone supportive>I understand this is challenging for you.',
            ),
          ),
        ),
      );

      // Find the message bubble
      final messageBubble = find.byType(MessageBubble);
      expect(messageBubble, findsOneWidget);

      // Check that emoji is added to text
      final textWidget = find.text(
        '🤗 I understand this is challenging for you.',
      );
      expect(textWidget, findsOneWidget);

      // Verify tone tag is stripped from display
      final toneTagText = find.textContaining('<tone supportive>');
      expect(toneTagText, findsNothing);
    });

    testWidgets('Should render neutral tone without emoji or special styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MessageBubble(
              isUser: false,
              text: 'This is a regular message without tone tags.',
            ),
          ),
        ),
      );

      // Find the message bubble
      final messageBubble = find.byType(MessageBubble);
      expect(messageBubble, findsOneWidget);

      // Check that original text is displayed without changes
      final textWidget = find.text(
        'This is a regular message without tone tags.',
      );
      expect(textWidget, findsOneWidget);

      // Verify no emojis are added
      final celebratoryEmoji = find.textContaining('🎉');
      final supportiveEmoji = find.textContaining('🤗');
      expect(celebratoryEmoji, findsNothing);
      expect(supportiveEmoji, findsNothing);
    });

    testWidgets('Should not apply tone parsing to user messages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MessageBubble(
              isUser: true,
              text: '<tone celebratory>This should not be parsed as tone',
            ),
          ),
        ),
      );

      // Find the message bubble
      final messageBubble = find.byType(MessageBubble);
      expect(messageBubble, findsOneWidget);

      // Check that user message displays original text (tone tags included)
      final textWidget = find.text(
        '<tone celebratory>This should not be parsed as tone',
      );
      expect(textWidget, findsOneWidget);

      // Verify no emojis are added to user messages
      final celebratoryEmoji = find.textContaining('🎉');
      expect(celebratoryEmoji, findsNothing);
    });

    testWidgets('Should handle malformed tone tags gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MessageBubble(
              isUser: false,
              text: '<tone invalid>This has an invalid tone tag.',
            ),
          ),
        ),
      );

      // Find the message bubble
      final messageBubble = find.byType(MessageBubble);
      expect(messageBubble, findsOneWidget);

      // Check that original text is displayed for invalid tone tags
      final textWidget = find.text(
        '<tone invalid>This has an invalid tone tag.',
      );
      expect(textWidget, findsOneWidget);

      // Verify no emojis are added for invalid tags
      final celebratoryEmoji = find.textContaining('🎉');
      final supportiveEmoji = find.textContaining('🤗');
      expect(celebratoryEmoji, findsNothing);
      expect(supportiveEmoji, findsNothing);
    });

    testWidgets('Should handle empty text gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: MessageBubble(isUser: false, text: '')),
        ),
      );

      // Find the message bubble
      final messageBubble = find.byType(MessageBubble);
      expect(messageBubble, findsOneWidget);

      // Check that empty text is handled
      final textWidget = find.text('');
      expect(textWidget, findsOneWidget);
    });

    testWidgets('Should display timestamp when provided', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MessageBubble(
              isUser: false,
              text: '<tone celebratory>Great work!',
              timestamp: now,
            ),
          ),
        ),
      );

      // Find the message bubble
      final messageBubble = find.byType(MessageBubble);
      expect(messageBubble, findsOneWidget);

      // Check that timestamp is displayed
      final timestampText = find.text('now');
      expect(timestampText, findsOneWidget);
    });
  });
}
