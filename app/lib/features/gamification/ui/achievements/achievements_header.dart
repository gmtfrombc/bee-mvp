import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';

/// Header section for the Achievements screen containing the title, earned
/// badge count and the current streak chip.
class AchievementsHeader extends StatelessWidget {
  const AchievementsHeader({
    super.key,
    required this.earnedCountAsync,
    required this.streakAsync,
    required this.totalBadges,
  });

  final AsyncValue<int> earnedCountAsync;
  final AsyncValue<int> streakAsync;
  final int totalBadges;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getMediumSpacing(context);

    return Container(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Achievements',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ),
              // Streak chip
              streakAsync.when(
                data: (streak) => _StreakChip(streak: streak),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress summary
          earnedCountAsync.when(
            data:
                (earnedCount) => Text(
                  '$earnedCount of $totalBadges badges earned',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();

    final spacing = ResponsiveService.getTinySpacing(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing * 2, vertical: spacing),
      decoration: BoxDecoration(
        color: AppTheme.getMomentumColor(
          MomentumState.rising,
        ).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getMomentumColor(
            MomentumState.rising,
          ).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 16 * ResponsiveService.getFontSizeMultiplier(context),
            color: AppTheme.getMomentumColor(MomentumState.rising),
          ),
          SizedBox(width: spacing * 0.5),
          Text(
            '$streak',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.getMomentumColor(MomentumState.rising),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
