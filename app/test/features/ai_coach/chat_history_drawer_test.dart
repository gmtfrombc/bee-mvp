import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/ai_coach/ui/chat_history_drawer.dart';
import 'package:app/features/ai_coach/providers/conversation_providers.dart';
import 'package:app/features/ai_coach/models/coach_conversation.dart';

void main() {
  testWidgets('ChatHistoryDrawer renders list and selects a conversation', (
    tester,
  ) async {
    final convos = [
      CoachConversation(
        id: 'c1',
        title: 'First chat with a long first question',
        createdAt: DateTime.now(),
      ),
      CoachConversation(
        id: 'c2',
        title: 'Second chat',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationListProvider.overrideWith((ref) async => convos),
        ],
        child: const MaterialApp(home: Scaffold(body: ChatHistoryDrawer())),
      ),
    );

    await tester.pump();

    // List tiles render
    expect(find.textContaining('First chat'), findsOneWidget);
    expect(find.text('Second chat'), findsOneWidget);

    // Capture the provider container before we pop the drawer so we still
    // have a valid reference after navigation changes the widget tree.
    final ctx = tester.element(find.byType(ChatHistoryDrawer));
    final container = ProviderScope.containerOf(ctx, listen: false);

    // Tap first tile (this will close the drawer)
    await tester.tap(find.textContaining('First chat'));
    await tester.pumpAndSettle();

    expect(container.read(currentConversationIdProvider), 'c1');
  });
}
