import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/momentum/presentation/providers/coach_dashboard_state_provider.dart';
import 'package:app/features/momentum/domain/models/coach_dashboard_filters.dart';

void main() {
  group('CoachDashboardScreen State Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Filter State Management', () {
      test('should initialize with default filter state', () {
        final filters = container.read(coachDashboardStateProvider);

        expect(filters.timeRange, equals('7d'));
        expect(filters.priority, equals('all'));
        expect(filters.status, equals('all'));
        expect(filters.hasActiveFilters, isFalse);
      });

      test('should update individual filters correctly', () {
        final stateActions = container.read(coachDashboardStateActionsProvider);

        // Update time range
        stateActions.updateTimeRange('24h');
        final filtersAfterTimeRange = container.read(
          coachDashboardStateProvider,
        );
        expect(filtersAfterTimeRange.timeRange, equals('24h'));

        // Update priority
        stateActions.updatePriority('medium');
        final filtersAfterPriority = container.read(
          coachDashboardStateProvider,
        );
        expect(filtersAfterPriority.priority, equals('medium'));

        // Update status
        stateActions.updateStatus('in_progress');
        final filtersAfterStatus = container.read(coachDashboardStateProvider);
        expect(filtersAfterStatus.status, equals('in_progress'));
      });

      test('should handle batch filter updates', () {
        final stateActions = container.read(coachDashboardStateActionsProvider);

        stateActions.updateFilters(
          timeRange: '7d',
          priority: 'low',
          status: 'completed',
        );

        final filtersAfterBatch = container.read(coachDashboardStateProvider);
        expect(filtersAfterBatch.timeRange, equals('7d'));
        expect(filtersAfterBatch.priority, equals('low'));
        expect(filtersAfterBatch.status, equals('completed'));
      });

      test('should reset filters to defaults', () {
        final stateActions = container.read(coachDashboardStateActionsProvider);

        // Set some non-default values
        stateActions.updateFilters(
          timeRange: '30d',
          priority: 'high',
          status: 'pending',
        );

        // Reset filters
        stateActions.resetFilters();

        final filtersAfterReset = container.read(coachDashboardStateProvider);
        expect(filtersAfterReset.timeRange, equals('7d'));
        expect(filtersAfterReset.priority, equals('all'));
        expect(filtersAfterReset.status, equals('all'));
        expect(filtersAfterReset.hasActiveFilters, isFalse);
      });
    });

    group('Convenience Providers', () {
      test('should provide access to individual filter values', () {
        final stateActions = container.read(coachDashboardStateActionsProvider);
        stateActions.updateFilters(
          timeRange: '30d',
          priority: 'high',
          status: 'pending',
        );

        final timeRange = container.read(timeRangeFilterProvider);
        final priority = container.read(priorityFilterProvider);
        final status = container.read(statusFilterProvider);
        final hasActiveFilters = container.read(hasActiveFiltersProvider);

        expect(timeRange, equals('30d'));
        expect(priority, equals('high'));
        expect(status, equals('pending'));
        expect(hasActiveFilters, isTrue);
      });

      test('should provide filter summary', () {
        final stateActions = container.read(coachDashboardStateActionsProvider);

        // Test default state
        expect(
          container.read(filterSummaryProvider),
          equals('All interventions'),
        );

        // Test with time range only
        stateActions.updateTimeRange('24h');
        // Force the provider to recalculate by reading the state again
        final summaryAfterTimeRange =
            container.read(coachDashboardStateProvider.notifier).filterSummary;
        expect(summaryAfterTimeRange, equals('Last 24 Hours'));

        // Test with multiple filters
        stateActions.updateFilters(
          timeRange: '30d',
          priority: 'high',
          status: 'pending',
        );
        final summaryAfterMultiple =
            container.read(coachDashboardStateProvider.notifier).filterSummary;
        expect(
          summaryAfterMultiple,
          equals('Last 30 Days, High Priority priority, Pending status'),
        );
      });
    });

    group('Provider Reactivity', () {
      test('should notify listeners when state changes', () {
        bool notified = false;
        container.listen(
          coachDashboardStateProvider,
          (_, __) => notified = true,
        );

        final stateActions = container.read(coachDashboardStateActionsProvider);
        stateActions.updateTimeRange('30d');

        expect(notified, isTrue);
      });

      test('should handle rapid state updates', () {
        final stateActions = container.read(coachDashboardStateActionsProvider);

        // Rapid fire state changes
        for (int i = 0; i < 100; i++) {
          stateActions.updateTimeRange(i % 2 == 0 ? '24h' : '30d');
          stateActions.updatePriority(i % 3 == 0 ? 'high' : 'medium');
          stateActions.updateStatus(i % 4 == 0 ? 'pending' : 'in_progress');
        }

        // Should not crash and should have consistent final state
        final finalFilters = container.read(coachDashboardStateProvider);
        expect(finalFilters, isA<CoachDashboardFilters>());
      });

      test('should maintain consistency across multiple provider reads', () {
        final stateActions = container.read(coachDashboardStateActionsProvider);
        stateActions.updateFilters(
          timeRange: '30d',
          priority: 'medium',
          status: 'in_progress',
        );

        final state = container.read(coachDashboardStateProvider);
        final timeRange = container.read(timeRangeFilterProvider);
        final priority = container.read(priorityFilterProvider);
        final status = container.read(statusFilterProvider);

        expect(state.timeRange, equals(timeRange));
        expect(state.priority, equals(priority));
        expect(state.status, equals(status));
      });
    });

    group('Filter Options', () {
      test('should provide all available filter options', () {
        final options = container.read(filterOptionsProvider);

        expect(options['timeRange'], isNotNull);
        expect(options['priority'], isNotNull);
        expect(options['status'], isNotNull);

        expect(options['timeRange'], contains('24h'));
        expect(options['priority'], contains('high'));
        expect(options['status'], contains('pending'));
      });

      test('should provide enum filter options', () {
        final enumOptions = container.read(enumFilterOptionsProvider);

        expect(enumOptions['timeRange'], isNotNull);
        expect(enumOptions['priority'], isNotNull);
        expect(enumOptions['status'], isNotNull);

        expect(enumOptions['timeRange'], contains(TimeRangeFilter.day));
        expect(enumOptions['priority'], contains(PriorityFilter.high));
        expect(enumOptions['status'], contains(StatusFilter.inProgress));
      });
    });

    group('Performance & Memory', () {
      test('should handle multiple provider containers', () {
        final container2 = ProviderContainer();
        final container3 = ProviderContainer();

        try {
          // Test that multiple containers work independently
          final stateActions1 = container.read(
            coachDashboardStateActionsProvider,
          );
          final stateActions2 = container2.read(
            coachDashboardStateActionsProvider,
          );
          final stateActions3 = container3.read(
            coachDashboardStateActionsProvider,
          );

          stateActions1.updateTimeRange('24h');
          stateActions2.updateTimeRange('30d');
          stateActions3.updateTimeRange('7d');

          expect(container.read(timeRangeFilterProvider), equals('24h'));
          expect(container2.read(timeRangeFilterProvider), equals('30d'));
          expect(container3.read(timeRangeFilterProvider), equals('7d'));
        } finally {
          container2.dispose();
          container3.dispose();
        }
      });

      test('should handle container disposal gracefully', () {
        final disposableContainer = ProviderContainer();

        final stateActions = disposableContainer.read(
          coachDashboardStateActionsProvider,
        );
        stateActions.updateTimeRange('30d');

        final filters = disposableContainer.read(coachDashboardStateProvider);
        expect(filters.timeRange, equals('30d'));

        // Should not throw when disposed
        expect(() => disposableContainer.dispose(), returnsNormally);
      });

      test('should efficiently handle repeated reads', () {
        final stopwatch = Stopwatch()..start();

        // Perform many reads
        for (int i = 0; i < 1000; i++) {
          container.read(coachDashboardStateProvider);
          container.read(timeRangeFilterProvider);
          container.read(priorityFilterProvider);
          container.read(statusFilterProvider);
          container.read(hasActiveFiltersProvider);
        }

        stopwatch.stop();

        // Should complete quickly (under 100ms)
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: '1000 provider reads took ${stopwatch.elapsedMilliseconds}ms',
        );
      });
    });

    group('Edge Cases', () {
      test('should handle null values in updateFilters', () {
        final stateActions = container.read(coachDashboardStateActionsProvider);

        stateActions.updateFilters(
          timeRange: null,
          priority: null,
          status: null,
        );

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('7d')); // Should remain default
        expect(state.priority, equals('all')); // Should remain default
        expect(state.status, equals('all')); // Should remain default
      });

      test('should handle multiple resets', () {
        final stateActions = container.read(coachDashboardStateActionsProvider);

        stateActions.updateFilters(
          timeRange: '30d',
          priority: 'high',
          status: 'pending',
        );

        // Multiple resets should be safe
        stateActions.resetFilters();
        stateActions.resetFilters();
        stateActions.resetFilters();

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('7d'));
        expect(state.priority, equals('all'));
        expect(state.status, equals('all'));
      });

      test('should handle concurrent state updates', () {
        final stateActions = container.read(coachDashboardStateActionsProvider);

        // Simulate concurrent updates
        stateActions.updateTimeRange('24h');
        stateActions.updatePriority('high');
        stateActions.updateStatus('pending');
        stateActions.updateFilters(timeRange: '30d', priority: 'low');
        stateActions.updateStatus('completed');

        final finalState = container.read(coachDashboardStateProvider);
        expect(finalState.timeRange, equals('30d'));
        expect(finalState.priority, equals('low'));
        expect(finalState.status, equals('completed'));
      });
    });
  });
}
