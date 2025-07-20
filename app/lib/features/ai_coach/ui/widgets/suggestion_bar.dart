import 'package:flutter/material.dart';
import '../coaching_card.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Horizontal suggestion bar shown above the input field.
class SuggestionBar extends StatelessWidget {
  const SuggestionBar({super.key, required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getSmallSpacing(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CompactCoachingCard(
            title: 'How am I doing?',
            emoji: '📊',
            onTap: () => onSuggestionTap('How am I doing?'),
            momentumState: MomentumState.steady,
          ),
          SizedBox(width: spacing),
          CompactCoachingCard(
            title: "What's next?",
            emoji: '➡️',
            onTap: () => onSuggestionTap("What's next?"),
            momentumState: MomentumState.rising,
          ),
        ],
      ),
    );
  }
}
