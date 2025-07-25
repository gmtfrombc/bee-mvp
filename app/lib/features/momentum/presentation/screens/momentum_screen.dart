import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';
import '../../domain/models/momentum_data.dart';
import '../providers/momentum_provider.dart';
import '../providers/momentum_api_provider.dart' as api;
import '../../../auth/ui/widgets/email_verification_banner.dart';

import '../widgets/momentum_card.dart';
import '../widgets/weekly_trend_chart.dart';
import '../widgets/quick_stats_cards.dart';
import '../widgets/momentum_detail_modal.dart';
import '../widgets/skeleton_widgets.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_widgets.dart';
import '../../../../core/services/error_handling_service.dart';
import 'package:app/core/services/action_step_status_service.dart';
import 'package:app/features/action_steps/ui/widgets/daily_checkin_card.dart';
import 'package:app/features/health_signals/pes/widgets/pes_checkin_card.dart';
// Routing
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';

// Today Feed imports
import '../../../today_feed/presentation/widgets/today_feed_tile.dart';
import '../providers/today_feed_provider.dart';

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
                context.push(kNotificationsRoute);
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
                context.push(kProfileSettingsRoute);
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

            // Email verification banner
            const EmailVerificationBanner(),

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

          // Daily Action Step Check-in (T12)
          const DailyCheckinCard(),

          SizedBox(height: spacing),

          // PES Check-in (Perceived Energy Score)
          const PesCheckinCard(),

          SizedBox(height: spacing),

          // Today Feed Tile - Fresh daily content
          TodayFeedTile(
            state: todayFeedState,
            onTap: () async {
              final notifier = ref.read(todayFeedProvider.notifier);
              final content = todayFeedState.content;

              if (content != null && context.mounted) {
                await context.push(kTodayFeedArticleRoute, extra: content);
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
              onActionStepTap: () async {
                context.announceToScreenReader('Navigating to Action Step');
                final hasStep =
                    await ActionStepStatusService().hasSetActionStep();
                if (!context.mounted) return;
                if (hasStep) {
                  context.push(kActionStepCurrentRoute);
                } else {
                  context.push(kActionStepSetupRoute);
                }
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
                context.push(kAchievementsRoute);
              },
            )
          else
            const SkeletonQuickStatsCards(),

          SizedBox(height: spacing),

          // Transition State Demo removed per HS task
        ],
      ),
    );
  }
}
