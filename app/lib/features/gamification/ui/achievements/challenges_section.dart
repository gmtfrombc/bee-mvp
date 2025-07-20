import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../models/badge.dart';
import '../../models/badge.dart'
    show Challenge; // reuse Challenge definition inside badge.dart
import '../challenge_card.dart';

/// Section that displays active challenges with accept/decline callbacks.
class ChallengesSection extends StatelessWidget {
  const ChallengesSection({
    super.key,
    required this.challengesAsync,
    required this.onAccept,
    required this.onDecline,
  });

  final AsyncValue<List<Challenge>> challengesAsync;
  final void Function(String challengeId) onAccept;
  final void Function(String challengeId) onDecline;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getMediumSpacing(context);

    return challengesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (challenges) {
        if (challenges.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.all(spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Icon(
                    Icons.sports_esports,
                    color: AppTheme.getMomentumColor(MomentumState.steady),
                    size: 20,
                  ),
                  SizedBox(width: spacing * 0.5),
                  Text(
                    'Active Challenges',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              // Challenge cards
              ...challenges.map(
                (challenge) => Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: ChallengeCard(
                    challenge: challenge,
                    onAccept: () => onAccept(challenge.id),
                    onDecline: () => onDecline(challenge.id),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
