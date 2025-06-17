import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_coaching_service.dart';
import '../../../core/services/responsive_service.dart';
import '../../../core/theme/app_theme.dart';
import 'animated_message_bubble.dart';

/// Provider that fetches the last 50 conversation messages for the
/// authenticated user via [AICoachingService]. In test environments the
/// provider can be overridden with static data for fast, deterministic tests.
final chatHistoryProvider = FutureProvider.autoDispose(
  (ref) => AICoachingService.instance.getConversationHistory(limit: 50),
);

/// Stateless widget that renders the user ↔️ coach interaction history using
/// the [chatHistoryProvider]. This component is intentionally kept focused so
/// it can be reused inside other screens (e.g. profile, analytics) and easily
/// unit-tested.
class ChatHistoryWidget extends ConsumerWidget {
  const ChatHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(chatHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (err, _) => Center(
            child: Text(
              'Failed to load history',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          ),
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          );
        }

        final spacing = ResponsiveService.getMediumSpacing(context);

        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: spacing),
          itemCount: messages.length,
          separatorBuilder:
              (_, __) =>
                  SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          itemBuilder: (_, index) {
            final msg = messages[index];
            return AnimatedMessageBubble(
              isUser: msg.isFromUser,
              text: msg.content,
              timestamp: msg.timestamp,
            );
          },
        );
      },
    );
  }
}
