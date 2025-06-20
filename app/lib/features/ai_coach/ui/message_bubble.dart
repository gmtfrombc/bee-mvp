import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/responsive_service.dart';

/// Coaching tone types for emotional intelligence
enum CoachingTone { neutral, celebratory, supportive }

/// Message bubble widget for coach chat interface
/// Displays user and coach messages with different styling
class MessageBubble extends StatelessWidget {
  final bool isUser;
  final String text;
  final DateTime? timestamp;

  const MessageBubble({
    super.key,
    required this.isUser,
    required this.text,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    // Parse tone from assistant message
    final (displayText, assistantTone) = _parseAssistantTone(text);

    Color backgroundColor;
    if (isUser) {
      // Use blue to mimic iOS iMessage bubbles while staying in theme
      backgroundColor = AppTheme.getMomentumColor(MomentumState.steady);
    } else {
      // Apply tone-based styling for assistant messages
      switch (assistantTone) {
        case CoachingTone.celebratory:
          backgroundColor = AppTheme.getMomentumColor(
            MomentumState.rising,
          ).withValues(alpha: 0.15);
          break;
        case CoachingTone.supportive:
          backgroundColor = Colors.orange.withValues(alpha: 0.15);
          break;
        case CoachingTone.neutral:
          backgroundColor = AppTheme.getSurfacePrimary(context);
          break;
      }
    }

    final textColor = isUser ? Colors.white : AppTheme.getTextPrimary(context);

    final spacing = ResponsiveService.getMediumSpacing(context);
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveService.getSmallSpacing(context),
        horizontal: spacing,
      ),
      child: Align(
        alignment: alignment,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: spacing,
            vertical: ResponsiveService.getSmallSpacing(context),
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16.0).copyWith(
              bottomRight: isUser ? const Radius.circular(4.0) : null,
              bottomLeft: !isUser ? const Radius.circular(4.0) : null,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: _buildSemanticLabel(displayText, assistantTone),
                child: Text(
                  displayText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
              if (timestamp != null) ...[
                SizedBox(height: ResponsiveService.getTinySpacing(context)),
                Text(
                  _formatTimestamp(timestamp!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        isUser
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppTheme.getTextTertiary(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  /// Parse tone tags from assistant messages and return clean text with tone
  (String, CoachingTone) _parseAssistantTone(String originalText) {
    if (isUser) {
      return (originalText, CoachingTone.neutral);
    }

    // Check for tone tags
    if (originalText.startsWith('<tone celebratory>')) {
      final cleanText =
          originalText.replaceFirst('<tone celebratory>', '').trim();
      return ('🎉 $cleanText', CoachingTone.celebratory);
    } else if (originalText.startsWith('<tone supportive>')) {
      final cleanText =
          originalText.replaceFirst('<tone supportive>', '').trim();
      return ('🤗 $cleanText', CoachingTone.supportive);
    }

    return (originalText, CoachingTone.neutral);
  }

  String _buildSemanticLabel(String text, CoachingTone tone) {
    String prefix = '';
    switch (tone) {
      case CoachingTone.celebratory:
        prefix = 'Celebratory message: ';
        break;
      case CoachingTone.supportive:
        prefix = 'Supportive message: ';
        break;
      case CoachingTone.neutral:
        prefix = isUser ? 'Your message: ' : 'Coach message: ';
        break;
    }

    // Replace emojis with descriptions for accessibility
    String accessibleText = text
        .replaceAll('🎉', 'celebration')
        .replaceAll('🤗', 'supportive hug')
        .replaceAll('🌱', 'growing plant')
        .replaceAll('🚀', 'rocket');

    return '$prefix$accessibleText';
  }
}

/// Typing indicator bubble for when coach is responding
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getMediumSpacing(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveService.getSmallSpacing(context),
        horizontal: spacing,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing,
            vertical: ResponsiveService.getSmallSpacing(context),
          ),
          decoration: BoxDecoration(
            color: AppTheme.getSurfacePrimary(context),
            borderRadius: BorderRadius.circular(
              16.0,
            ).copyWith(bottomLeft: const Radius.circular(4.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Row(
                    children: List.generate(3, (index) {
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveService.getTinySpacing(context) / 2,
                        ),
                        child: Opacity(
                          opacity: _animation.value,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.getTextSecondary(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              Text(
                'Coach is typing...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.getTextSecondary(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
