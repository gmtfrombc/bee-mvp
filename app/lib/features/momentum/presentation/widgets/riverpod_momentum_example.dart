import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/momentum_provider.dart';
import '../providers/ui_state_provider.dart';

/// Comprehensive example widget demonstrating Riverpod state management patterns
/// This widget showcases all the different ways to use Riverpod providers
/// for reactive state management in the momentum meter feature
class RiverpodMomentumExample extends ConsumerWidget {
  const RiverpodMomentumExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod State Management Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(momentumProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Basic Provider Watching'),
            const _BasicProviderExample(),

            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Conditional Rendering'),
            const _ConditionalRenderingExample(),

            const SizedBox(height: 24),

            _buildSectionTitle(context, 'State Mutation'),
            const _StateMutationExample(),

            const SizedBox(height: 24),

            _buildSectionTitle(context, 'UI State Management'),
            const _UIStateExample(),

            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Real-time Updates'),
            const _RealTimeUpdatesExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

/// Example 1: Basic provider watching
class _BasicProviderExample extends ConsumerWidget {
  const _BasicProviderExample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch individual providers
    final momentumState = ref.watch(momentumStateProvider);
    final percentage = ref.watch(momentumPercentageProvider);
    final message = ref.watch(momentumMessageProvider);
    final lastUpdated = ref.watch(lastUpdatedProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current State: ${momentumState?.name ?? 'Loading...'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Percentage: ${percentage?.toStringAsFixed(1) ?? 'Loading...'}%',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Message: ${message ?? 'Loading...'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${lastUpdated?.toString() ?? 'Loading...'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 2: Conditional rendering based on provider state
class _ConditionalRenderingExample extends ConsumerWidget {
  const _ConditionalRenderingExample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorProvider);
    final momentumState = ref.watch(momentumStateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Loading momentum data...'),
                ],
              )
            else if (error != null)
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error: $error')),
                ],
              )
            else if (momentumState != null)
              Row(
                children: [
                  Icon(
                    _getStateIcon(momentumState),
                    color: AppTheme.getMomentumColor(momentumState),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${momentumState.name}',
                    style: TextStyle(
                      color: AppTheme.getMomentumColor(momentumState),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              const Text('No data available'),
          ],
        ),
      ),
    );
  }

  IconData _getStateIcon(MomentumState state) {
    switch (state) {
      case MomentumState.rising:
        return Icons.trending_up;
      case MomentumState.steady:
        return Icons.trending_flat;
      case MomentumState.needsCare:
        return Icons.trending_down;
    }
  }
}

/// Example 3: State mutation using providers
class _StateMutationExample extends ConsumerWidget {
  const _StateMutationExample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(momentumStateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulate State Changes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        () => ref
                            .read(momentumProvider.notifier)
                            .simulateStateChange(MomentumState.rising),
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text('Rising'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          currentState == MomentumState.rising
                              ? AppTheme.momentumRising
                              : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        () => ref
                            .read(momentumProvider.notifier)
                            .simulateStateChange(MomentumState.steady),
                    icon: const Icon(Icons.sentiment_satisfied),
                    label: const Text('Steady'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          currentState == MomentumState.steady
                              ? AppTheme.momentumSteady
                              : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        () => ref
                            .read(momentumProvider.notifier)
                            .simulateStateChange(MomentumState.needsCare),
                    icon: const Icon(Icons.eco),
                    label: const Text('Care'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          currentState == MomentumState.needsCare
                              ? AppTheme.momentumCare
                              : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 4: UI state management
class _UIStateExample extends ConsumerWidget {
  const _UIStateExample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInteraction = ref.watch(userInteractionProvider);
    final cardInteraction = ref.watch(cardInteractionProvider);
    final modalVisible = ref.watch(modalVisibilityProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UI State Tracking',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Last Button Tapped: ${userInteraction.lastTappedButton ?? 'None'}',
            ),
            Text(
              'Last Interaction: ${userInteraction.lastInteractionTime?.toString() ?? 'None'}',
            ),
            Text('Card Pressed: ${cardInteraction.isPressed}'),
            Text('Card Scale: ${cardInteraction.scale.toStringAsFixed(2)}'),
            Text('Modal Visible: $modalVisible'),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(userInteractionProvider.notifier)
                        .state = userInteraction.copyWith(
                      lastTappedButton: 'Test Button',
                      lastInteractionTime: DateTime.now(),
                    );
                  },
                  child: const Text('Test Interaction'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.read(modalVisibilityProvider.notifier).state =
                        !modalVisible;
                  },
                  child: Text(modalVisible ? 'Hide Modal' : 'Show Modal'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 5: Real-time updates demonstration
class _RealTimeUpdatesExample extends ConsumerWidget {
  const _RealTimeUpdatesExample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(momentumStatsProvider);
    final weeklyTrend = ref.watch(weeklyTrendProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Data Updates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (stats != null) ...[
              Text('Lessons: ${stats.lessonsRatio}'),
              Text('Streak: ${stats.streakText}'),
              Text('Today: ${stats.todayText}'),
            ] else
              const Text('Loading stats...'),
            const SizedBox(height: 12),
            Text('Weekly Trend: ${weeklyTrend?.length ?? 0} days'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(momentumProvider.notifier).refresh(),
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }
}
