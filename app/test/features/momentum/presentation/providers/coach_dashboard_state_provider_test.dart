import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/momentum/domain/models/coach_dashboard_filters.dart';
import 'package:app/features/momentum/presentation/providers/coach_dashboard_state_provider.dart';

void main() {
  group('CoachDashboardStateNotifier', () {
    late ProviderContainer container;
    late CoachDashboardStateNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(coachDashboardStateProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('Initialization', () {
      test('should initialize with default filter values', () {
        final state = container.read(coachDashboardStateProvider);

        expect(state.timeRange, equals('7d'));
        expect(state.priority, equals('all'));
        expect(state.status, equals('all'));
        expect(state.hasActiveFilters, isFalse);
      });

      test('should have correct default display names', () {
        final state = container.read(coachDashboardStateProvider);

        expect(state.timeRangeDisplayName, equals('Last 7 Days'));
        expect(state.priorityDisplayName, equals('All Priorities'));
        expect(state.statusDisplayName, equals('All Statuses'));
      });
    });

    group('updateTimeRange', () {
      test('should update time range filter', () {
        notifier.updateTimeRange('30d');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('30d'));
        expect(state.timeRangeDisplayName, equals('Last 30 Days'));
      });

      test('should maintain other filter values when updating time range', () {
        notifier.updatePriority('high');
        notifier.updateStatus('pending');
        notifier.updateTimeRange('24h');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('24h'));
        expect(state.priority, equals('high'));
        expect(state.status, equals('pending'));
      });

      test('should handle all valid time range values', () {
        final timeRanges = ['24h', '7d', '30d'];

        for (final timeRange in timeRanges) {
          notifier.updateTimeRange(timeRange);
          final state = container.read(coachDashboardStateProvider);
          expect(state.timeRange, equals(timeRange));
        }
      });
    });

    group('updatePriority', () {
      test('should update priority filter', () {
        notifier.updatePriority('high');

        final state = container.read(coachDashboardStateProvider);
        expect(state.priority, equals('high'));
        expect(state.priorityDisplayName, equals('High Priority'));
      });

      test('should maintain other filter values when updating priority', () {
        notifier.updateTimeRange('30d');
        notifier.updateStatus('pending');
        notifier.updatePriority('low');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('30d'));
        expect(state.priority, equals('low'));
        expect(state.status, equals('pending'));
      });

      test('should handle all valid priority values', () {
        final priorities = ['all', 'high', 'medium', 'low'];

        for (final priority in priorities) {
          notifier.updatePriority(priority);
          final state = container.read(coachDashboardStateProvider);
          expect(state.priority, equals(priority));
        }
      });
    });

    group('updateStatus', () {
      test('should update status filter', () {
        notifier.updateStatus('completed');

        final state = container.read(coachDashboardStateProvider);
        expect(state.status, equals('completed'));
        expect(state.statusDisplayName, equals('Completed'));
      });

      test('should maintain other filter values when updating status', () {
        notifier.updateTimeRange('30d');
        notifier.updatePriority('high');
        notifier.updateStatus('in_progress');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('30d'));
        expect(state.priority, equals('high'));
        expect(state.status, equals('in_progress'));
      });

      test('should handle all valid status values', () {
        final statuses = ['all', 'pending', 'in_progress', 'completed'];

        for (final status in statuses) {
          notifier.updateStatus(status);
          final state = container.read(coachDashboardStateProvider);
          expect(state.status, equals(status));
        }
      });
    });

    group('updateFilters', () {
      test('should update multiple filters at once', () {
        notifier.updateFilters(
          timeRange: '30d',
          priority: 'high',
          status: 'pending',
        );

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('30d'));
        expect(state.priority, equals('high'));
        expect(state.status, equals('pending'));
      });

      test('should update only specified filters', () {
        notifier.updatePriority('medium');
        notifier.updateStatus('in_progress');

        notifier.updateFilters(timeRange: '24h');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('24h'));
        expect(state.priority, equals('medium')); // Should remain unchanged
        expect(state.status, equals('in_progress')); // Should remain unchanged
      });

      test('should handle partial updates correctly', () {
        notifier.updateFilters(priority: 'high');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('7d')); // Default value
        expect(state.priority, equals('high'));
        expect(state.status, equals('all')); // Default value
      });
    });

    group('resetFilters', () {
      test('should reset all filters to default values', () {
        notifier.updateTimeRange('30d');
        notifier.updatePriority('high');
        notifier.updateStatus('pending');

        notifier.resetFilters();

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('7d'));
        expect(state.priority, equals('all'));
        expect(state.status, equals('all'));
        expect(state.hasActiveFilters, isFalse);
      });

      test('should reset from any state to defaults', () {
        notifier.updateFilters(
          timeRange: '24h',
          priority: 'low',
          status: 'completed',
        );

        notifier.resetFilters();

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('7d'));
        expect(state.priority, equals('all'));
        expect(state.status, equals('all'));
      });
    });

    group('hasActiveFilters', () {
      test('should return false for default filter state', () {
        expect(notifier.hasActiveFilters, isFalse);
      });

      test('should return true when time range is non-default', () {
        notifier.updateTimeRange('30d');
        expect(notifier.hasActiveFilters, isTrue);
      });

      test('should return true when priority is non-default', () {
        notifier.updatePriority('high');
        expect(notifier.hasActiveFilters, isTrue);
      });

      test('should return true when status is non-default', () {
        notifier.updateStatus('pending');
        expect(notifier.hasActiveFilters, isTrue);
      });

      test('should return true when any filter is non-default', () {
        notifier.updateFilters(
          timeRange: '24h',
          priority: 'medium',
          status: 'in_progress',
        );
        expect(notifier.hasActiveFilters, isTrue);
      });
    });

    group('filterSummary', () {
      test('should return "All interventions" for default filters', () {
        expect(notifier.filterSummary, equals('All interventions'));
      });

      test('should include time range in summary when non-default', () {
        notifier.updateTimeRange('30d');
        expect(notifier.filterSummary, equals('Last 30 Days'));
      });

      test('should include priority in summary when non-default', () {
        notifier.updatePriority('high');
        expect(notifier.filterSummary, equals('High Priority priority'));
      });

      test('should include status in summary when non-default', () {
        notifier.updateStatus('pending');
        expect(notifier.filterSummary, equals('Pending status'));
      });

      test('should combine multiple active filters in summary', () {
        notifier.updateFilters(
          timeRange: '24h',
          priority: 'high',
          status: 'pending',
        );
        expect(
          notifier.filterSummary,
          equals('Last 24 Hours, High Priority priority, Pending status'),
        );
      });

      test('should handle partial filter combinations', () {
        notifier.updateTimeRange('30d');
        notifier.updateStatus('completed');

        expect(
          notifier.filterSummary,
          equals('Last 30 Days, Completed status'),
        );
      });
    });
  });

  group('Provider Integration', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('coachDashboardStateProvider', () {
      test('should provide access to current filter state', () {
        final state = container.read(coachDashboardStateProvider);
        expect(state, isA<CoachDashboardFilters>());
        expect(state.timeRange, equals('7d'));
      });

      test('should notify listeners when state changes', () {
        bool notified = false;
        container.listen(
          coachDashboardStateProvider,
          (_, __) => notified = true,
        );

        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updateTimeRange('30d');

        expect(notified, isTrue);
      });
    });

    group('Convenience Providers', () {
      test('timeRangeFilterProvider should return current time range', () {
        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updateTimeRange('30d');

        final timeRange = container.read(timeRangeFilterProvider);
        expect(timeRange, equals('30d'));
      });

      test('priorityFilterProvider should return current priority', () {
        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updatePriority('high');

        final priority = container.read(priorityFilterProvider);
        expect(priority, equals('high'));
      });

      test('statusFilterProvider should return current status', () {
        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updateStatus('pending');

        final status = container.read(statusFilterProvider);
        expect(status, equals('pending'));
      });

      test('hasActiveFiltersProvider should reflect filter state', () {
        expect(container.read(hasActiveFiltersProvider), isFalse);

        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updatePriority('high');

        expect(container.read(hasActiveFiltersProvider), isTrue);
      });

      test('filterSummaryProvider should return current summary', () {
        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updateTimeRange('24h');

        final summary = container.read(filterSummaryProvider);
        expect(summary, equals('Last 24 Hours'));
      });
    });

    group('Filter Options Providers', () {
      test('filterOptionsProvider should return all available options', () {
        final options = container.read(filterOptionsProvider);

        expect(options['timeRange'], isNotNull);
        expect(options['priority'], isNotNull);
        expect(options['status'], isNotNull);

        expect(options['timeRange'], contains('24h'));
        expect(options['priority'], contains('high'));
        expect(options['status'], contains('pending'));
      });

      test('enumFilterOptionsProvider should return enum values', () {
        final enumOptions = container.read(enumFilterOptionsProvider);

        expect(enumOptions['timeRange'], isNotNull);
        expect(enumOptions['priority'], isNotNull);
        expect(enumOptions['status'], isNotNull);

        expect(enumOptions['timeRange'], contains(TimeRangeFilter.day));
        expect(enumOptions['priority'], contains(PriorityFilter.high));
        expect(enumOptions['status'], contains(StatusFilter.inProgress));
      });
    });

    group('State Actions Provider', () {
      test('should provide access to notifier methods', () {
        final actions = container.read(coachDashboardStateActionsProvider);
        expect(actions, isA<CoachDashboardStateNotifier>());

        actions.updateTimeRange('30d');
        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('30d'));
      });
    });
  });

  group('Provider Reactivity', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should handle rapid state updates correctly', () {
      final notifier = container.read(coachDashboardStateProvider.notifier);

      notifier.updateTimeRange('24h');
      notifier.updatePriority('high');
      notifier.updateStatus('pending');

      final state = container.read(coachDashboardStateProvider);
      expect(state.timeRange, equals('24h'));
      expect(state.priority, equals('high'));
      expect(state.status, equals('pending'));
    });

    test('should maintain consistency across multiple provider reads', () {
      final notifier = container.read(coachDashboardStateProvider.notifier);
      notifier.updateFilters(
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

  group('Edge Cases', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should handle null values gracefully in updateFilters', () {
      final notifier = container.read(coachDashboardStateProvider.notifier);

      notifier.updateFilters(timeRange: null, priority: null, status: null);

      final state = container.read(coachDashboardStateProvider);
      expect(state.timeRange, equals('7d')); // Should remain default
      expect(state.priority, equals('all')); // Should remain default
      expect(state.status, equals('all')); // Should remain default
    });

    test('should handle multiple resets correctly', () {
      final notifier = container.read(coachDashboardStateProvider.notifier);

      notifier.updateFilters(
        timeRange: '30d',
        priority: 'high',
        status: 'pending',
      );

      notifier.resetFilters();
      notifier.resetFilters(); // Multiple resets should be safe

      final state = container.read(coachDashboardStateProvider);
      expect(state.timeRange, equals('7d'));
      expect(state.priority, equals('all'));
      expect(state.status, equals('all'));
    });

    test('should handle empty filter summary correctly', () {
      final notifier = container.read(coachDashboardStateProvider.notifier);
      expect(notifier.filterSummary, equals('All interventions'));

      // Even after updates and reset, should handle empty state
      notifier.updateTimeRange('30d');
      notifier.resetFilters();
      expect(notifier.filterSummary, equals('All interventions'));
    });
  });
}
