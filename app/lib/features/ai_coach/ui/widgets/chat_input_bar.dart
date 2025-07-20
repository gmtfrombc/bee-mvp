import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Chat input bar with text field and send button.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isRateLimited,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isRateLimited;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getMediumSpacing(context);
    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: AppTheme.getSurfacePrimary(context),
        border: Border(
          top: BorderSide(
            color: AppTheme.getTextTertiary(context).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Message input field',
                textField: true,
                child: TextField(
                  controller: controller,
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
                        color: AppTheme.getMomentumColor(MomentumState.steady),
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: spacing,
                      vertical: ResponsiveService.getSmallSpacing(context),
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            IconButton(
              tooltip: 'Send message',
              onPressed: isRateLimited ? null : onSend,
              icon: Icon(
                Icons.send_rounded,
                color:
                    isRateLimited
                        ? AppTheme.getTextTertiary(context)
                        : AppTheme.getMomentumColor(MomentumState.rising),
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    isRateLimited
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
    );
  }
}
