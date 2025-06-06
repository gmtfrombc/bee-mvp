import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/momentum_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/responsive_service.dart';
import '../../achievements/streak_badge.dart';
import 'message_bubble.dart';
import 'coaching_card.dart';

/// Main coach chat screen with message history and input
class CoachChatScreen extends ConsumerStatefulWidget {
  const CoachChatScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    // Add welcome message from coach
    _messages.add(
      ChatMessage(
        text:
            "Hi! I'm your momentum coach. I'm here to help you build sustainable habits and maintain your momentum. How can I support you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _checkRateLimit() {
    final now = DateTime.now();

    // Reset counter every minute
    if (_rateLimitResetTime == null || now.isAfter(_rateLimitResetTime!)) {
      _messageCount = 0;
      _rateLimitResetTime = now.add(const Duration(minutes: 1));
      _isRateLimited = false;
    }

    // Check if user exceeded 5 messages per minute
    if (_messageCount >= 5) {
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

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isRateLimited) return;

    _checkRateLimit();
    if (_isRateLimited) return;

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _messageCount++;
      _isTyping = true;
    });

    _textController.clear();
    _scrollToBottom();

    // Simulate coach response (replace with actual API call)
    _simulateCoachResponse();
  }

  void _simulateCoachResponse() {
    // Simulate API delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      try {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text:
                  "That's a great question! Based on your momentum patterns, I'd suggest focusing on small, consistent actions. Remember, progress isn't always linear - what matters is maintaining forward momentum. What specific area would you like to work on?",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      } catch (error, stackTrace) {
        _handleGlobalError(error, stackTrace);
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onCoachingCardTap(String suggestion) {
    _textController.text = suggestion;
    _sendMessage();
  }

  void _handleGlobalError(Object error, StackTrace stackTrace) {
    debugPrint('❌ Coach Error: $error');
    // Log to Supabase error_logs (placeholder for actual implementation)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: AppTheme.getMomentumColor(MomentumState.needsCare),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getMediumSpacing(context);

    return MomentumScaffold(
      title: 'Coach',
      actions: [
        AutoStreakBadge(onTap: () => StreakInfoDialog.show(context)),
        SizedBox(width: ResponsiveService.getSmallSpacing(context)),
      ],
      body: Column(
        children: [
          // Coaching suggestions section
          if (_messages.length <= 2) ...[
            Container(
              padding: EdgeInsets.all(spacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick suggestions:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  SizedBox(height: ResponsiveService.getSmallSpacing(context)),
                  Row(
                    children: [
                      Expanded(
                        child: CompactCoachingCard(
                          title: 'Daily habits',
                          emoji: '🌱',
                          onTap:
                              () => _onCoachingCardTap(
                                'Help me build daily habits',
                              ),
                          momentumState: MomentumState.rising,
                        ),
                      ),
                      Expanded(
                        child: CompactCoachingCard(
                          title: 'Motivation',
                          emoji: '🚀',
                          onTap: () => _onCoachingCardTap('I need motivation'),
                          momentumState: MomentumState.steady,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              color: AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
              height: 1,
            ),
          ],

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: spacing),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const TypingIndicatorBubble();
                }

                final message = _messages[index];
                return MessageBubble(
                  isUser: message.isUser,
                  text: message.text,
                  timestamp: message.timestamp,
                );
              },
            ),
          ),

          // Input section
          Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: AppTheme.getSurfacePrimary(context),
              border: Border(
                top: BorderSide(
                  color: AppTheme.getTextTertiary(
                    context,
                  ).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask your coach...',
                        hintStyle: TextStyle(
                          color: AppTheme.getTextTertiary(context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppTheme.getTextTertiary(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppTheme.getTextTertiary(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppTheme.getMomentumColor(
                              MomentumState.steady,
                            ),
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: spacing,
                          vertical: ResponsiveService.getSmallSpacing(context),
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                  IconButton(
                    onPressed: _isRateLimited ? null : _sendMessage,
                    icon: Icon(
                      Icons.send_rounded,
                      color:
                          _isRateLimited
                              ? AppTheme.getTextTertiary(context)
                              : AppTheme.getMomentumColor(MomentumState.rising),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _isRateLimited
                              ? AppTheme.getTextTertiary(
                                context,
                              ).withValues(alpha: 0.1)
                              : AppTheme.getMomentumColor(
                                MomentumState.rising,
                              ).withValues(alpha: 0.1),
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
