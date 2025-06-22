import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';
import '../../domain/models/momentum_data.dart';
import '../providers/momentum_provider.dart';
import '../providers/momentum_api_provider.dart' as api;

import '../widgets/momentum_card.dart';
import '../widgets/weekly_trend_chart.dart';
import '../widgets/quick_stats_cards.dart';
import '../widgets/action_buttons.dart';
import '../widgets/momentum_detail_modal.dart';
import '../widgets/momentum_gauge.dart';
import '../widgets/skeleton_widgets.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_widgets.dart';
import '../../../../core/services/error_handling_service.dart';
import 'notification_settings_screen.dart';
import 'profile_settings_screen.dart';

// Today Feed imports
import '../../../today_feed/presentation/widgets/today_feed_tile.dart';
import '../providers/today_feed_provider.dart';
import '../../../today_feed/presentation/screens/today_feed_article_screen.dart';

// Gamification imports
import '../../../gamification/ui/achievements_screen.dart';

// Coach Chat imports
/// Main momentum meter screen
/// Displays the user's current momentum state and provides quick actions
class MomentumScreen extends ConsumerWidget {
  const MomentumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentumAsync = ref.watch(momentumProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Welcome back, Sarah!'),
        actions: [
          Semantics(
            label: 'Notifications',
            hint: 'Tap to view notifications',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
          ),
          Semantics(
            label: 'Profile',
            hint: 'Tap to view profile settings',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline banner
            const OfflineBanner(),

            // Main content with responsive layout
            Expanded(
              child: MomentumRefreshIndicator(
                onRefresh:
                    () => ref.read(api.momentumControllerProvider).refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: ResponsiveLayout(
                    centerContent: ResponsiveService.shouldUseExpandedLayout(
                      context,
                    ),
                    child: momentumAsync.when(
                      loading: () => const SkeletonMomentumScreen(),
                      error:
                          (error, stack) => MomentumErrorWidget(
                            error:
                                error is AppError
                                    ? error
                                    : AppError.fromException(error),
                            onRetry:
                                () =>
                                    ref
                                        .read(api.momentumControllerProvider)
                                        .refresh(),
                          ),
                      data:
                          (momentumData) =>
                              _MomentumContent(momentumData: momentumData),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main content view with momentum data - now using Riverpod providers
class _MomentumContent extends ConsumerWidget {
  final MomentumData momentumData;

  const _MomentumContent({required this.momentumData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch individual providers for reactive updates
    final weeklyTrend = ref.watch(weeklyTrendProvider);
    final stats = ref.watch(momentumStatsProvider);
    final momentumState = ref.watch(momentumStateProvider);
    final todayFeedState = ref.watch(todayFeedProvider);

    // Get responsive spacing
    final spacing = ResponsiveService.getResponsiveSpacing(context);

    return Semantics(
      label: 'Momentum dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Momentum Card - T1.1.3.3 Complete
          MomentumCard(
            momentumData: momentumData,
            onTap: () {
              // T1.1.3.7: Show detail modal
              showMomentumDetailModal(context, momentumData);
            },
          ),

          SizedBox(height: spacing),

          // Today Feed Tile - Fresh daily content
          TodayFeedTile(
            state: todayFeedState,
            onTap: () async {
              final notifier = ref.read(todayFeedProvider.notifier);
              final content = todayFeedState.content;

              if (content != null && context.mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TodayFeedArticleScreen(content: content),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "We're just writing something up — check back soon!",
                    ),
                  ),
                );
              }

              // Record interaction (once per day)
              await notifier.handleTap();
            },
            onRetry: () {
              ref.read(todayFeedProvider.notifier).forceRefresh();
            },
            onShare: () {
              ref.read(todayFeedProvider.notifier).handleShare();
            },
            onBookmark: () {
              ref.read(todayFeedProvider.notifier).handleBookmark();
            },
            onInteraction: (type) {
              ref.read(todayFeedProvider.notifier).recordInteraction(type);
            },
            showMomentumIndicator: true,
            enableAnimations: true,
            margin: ResponsiveService.getResponsivePadding(context),
          ),

          SizedBox(height: spacing),

          // Weekly Trend Chart - T1.1.3.4 Complete
          if (weeklyTrend != null)
            WeeklyTrendChart(weeklyTrend: weeklyTrend)
          else
            const SkeletonWeeklyTrendChart(),

          SizedBox(height: spacing),

          // Quick Stats Cards - T1.1.3.5 Complete
          if (stats != null)
            QuickStatsCards(
              stats: stats,
              onLessonsTap: () {
                // TODO: Navigate to lessons (T1.1.3.6)
                context.announceToScreenReader('Navigating to lessons');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lessons view coming soon!')),
                );
              },
              onStreakTap: () {
                // TODO: Navigate to streak details (T1.1.3.6)
                context.announceToScreenReader('Navigating to streak details');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Streak details coming soon!')),
                );
              },
              onTodayTap: () {
                // TODO: Navigate to today's activity (T1.1.3.6)
                context.announceToScreenReader(
                  'Navigating to today\'s activity',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Today\'s activity coming soon!'),
                  ),
                );
              },
              onAchievementsTap: () {
                // Navigate to achievements screen
                context.announceToScreenReader('Navigating to achievements');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AchievementsScreen(),
                  ),
                );
              },
            )
          else
            const SkeletonQuickStatsCards(),

          SizedBox(height: spacing),

          // Action Buttons - T1.1.3.6 Complete
          if (momentumState != null)
            ActionButtons(
              state: momentumState,
              onLearnTap: () {
                // TODO: Navigate to learning content
                context.announceToScreenReader('Opening learning content');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Learning content coming soon!'),
                  ),
                );
              },
              onShareTap: () {
                // TODO: Navigate to sharing options
                context.announceToScreenReader('Opening sharing options');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing options coming soon!')),
                );
              },
            )
          else
            const SkeletonActionButtons(),

          SizedBox(height: spacing),

          // Demo section now using Riverpod providers
          const _DemoSection(),
        ],
      ),
    );
  }
}

/// Demo section using Riverpod providers for state management
class _DemoSection extends ConsumerWidget {
  const _DemoSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoStateProvider);
    final demoPercentage = ref.watch(demoPercentageProvider);

    return Card(
      margin: ResponsiveService.getResponsivePadding(context),
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'State Transition Demo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
            Center(
              child: MomentumGauge(
                state: demoState,
                percentage: demoPercentage,
                size: 140,
                stateTransitionDuration: const Duration(milliseconds: 800),
              ),
            ),
            SizedBox(height: ResponsiveService.getLargeSpacing(context)),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DemoButton(
                  label: 'Rising 🚀',
                  state: MomentumState.rising,
                  color: AppTheme.momentumRising,
                ),
                _DemoButton(
                  label: 'Steady 🙂',
                  state: MomentumState.steady,
                  color: AppTheme.momentumSteady,
                ),
                _DemoButton(
                  label: 'Care 🌱',
                  state: MomentumState.needsCare,
                  color: AppTheme.momentumCare,
                ),
              ],
            ),
            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
            Text(
              'Tap the buttons above to see smooth state transitions with haptic feedback!',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual demo button using Riverpod for state management
class _DemoButton extends ConsumerWidget {
  final String label;
  final MomentumState state;
  final Color color;

  const _DemoButton({
    required this.label,
    required this.state,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDemoState = ref.watch(demoStateProvider);
    final isSelected = currentDemoState == state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            // Update demo state using Riverpod
            ref.read(demoStateProvider.notifier).update((_) => state);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected
                    ? color
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            foregroundColor:
                isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
            elevation: isSelected ? 2 : 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
