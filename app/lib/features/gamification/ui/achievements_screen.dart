import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/responsive_service.dart';
import '../providers/gamification_providers.dart';
import '../models/badge.dart';
import '../services/share_helper.dart';
import 'progress_dashboard.dart';
import 'challenge_card.dart';

/// Achievements screen showing earned and unearned badges
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final earnedCountAsync = ref.watch(earnedBadgesCountProvider);
    final streakAsync = ref.watch(currentStreakProvider);
    final challengesAsync = ref.watch(challengeProvider);

    return Scaffold(
      backgroundColor: AppTheme.getSurfaceSecondary(context),
      appBar: AppBar(
        title: const Text('Achievements & Challenges'),
        backgroundColor: AppTheme.getSurfacePrimary(context),
        foregroundColor: AppTheme.getTextPrimary(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProgressDashboard(),
                ),
              );
            },
            tooltip: 'View Progress Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProgress(context, ref),
            tooltip: 'Share Progress',
          ),
        ],
      ),
      body: SafeArea(
        child: achievementsAsync.when(
          loading: () => const _LoadingState(),
          error: (error, stack) => _ErrorState(error: error.toString()),
          data: (badges) {
            if (badges.isEmpty) {
              return const _EmptyState();
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header with stats
                  _buildHeader(context, earnedCountAsync, streakAsync, badges),

                  // Challenges section
                  _buildChallengesSection(context, challengesAsync),

                  // Badges section
                  _buildBadgesSection(context, badges),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<int> earnedCountAsync,
    AsyncValue<int> streakAsync,
    List<Badge> badges,
  ) {
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
                data: (streak) => _buildStreakChip(context, streak),
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
                  '$earnedCount of ${badges.length} badges earned',
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

  Widget _buildStreakChip(BuildContext context, int streak) {
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

  Widget _buildChallengesSection(
    BuildContext context,
    AsyncValue<List<Challenge>> challengesAsync,
  ) {
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
                    onAccept:
                        () => _handleChallengeAccept(context, challenge.id),
                    onDecline:
                        () => _handleChallengeDecline(context, challenge.id),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgesSection(BuildContext context, List<Badge> badges) {
    final spacing = ResponsiveService.getMediumSpacing(context);

    return Container(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppTheme.getMomentumColor(MomentumState.rising),
                size: 20,
              ),
              SizedBox(width: spacing * 0.5),
              Text(
                'Your Badges',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ],
          ),

          SizedBox(height: spacing),

          // Badges grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _BadgeCard(
                badge: badge,
                onTap: () => _showBadgeDetail(context, badge),
              );
            },
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final deviceType = ResponsiveService.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 2;
      case DeviceType.mobile:
        return 2;
      case DeviceType.mobileLarge:
        return 3;
      case DeviceType.tablet:
        return 4;
      case DeviceType.desktop:
        return 5;
    }
  }

  void _showBadgeDetail(BuildContext context, Badge badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BadgeDetailSheet(badge: badge),
    );
  }

  Future<void> _shareProgress(BuildContext context, WidgetRef ref) async {
    try {
      final earnedCount = await ref.read(earnedBadgesCountProvider.future);
      final totalPoints = await ref.read(totalPointsProvider.future);
      final streak = await ref.read(currentStreakProvider.future);

      await ShareHelper.shareProgress(
        totalPoints: totalPoints,
        streakDays: streak,
        badgesEarned: earnedCount,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error sharing progress')));
      }
    }
  }

  void _handleChallengeAccept(BuildContext context, String challengeId) {
    // Challenge accept logic would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Challenge accepted!'),
        backgroundColor: AppTheme.getMomentumColor(MomentumState.rising),
      ),
    );
  }

  void _handleChallengeDecline(BuildContext context, String challengeId) {
    // Challenge decline logic would be implemented here
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Challenge declined')));
  }
}

/// Badge card widget
class _BadgeCard extends StatelessWidget {
  final Badge badge;
  final VoidCallback onTap;

  const _BadgeCard({required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getSmallSpacing(context);
    final isEarned = badge.isEarned;

    return Semantics(
      label: '${badge.title} badge',
      hint:
          isEarned
              ? 'Earned on ${badge.earnedAt?.day}/${badge.earnedAt?.month}'
              : 'Not yet earned, ${(badge.progressPercentage * 100).round()}% progress',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveService.getBorderRadius(context),
          ),
          child: Card(
            elevation: isEarned ? 3 : 1,
            color: AppTheme.getSurfacePrimary(context),
            child: Padding(
              padding: EdgeInsets.all(spacing),
              child: Column(
                children: [
                  // Badge icon
                  Expanded(flex: 3, child: _buildBadgeIcon(context)),

                  SizedBox(height: spacing * 0.5),

                  // Badge title
                  Text(
                    badge.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isEarned
                              ? AppTheme.getTextPrimary(context)
                              : AppTheme.getTextSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: spacing * 0.25),

                  // Progress or earned indicator
                  if (isEarned)
                    Icon(
                      Icons.check_circle,
                      size:
                          16 * ResponsiveService.getFontSizeMultiplier(context),
                      color: AppTheme.getMomentumColor(MomentumState.rising),
                    )
                  else
                    _buildProgressIndicator(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(BuildContext context) {
    final isEarned = badge.isEarned;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isEarned
                ? AppTheme.getMomentumColor(
                  MomentumState.rising,
                ).withValues(alpha: 0.1)
                : AppTheme.getTextTertiary(context).withValues(alpha: 0.1),
      ),
      child: Center(child: _getBadgeEmoji(badge.category, isEarned, context)),
    );
  }

  Widget _getBadgeEmoji(
    BadgeCategory category,
    bool isEarned,
    BuildContext context,
  ) {
    final fontSize = 32.0 * ResponsiveService.getFontSizeMultiplier(context);
    final emoji = switch (category) {
      BadgeCategory.streak => '🔥',
      BadgeCategory.momentum => '⚡',
      BadgeCategory.engagement => '💬',
      BadgeCategory.milestone => '🎯',
      BadgeCategory.special => '⭐',
    };

    return Text(
      emoji,
      style: TextStyle(
        fontSize: fontSize,
        color: isEarned ? null : Colors.grey,
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final progress = badge.progressPercentage;

    return SizedBox(
      width: 40,
      height: 6,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: AppTheme.getTextTertiary(
          context,
        ).withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(
          AppTheme.getMomentumColor(MomentumState.steady),
        ),
      ),
    );
  }
}

/// Badge detail bottom sheet
class _BadgeDetailSheet extends StatelessWidget {
  final Badge badge;

  const _BadgeDetailSheet({required this.badge});

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getMediumSpacing(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfacePrimary(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.getTextTertiary(
                    context,
                  ).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Badge icon (larger)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      badge.isEarned
                          ? AppTheme.getMomentumColor(
                            MomentumState.rising,
                          ).withValues(alpha: 0.1)
                          : AppTheme.getTextTertiary(
                            context,
                          ).withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    _getBadgeEmojiForCategory(badge.category),
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),

              SizedBox(height: spacing),

              // Badge title
              Text(
                badge.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: spacing * 0.5),

              // Badge description
              Text(
                badge.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: spacing),

              // Progress or earned info
              if (badge.isEarned) ...[
                Container(
                  padding: EdgeInsets.all(spacing * 0.75),
                  decoration: BoxDecoration(
                    color: AppTheme.getMomentumColor(
                      MomentumState.rising,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.getMomentumColor(MomentumState.rising),
                        size: 20,
                      ),
                      SizedBox(width: spacing * 0.5),
                      Text(
                        'Earned on ${badge.earnedAt?.day}/${badge.earnedAt?.month}/${badge.earnedAt?.year}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getMomentumColor(
                            MomentumState.rising,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing),

                // Share button
                ElevatedButton.icon(
                  onPressed: () {
                    ShareHelper.shareAchievement(
                      badge.imagePath,
                      'I earned the "${badge.title}" badge! 🎉',
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Achievement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.getMomentumColor(
                      MomentumState.rising,
                    ),
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                // Progress info
                Column(
                  children: [
                    Text(
                      'Progress: ${badge.currentProgress ?? 0} / ${badge.requiredPoints}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),

                    SizedBox(height: spacing * 0.5),

                    LinearProgressIndicator(
                      value: badge.progressPercentage,
                      backgroundColor: AppTheme.getTextTertiary(
                        context,
                      ).withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.getMomentumColor(MomentumState.steady),
                      ),
                    ),

                    SizedBox(height: spacing * 0.25),

                    Text(
                      '${(badge.progressPercentage * 100).round()}% complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getBadgeEmojiForCategory(BadgeCategory category) {
    return switch (category) {
      BadgeCategory.streak => '🔥',
      BadgeCategory.momentum => '⚡',
      BadgeCategory.engagement => '💬',
      BadgeCategory.milestone => '🎯',
      BadgeCategory.special => '⭐',
    };
  }
}

/// Loading state widget
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Error state widget
class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading achievements',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Empty state widget with onboarding
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getLargeSpacing(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Achievement icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.getMomentumColor(
                  MomentumState.steady,
                ).withValues(alpha: 0.1),
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 60)),
              ),
            ),

            SizedBox(height: spacing),

            // Title
            Text(
              'Start Your Journey!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: spacing * 0.5),

            // Description
            Text(
              'Complete activities and build momentum to earn your first badges. Chat with your AI coach, read Today Feed articles, and maintain your streak!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: spacing),

            // CTA button
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.psychology),
              label: const Text('Chat with Coach'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getMomentumColor(
                  MomentumState.rising,
                ),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
