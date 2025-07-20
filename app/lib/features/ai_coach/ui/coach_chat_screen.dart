import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/momentum_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/responsive_service.dart';
import '../../../core/services/ai_coaching_service.dart';
import '../../momentum/presentation/providers/momentum_api_provider.dart';
import '../../achievements/streak_badge.dart';
import '../../ai_coach/providers/coach_stream_provider.dart';
import 'chat_history_drawer.dart';
import 'widgets/message_list.dart';
import 'widgets/suggestion_bar.dart';
import 'widgets/chat_input_bar.dart';
import '../providers/conversation_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Main coach chat screen with message history and input
class CoachChatScreen extends ConsumerStatefulWidget {
  /// Optional context from Today Feed – if provided the AI coach will receive
  /// the related article ID and summary so it can tailor the first response.
  final String? articleId;
  final String? articleSummary;
  final String? articleTitle;

  /// Whether to show an explicit back arrow instead of the hamburger menu.
  /// Used for contexts where the coach screen is launched *on top of* an
  /// existing view (e.g.
  /// long-press from Today Feed). For the bottom-nav tab we keep the menu.
  final bool showBackButton;

  const CoachChatScreen({
    super.key,
    this.articleId,
    this.articleSummary,
    this.articleTitle,
    this.showBackButton = false,
  });

  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends ConsumerState<CoachChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isTyping = false;
  bool _isRateLimited = false;
  int _messageCount = 0;
  DateTime? _rateLimitResetTime;
  ProviderSubscription<String?>? _convSub;

  @override
  void initState() {
    super.initState();
    final initialConvoId = ref.read(currentConversationIdProvider);
    if (initialConvoId != null) {
      _loadConversationMessages(initialConvoId);
    } else {
      _initializeChat();
    }
    // Register manual listener (allowed outside build)
    _convSub = ref.listenManual<String?>(currentConversationIdProvider, (
      prev,
      next,
    ) {
      if (prev != next && mounted) {
        if (next != null) {
          _loadConversationMessages(next);
        } else {
          setState(() {
            _messages.clear();
            _initializeChat();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _convSub?.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    const firstName = 'Sarah';

    // If user arrived with article context, acknowledge it explicitly to
    // improve clarity of the feature (tester feedback GC-1 UX).
    if (widget.articleTitle != null) {
      _messages.add(
        ChatMessage(
          text:
              "I see you've opened the article \"${widget.articleTitle}\". What questions can I answer for you?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    // Default greetings (no article context)
    final greetings = [
      'Hi $firstName! How can I help you today?',
      'Hello $firstName, what\'s on your mind?',
      'Hey $firstName! Need any support right now?',
      'Hi $firstName, how is it going today?',
      'Hello $firstName – how can I assist you?',
      'Hi there $firstName! What would you like to talk about?',
      'Good to see you $firstName. How can I help?',
      'Hey $firstName, what\'s up?',
      'Greetings $firstName! How may I support you?',
      'Hi $firstName – ready when you are!',
    ]..shuffle();

    _messages.add(
      ChatMessage(
        text: greetings.first,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _loadConversationMessages(String convoId) async {
    setState(() => _messages.clear());
    try {
      final msgs = await ref.read(conversationMessagesProvider(convoId).future);
      if (!mounted) return;
      setState(() {
        if (msgs.isEmpty) {
          // No stored messages for this conversation – add default greeting so
          // the chat never feels empty (tester feedback).
          _initializeChat();
        } else {
          _messages.addAll(
            msgs.map(
              (m) => ChatMessage(
                text: m.content,
                isUser: m.isFromUser,
                timestamp: m.timestamp,
              ),
            ),
          );
        }
      });
      _scrollToBottom();
    } catch (_) {
      // graceful fail – keep empty
      if (!mounted) return;
      _initializeChat();
    }
  }

  void _checkRateLimit() {
    final now = DateTime.now();

    // Reset counter every minute
    if (_rateLimitResetTime == null || now.isAfter(_rateLimitResetTime!)) {
      _messageCount = 0;
      _rateLimitResetTime = now.add(const Duration(minutes: 1));
      _isRateLimited = false;
    }

    // Soft cap – practically unreachable under normal use.
    if (_messageCount >= 30) {
      _isRateLimited = true;
      _showRateLimitSnackBar();
    }
  }

  void _showRateLimitSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Please wait a moment before sending another message',
        ),
        backgroundColor: AppTheme.getMomentumColor(MomentumState.needsCare),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isRateLimited) return;

    // Check both local and AI service rate limits
    _checkRateLimit();
    if (_isRateLimited) return;

    final canSend = await AICoachingService.instance.canSendMessage();
    if (!canSend) {
      _showRateLimitSnackBar();
      return;
    }

    // Conversation handling -------------------------------------------------
    SupabaseClient? client;
    try {
      client = ref.read(supabaseClientProvider);
    } catch (_) {
      // Likely test environment where Supabase.initialize() has not run
      client = null;
    }

    String? conversationId;
    if (client != null) {
      conversationId = ref.read(currentConversationIdProvider);

      try {
        // If no active conversation row yet, create one (blank title)
        if (conversationId == null) {
          final insertRes =
              await client
                  .from('coach_conversations')
                  .insert({
                    'title': widget.articleTitle ?? '',
                    'user_id': client.auth.currentUser?.id,
                  })
                  .select('id')
                  .single();
          conversationId = insertRes['id'] as String?;
          ref.read(currentConversationIdProvider.notifier).state =
              conversationId;
          ref.invalidate(conversationListProvider);
        }

        // If this is the very first user message in the thread, generate title
        final existingUserMsgs = _messages.where((m) => m.isUser).length;
        final shouldAutoTitle =
            widget.articleTitle == null || widget.articleTitle!.isEmpty;
        if (conversationId != null &&
            existingUserMsgs == 0 &&
            shouldAutoTitle) {
          await client
              .from('coach_conversations')
              .update({'title': _makeTitleSnippet(text)})
              .eq('id', conversationId);
          ref.invalidate(conversationListProvider);
        }
      } catch (_) {
        // Ignore Supabase errors in offline/test modes
      }
    }

    // Add user message
    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _messageCount++;
      _isTyping = true;
    });

    final userMessageText = text; // Store message for AI call
    _textController.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();

    // Generate real AI coach response
    _generateCoachResponse(userMessageText, conversationId: conversationId);
  }

  void _generateCoachResponse(
    String userMessage, {
    String? conversationId,
  }) async {
    try {
      // Resolve current momentum state from the shared Momentum provider.
      final momentumEnum = ref
          .read(realtimeMomentumProvider)
          .maybeWhen(data: (d) => d.state, orElse: () => MomentumState.steady);

      // Capitalise the first letter to match the API’s expected format.
      final momentumState =
          momentumEnum.name[0].toUpperCase() + momentumEnum.name.substring(1);

      // Build contextual payload for the AI coaching engine. We include the
      // conversation_id for threading plus optional Today-Feed article context
      // when available.
      final Map<String, dynamic> ctx = {};
      if (conversationId != null) ctx['conversation_id'] = conversationId;
      if (widget.articleId != null) ctx['article_id'] = widget.articleId;
      if (widget.articleSummary != null) {
        ctx['article_summary'] = widget.articleSummary;
      }

      final response = await AICoachingService.instance.generateResponse(
        message: userMessage,
        momentumState: momentumState,
        context: ctx.isEmpty ? null : ctx,
      );

      if (!mounted) return;

      String? logId = response.logId;

      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: response.message,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();

      // Prompt user for rating once the response is shown
      if (logId != null && context.mounted) {
        final rating = await _showRatingSheet();
        if (rating != null) {
          await _submitRating(logId, rating);
        }
      }
    } catch (error, stackTrace) {
      _handleGlobalError(error, stackTrace);
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text:
                  "I'm having trouble connecting right now. Please try again in a moment.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    void doScroll() {
      if (!_scrollController.hasClients) return;

      final max = _scrollController.position.maxScrollExtent;
      final offset = _scrollController.offset;
      const threshold = 8.0;
      if ((max - offset).abs() < threshold) return;

      // If the keyboard is still visible, jumping avoids the overscroll
      // rubber-band that happens when the view inset shrinks mid-animation.
      final viewInset = MediaQuery.of(context).viewInsets.bottom;
      if (viewInset > 0) {
        _scrollController.jumpTo(max);
      } else {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }

    // Wait two frames: one for list updates, another for keyboard/inset
    // changes, then scroll.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((__) => doScroll());
    });
  }

  void _onCoachingCardTap(String suggestion) {
    _textController.text = suggestion;
    _sendMessage();
  }

  void _handleGlobalError(Object error, StackTrace stackTrace) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Something went wrong. Please try again.'),
          backgroundColor: AppTheme.getMomentumColor(MomentumState.needsCare),
        ),
      );
    }
  }

  Future<int?> _showRatingSheet() {
    final spacing = ResponsiveService.getResponsiveSpacing(context);
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(spacing * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How helpful was this response?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: spacing * 1.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    icon: const Icon(Icons.star_border),
                    onPressed: () {
                      Navigator.of(ctx).pop(star);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRating(String logId, int rating) async {
    try {
      SupabaseClient? client;
      try {
        client = ref.read(supabaseClientProvider);
      } catch (_) {
        client = null;
      }
      if (client == null) return;

      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client
          .from('coaching_effectiveness')
          .update({'user_rating': rating})
          .eq('conversation_log_id', logId)
          .eq('user_id', userId);
    } catch (_) {
      // Silently ignore for now – can log to Sentry in production
    }
  }

  String _makeTitleSnippet(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 40) return trimmed;
    // Cut at word boundary roughly at 40 chars
    final snippet = trimmed.substring(0, 40);
    final lastSpace = snippet.lastIndexOf(' ');
    return '${lastSpace > 20 ? snippet.substring(0, lastSpace) : snippet}…';
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time coach stream events (must be inside build)
    ref.listen<AsyncValue<CoachStreamEvent>>(coachStreamProvider, (prev, next) {
      next.whenData((event) {
        if (event.type == 'typing') {
          final isTyping = event.data['typing'] == true;
          if (mounted && _isTyping != isTyping) {
            setState(() => _isTyping = isTyping);
            if (!isTyping) _scrollToBottom();
          }
        }
        // Future: handle momentum_update events here
      });
    });

    final spacing = ResponsiveService.getMediumSpacing(context);

    return MomentumScaffold(
      title: 'Coach',
      drawer: const ChatHistoryDrawer(),
      leading:
          widget.showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              )
              : Builder(
                builder:
                    (drawerCtx) => IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: 'Open chat history',
                      onPressed: () {
                        FocusScope.of(drawerCtx).unfocus();
                        Scaffold.of(drawerCtx).openDrawer();
                      },
                    ),
              ),
      actions: [
        AutoStreakBadge(onTap: () => StreakInfoDialog.show(context)),
        SizedBox(width: ResponsiveService.getSmallSpacing(context)),
      ],
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: MessageList(
                messages: _messages,
                isTyping: _isTyping,
                scrollController: _scrollController,
              ),
            ),

            // Suggestion chips row (always visible like ChatGPT)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing,
                vertical: ResponsiveService.getSmallSpacing(context),
              ),
              child: SuggestionBar(onSuggestionTap: _onCoachingCardTap),
            ),

            // Input section
            ChatInputBar(
              controller: _textController,
              onSend: _sendMessage,
              isRateLimited: _isRateLimited,
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
