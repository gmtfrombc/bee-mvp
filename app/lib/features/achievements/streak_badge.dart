import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/responsive_service.dart';
import 'streak_service.dart';

/// Streak badge widget for displaying chat streak count
/// Shows in AppBar when streak > 0, with special styling for 7+ day streak
class StreakBadge extends ConsumerWidget {
  final int count;
  final VoidCallback? onTap;

  const StreakBadge({super.key, required this.count, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (count <= 0) return const SizedBox.shrink();

    final hasSevenDayBadge = count >= 7;
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);
    final spacing = ResponsiveService.getTinySpacing(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing * 1.5,
            vertical: spacing * 0.75,
          ),
          decoration: BoxDecoration(
            color:
                hasSevenDayBadge
                    ? AppTheme.getMomentumColor(
                      MomentumState.rising,
                    ).withValues(alpha: 0.15)
                    : AppTheme.getMomentumColor(
                      MomentumState.steady,
                    ).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  hasSevenDayBadge
                      ? AppTheme.getMomentumColor(
                        MomentumState.rising,
                      ).withValues(alpha: 0.3)
                      : AppTheme.getMomentumColor(
                        MomentumState.steady,
                      ).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasSevenDayBadge) ...[
                // Use badge asset or fallback to emoji
                _buildBadgeIcon(context, iconSize),
                SizedBox(width: spacing * 0.5),
              ] else ...[
                Icon(
                  Icons.local_fire_department,
                  size: iconSize,
                  color: AppTheme.getMomentumColor(MomentumState.steady),
                ),
                SizedBox(width: spacing * 0.5),
              ],
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:
                      hasSevenDayBadge
                          ? AppTheme.getMomentumColor(MomentumState.rising)
                          : AppTheme.getMomentumColor(MomentumState.steady),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(BuildContext context, double iconSize) {
    // Try to load asset, fallback to emoji
    try {
      return Image.asset(
        'assets/badges/streak_7.png',
        width: iconSize,
        height: iconSize,
        errorBuilder:
            (context, error, stackTrace) =>
                Text('🏆', style: TextStyle(fontSize: iconSize * 0.8)),
      );
    } catch (e) {
      return Text('🏆', style: TextStyle(fontSize: iconSize * 0.8));
    }
  }
}

/// Provider-aware streak badge that auto-updates with current streak
class AutoStreakBadge extends ConsumerWidget {
  final VoidCallback? onTap;

  const AutoStreakBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return streakAsync.when(
      data: (streak) => StreakBadge(count: streak, onTap: onTap),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

/// Detailed streak info widget for streak badge tap
class StreakInfoDialog extends ConsumerWidget {
  const StreakInfoDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final metadataAsync = ref.watch(streakMetadataProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.orange),
          SizedBox(width: 8),
          Text('Chat Streak'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          streakAsync.when(
            data: (streak) => _buildStreakInfo(context, streak, metadataAsync),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error loading streak: $error'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  Widget _buildStreakInfo(
    BuildContext context,
    int streak,
    AsyncValue<StreakMetadata> metadataAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current streak: $streak days',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.getMomentumColor(MomentumState.rising),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (streak >= 7) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.getMomentumColor(
                MomentumState.rising,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seven Day Badge Earned!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.getMomentumColor(MomentumState.rising),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Keep chatting with your AI coach daily to maintain your streak!',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Streak resets if you miss a day.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const StreakInfoDialog(),
    );
  }
}
