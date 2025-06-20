import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/responsive_service.dart';
import '../providers/conversation_providers.dart';
import '../models/coach_conversation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/supabase_provider.dart';

class ChatHistoryDrawer extends ConsumerWidget {
  const ChatHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationListProvider);

    final spacing = ResponsiveService.getMediumSpacing(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(spacing),
              child: Row(
                children: [
                  const Text(
                    'Chats',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'New chat',
                    onPressed: () async {
                      // Hide keyboard if open
                      FocusManager.instance.primaryFocus?.unfocus();
                      // We no longer pre-create a blank conversation row.
                      // A row will be created on the first user message to
                      // avoid cluttering the drawer with untitled chats.
                      String? newConversationId;

                      // Even if the DB insert failed we still reset the
                      // provider so the UI starts a fresh session.
                      ref.read(currentConversationIdProvider.notifier).state =
                          newConversationId;

                      // Refresh drawer list so the new conversation (if any)
                      // shows up immediately.
                      ref.invalidate(conversationListProvider);

                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: conversationsAsync.when(
                data: (list) => _ConversationListView(conversations: list),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, _) => Center(
                      child: Text(
                        'Could not load chats',
                        style: TextStyle(
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationListView extends ConsumerStatefulWidget {
  final List<CoachConversation> conversations;
  const _ConversationListView({required this.conversations});

  @override
  ConsumerState<_ConversationListView> createState() => _ConvListState();
}

class _ConvListState extends ConsumerState<_ConversationListView> {
  late List<CoachConversation> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.conversations);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No past chats',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final convo = _items[index];
        return Dismissible(
          key: ValueKey(convo.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Delete chat?'),
                        content: const Text(
                          'This will hide the chat from your list but will not erase the messages.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                ) ??
                false;
          },
          onDismissed: (_) async {
            setState(() => _items.removeAt(index));
            try {
              // Soft-delete: set archived = true
              final client = ref.read(supabaseClientProvider);
              await client
                  .from('coach_conversations')
                  .update({'archived': true})
                  .eq('id', convo.id);
            } catch (_) {
              // Ignore errors in offline/test scenarios.
            }

            // Refresh list even if the update failed; the UI will remove the
            // tile locally and conversationListProvider will reload (empty)
            // next time it succeeds.
            ref.invalidate(conversationListProvider);
          },
          child: ListTile(
            title: Text(
              convo.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              ref.read(currentConversationIdProvider.notifier).state = convo.id;
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
