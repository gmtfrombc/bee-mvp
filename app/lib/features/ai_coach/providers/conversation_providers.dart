import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/coach_conversation.dart';
import '../../../core/services/ai_coaching_service.dart';

/// Fetch paginated list of conversations for the current user.
final conversationListProvider = FutureProvider.autoDispose<
  List<CoachConversation>
>((ref) async {
  try {
    final client = await ref.watch(supabaseProvider.future);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('coach_conversations')
        .select('*')
        .eq('user_id', userId)
        .eq('archived', false)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List<dynamic>)
        .map((json) => CoachConversation.fromJson(json as Map<String, dynamic>))
        .toList()
        .where((c) => c.title.trim().isNotEmpty)
        .toList();
  } catch (e, _) {
    // In tests or when Supabase is not configured we silently return an empty
    // list so that the UI can render its graceful empty-state instead of
    // crashing the widget tree.
    return [];
  }
});

/// Holds the currently active conversation ID (null = new chat).
final currentConversationIdProvider = StateProvider<String?>((_) => null);

/// Fetch messages for a given conversation id (ordered asc, capped to 100)
final conversationMessagesProvider = FutureProvider.family
    .autoDispose<List<ConversationMessage>, String>((ref, convoId) async {
      try {
        final client = await ref.watch(supabaseProvider.future);

        final response = await client
            .from('conversation_logs')
            .select('*')
            .eq('conversation_id', convoId)
            .order('timestamp', ascending: true)
            .limit(100);

        return (response as List<dynamic>)
            .map(
              (json) =>
                  ConversationMessage.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } catch (_) {
        return [];
      }
    });
