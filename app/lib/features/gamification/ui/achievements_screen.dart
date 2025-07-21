import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/responsive_service.dart';
import '../providers/gamification_providers.dart';
import '../services/share_helper.dart';

// Extracted widgets
import 'achievements/achievements_header.dart';
import 'achievements/challenges_section.dart';
import 'achievements/badges_section.dart';

/// Achievements screen showing earned and unearned badges (refactored).
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
              context.push(kProgressDashboardRoute);
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
            if (badges.isEmpty) return const _EmptyState();

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header with stats
                  AchievementsHeader(
                    earnedCountAsync: earnedCountAsync,
                    streakAsync: streakAsync,
                    totalBadges: badges.length,
                  ),

                  // Challenges section
                  ChallengesSection(
                    challengesAsync: challengesAsync,
                    onAccept: (id) => _handleChallengeAccept(context, id),
                    onDecline: (id) => _handleChallengeDecline(context, id),
                  ),

                  // Badges section
                  BadgesSection(badges: badges),
                ],
              ),
            );
          },
        ),
      ),
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
    } catch (_) {
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
        content: const Text('Challenge accepted!'),
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
  const _ErrorState({required this.error});

  final String error;

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
            Text(
              'Start Your Journey!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing * 0.5),
            Text(
              'Complete activities and build momentum to earn your first badges. Chat with your AI coach, read Today Feed articles, and maintain your streak!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing),
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
