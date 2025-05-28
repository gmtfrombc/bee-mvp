import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/momentum_data.dart';
import '../providers/momentum_provider.dart';

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

/// Main momentum meter screen
/// Displays the user's current momentum state and provides quick actions
class MomentumScreen extends ConsumerWidget {
  const MomentumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentumAsync = ref.watch(momentumProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceSecondary,
      appBar: AppBar(
        title: const Text('Welcome back, Sarah!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline banner
            const OfflineBanner(),

            // Main content
            Expanded(
              child: MomentumRefreshIndicator(
                onRefresh: () => ref.read(momentumProvider.notifier).refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
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
                                  ref.read(momentumProvider.notifier).refresh(),
                        ),
                    data:
                        (momentumData) =>
                            _MomentumContent(momentumData: momentumData),
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

    return Column(
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

        const SizedBox(height: 24),

        // Weekly Trend Chart - T1.1.3.4 Complete
        if (weeklyTrend != null)
          WeeklyTrendChart(weeklyTrend: weeklyTrend)
        else
          const SkeletonWeeklyTrendChart(),

        const SizedBox(height: 24),

        // Quick Stats Cards - T1.1.3.5 Complete
        if (stats != null)
          QuickStatsCards(
            stats: stats,
            onLessonsTap: () {
              // TODO: Navigate to lessons (T1.1.3.6)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lessons view coming soon!')),
              );
            },
            onStreakTap: () {
              // TODO: Navigate to streak details (T1.1.3.6)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Streak details coming soon!')),
              );
            },
            onTodayTap: () {
              // TODO: Navigate to today's activity (T1.1.3.6)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Today\'s activity coming soon!')),
              );
            },
          )
        else
          const SkeletonQuickStatsCards(),

        const SizedBox(height: 24),

        // Action Buttons - T1.1.3.6 Complete
        if (momentumState != null)
          ActionButtons(
            state: momentumState,
            onLearnTap: () {
              // TODO: Navigate to learning content
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Learning content coming soon!')),
              );
            },
            onShareTap: () {
              // TODO: Navigate to sharing options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing options coming soon!')),
              );
            },
          )
        else
          const SkeletonActionButtons(),

        const SizedBox(height: 24),

        // Demo section now using Riverpod providers
        const _DemoSection(),
      ],
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
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'State Transition Demo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Center(
              child: MomentumGauge(
                state: demoState,
                percentage: demoPercentage,
                size: 140,
                stateTransitionDuration: const Duration(milliseconds: 800),
              ),
            ),
            const SizedBox(height: 24),
            Row(
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
            const SizedBox(height: 16),
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

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            // Update demo state using Riverpod
            ref.read(demoStateProvider.notifier).state = state;
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
            elevation: isSelected ? 2 : 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
