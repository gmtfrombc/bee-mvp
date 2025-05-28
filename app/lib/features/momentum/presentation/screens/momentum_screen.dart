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
        child: RefreshIndicator(
          onRefresh: () => ref.read(momentumProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: momentumAsync.when(
              loading: () => const _LoadingView(),
              error:
                  (error, stack) => _ErrorView(
                    error: error.toString(),
                    onRetry:
                        () => ref.read(momentumProvider.notifier).refresh(),
                  ),
              data:
                  (momentumData) =>
                      _MomentumContent(momentumData: momentumData),
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading view with skeleton screens
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loading momentum card
        Card(
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your momentum...'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Loading placeholders for other sections
        Card(
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                child: Card(
                  child: SizedBox(
                    height: 84,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Error view with retry option
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.momentumCare,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load momentum data',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

/// Main content view with momentum data
class _MomentumContent extends StatelessWidget {
  final MomentumData momentumData;

  const _MomentumContent({required this.momentumData});

  @override
  Widget build(BuildContext context) {
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
        WeeklyTrendChart(weeklyTrend: momentumData.weeklyTrend),

        const SizedBox(height: 24),

        // Quick Stats Cards - T1.1.3.5 Complete
        QuickStatsCards(
          stats: momentumData.stats,
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
        ),

        const SizedBox(height: 24),

        // Action Buttons - T1.1.3.6 Complete
        ActionButtons(
          state: momentumData.state,
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
        ),
      ],
    );
  }
}
