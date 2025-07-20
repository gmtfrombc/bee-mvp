import 'package:flutter/material.dart';
import '../message_bubble.dart';
import '../../../../core/services/responsive_service.dart';

/// Message list with optional typing indicator extracted from CoachChatScreen.
class MessageList extends StatelessWidget {
  const MessageList({
    super.key,
    required this.messages,
    required this.isTyping,
    required this.scrollController,
  });

  /// Chat messages ordered oldest → newest.
  final List<dynamic> messages; // expecting List<ChatMessage>
  final bool isTyping;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getMediumSpacing(context);
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.symmetric(vertical: spacing),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isTyping) {
          return const TypingIndicatorBubble();
        }
        final message = messages[index];
        return MessageBubble(
          isUser: message.isUser,
          text: message.text,
          timestamp: message.timestamp,
        );
      },
    );
  }
}
