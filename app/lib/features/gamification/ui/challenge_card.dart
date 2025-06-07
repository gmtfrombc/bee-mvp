import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/responsive_service.dart';
import '../models/badge.dart';
import '../providers/gamification_providers.dart';

/// Challenge card widget with accept/decline actions and progress display
class ChallengeCard extends ConsumerWidget {
  final Challenge challenge;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ResponsiveService.getMediumSpacing(context);

    return Card(
      elevation: 2,
      color: AppTheme.getSurfacePrimary(context),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with challenge type and time remaining
            _buildHeader(context),

            SizedBox(height: spacing * 0.75),

            // Challenge title and description
            _buildContent(context),

            SizedBox(height: spacing),

            // Progress ring and stats
            _buildProgress(context),

            SizedBox(height: spacing),

            // Action buttons
            _buildActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Challenge type icon
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getTypeColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(_getTypeIcon(), size: 16, color: _getTypeColor()),
        ),

        const SizedBox(width: 8),

        // Challenge type label
        Text(
          challenge.type.displayName,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: _getTypeColor(),
            fontWeight: FontWeight.w600,
          ),
        ),

        const Spacer(),

        // Time remaining
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                challenge.isExpired
                    ? Colors.red.withValues(alpha: 0.1)
                    : AppTheme.getTextTertiary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            challenge.timeRemaining,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:
                  challenge.isExpired
                      ? Colors.red
                      : AppTheme.getTextSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          challenge.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimary(context),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          challenge.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(BuildContext context) {
    final progress = challenge.progressPercentage;

    return Row(
      children: [
        // Progress ring
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              // Background circle
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 6,
                backgroundColor: AppTheme.getTextTertiary(
                  context,
                ).withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.getTextTertiary(context).withValues(alpha: 0.1),
                ),
              ),

              // Progress circle
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(_getTypeColor()),
              ),

              // Progress text
              Center(
                child: Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Progress stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress: ${challenge.currentProgress} / ${challenge.targetValue}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Reward: ${challenge.rewardPoints} points',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getMomentumColor(MomentumState.rising),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    if (challenge.isCompleted) {
      return _buildCompletedState(context);
    }

    if (challenge.isExpired) {
      return _buildExpiredState(context);
    }

    if (challenge.isAccepted) {
      return _buildAcceptedState(context);
    }

    return _buildPendingState(context, ref);
  }

  Widget _buildCompletedState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getMomentumColor(
          MomentumState.rising,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.getMomentumColor(MomentumState.rising),
            size: 20,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              'Challenge Completed! 🎉',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getMomentumColor(MomentumState.rising),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.red, size: 20),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              'Challenge Expired',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedState(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.getMomentumColor(
              MomentumState.steady,
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.getMomentumColor(MomentumState.steady),
                size: 20,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Challenge Active - Keep Going!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.getMomentumColor(MomentumState.steady),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // CTA to coach chat
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToCoach(context),
            icon: const Icon(Icons.psychology),
            label: const Text('Chat with Coach'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.getMomentumColor(MomentumState.rising),
              side: BorderSide(
                color: AppTheme.getMomentumColor(MomentumState.rising),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingState(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Decline button
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleDecline(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.getTextSecondary(context),
              side: BorderSide(color: AppTheme.getTextTertiary(context)),
            ),
            child: const Text('Decline'),
          ),
        ),

        const SizedBox(width: 12),

        // Accept button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => _handleAccept(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getTypeColor(),
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept Challenge'),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor() {
    return switch (challenge.type) {
      ChallengeType.dailyStreak => AppTheme.getMomentumColor(
        MomentumState.rising,
      ),
      ChallengeType.coachChats => AppTheme.getMomentumColor(
        MomentumState.steady,
      ),
      ChallengeType.momentumPoints => AppTheme.getMomentumColor(
        MomentumState.rising,
      ),
      ChallengeType.todayFeed => AppTheme.getMomentumColor(
        MomentumState.steady,
      ),
    };
  }

  IconData _getTypeIcon() {
    return switch (challenge.type) {
      ChallengeType.dailyStreak => Icons.local_fire_department,
      ChallengeType.coachChats => Icons.psychology,
      ChallengeType.momentumPoints => Icons.trending_up,
      ChallengeType.todayFeed => Icons.article,
    };
  }

  void _handleAccept(BuildContext context, WidgetRef ref) {
    final challengeAction = ref.read(challengeActionProvider);
    challengeAction(challenge.id, true);

    onAccept?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Challenge "${challenge.title}" accepted!'),
        backgroundColor: AppTheme.getMomentumColor(MomentumState.rising),
      ),
    );
  }

  void _handleDecline(BuildContext context, WidgetRef ref) {
    final challengeAction = ref.read(challengeActionProvider);
    challengeAction(challenge.id, false);

    onDecline?.call();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Challenge declined')));
  }

  void _navigateToCoach(BuildContext context) {
    // Navigate to coach chat - this would typically use named routes
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening coach chat...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
