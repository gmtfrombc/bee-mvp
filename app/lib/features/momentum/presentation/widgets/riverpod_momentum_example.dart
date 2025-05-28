import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../providers/momentum_provider.dart';
import '../providers/momentum_api_provider.dart';
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
            onPressed: () => ref.read(momentumControllerProvider).refresh(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Basic Provider Watching'),
            const _BasicProviderExample(),

            SizedBox(height: ResponsiveService.getLargeSpacing(context)),

            _buildSectionTitle(context, 'Conditional Rendering'),
            const _ConditionalRenderingExample(),

            SizedBox(height: ResponsiveService.getLargeSpacing(context)),

            _buildSectionTitle(context, 'State Mutation'),
            const _StateMutationExample(),

            SizedBox(height: ResponsiveService.getLargeSpacing(context)),

            _buildSectionTitle(context, 'UI State Management'),
            const _UIStateExample(),

            SizedBox(height: ResponsiveService.getLargeSpacing(context)),

            _buildSectionTitle(context, 'Real-time Updates'),
            const _RealTimeUpdatesExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveService.getMediumSpacing(context),
      ),
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
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current State: ${momentumState?.name ?? 'Loading...'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            Text(
              'Percentage: ${percentage?.toStringAsFixed(1) ?? 'Loading...'}%',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            Text(
              'Message: ${message ?? 'Loading...'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
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
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              Row(
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(
                    width: ResponsiveService.getResponsiveSpacing(context),
                  ),
                  const Text('Loading momentum data...'),
                ],
              )
            else if (error != null)
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  SizedBox(width: ResponsiveService.getSmallSpacing(context)),
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
                  SizedBox(width: ResponsiveService.getSmallSpacing(context)),
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
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulate State Changes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        () => ref
                            .read(momentumControllerProvider)
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
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        () => ref
                            .read(momentumControllerProvider)
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
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        () => ref
                            .read(momentumControllerProvider)
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
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UI State Tracking',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            Text(
              'Last Button Tapped: ${userInteraction.lastTappedButton ?? 'None'}',
            ),
            Text(
              'Last Interaction: ${userInteraction.lastInteractionTime?.toString() ?? 'None'}',
            ),
            Text('Card Pressed: ${cardInteraction.isPressed}'),
            Text('Card Scale: ${cardInteraction.scale.toStringAsFixed(2)}'),
            Text('Modal Visible: $modalVisible'),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
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
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
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
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Data Updates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            if (stats != null) ...[
              Text('Lessons: ${stats.lessonsRatio}'),
              Text('Streak: ${stats.streakText}'),
              Text('Today: ${stats.todayText}'),
            ] else
              const Text('Loading stats...'),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            Text('Weekly Trend: ${weeklyTrend?.length ?? 0} days'),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            ElevatedButton(
              onPressed: () => ref.read(momentumControllerProvider).refresh(),
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }
}
