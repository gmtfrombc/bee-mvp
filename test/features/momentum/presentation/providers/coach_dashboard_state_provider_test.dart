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

        expect(state.timeRange, equals('week'));
        expect(state.priority, equals('all'));
        expect(state.status, equals('all'));
        expect(state.hasActiveFilters, isFalse);
      });

      test('should have correct default display names', () {
        final state = container.read(coachDashboardStateProvider);

        expect(state.timeRangeDisplayName, equals('This Week'));
        expect(state.priorityDisplayName, equals('All'));
        expect(state.statusDisplayName, equals('All'));
      });
    });

    group('updateTimeRange', () {
      test('should update time range filter', () {
        notifier.updateTimeRange('month');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('month'));
        expect(state.timeRangeDisplayName, equals('This Month'));
      });

      test('should maintain other filter values when updating time range', () {
        notifier.updatePriority('high');
        notifier.updateStatus('active');
        notifier.updateTimeRange('today');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('today'));
        expect(state.priority, equals('high'));
        expect(state.status, equals('active'));
      });

      test('should handle all valid time range values', () {
        final timeRanges = ['today', 'week', 'month', 'quarter', 'year'];

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
        expect(state.priorityDisplayName, equals('High'));
      });

      test('should maintain other filter values when updating priority', () {
        notifier.updateTimeRange('month');
        notifier.updateStatus('active');
        notifier.updatePriority('low');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('month'));
        expect(state.priority, equals('low'));
        expect(state.status, equals('active'));
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
        notifier.updateTimeRange('month');
        notifier.updatePriority('high');
        notifier.updateStatus('scheduled');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('month'));
        expect(state.priority, equals('high'));
        expect(state.status, equals('scheduled'));
      });

      test('should handle all valid status values', () {
        final statuses = [
          'all',
          'active',
          'scheduled',
          'completed',
          'cancelled',
        ];

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
          timeRange: 'month',
          priority: 'high',
          status: 'active',
        );

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('month'));
        expect(state.priority, equals('high'));
        expect(state.status, equals('active'));
      });

      test('should update only specified filters', () {
        notifier.updatePriority('medium');
        notifier.updateStatus('scheduled');

        notifier.updateFilters(timeRange: 'today');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('today'));
        expect(state.priority, equals('medium')); // Should remain unchanged
        expect(state.status, equals('scheduled')); // Should remain unchanged
      });

      test('should handle partial updates correctly', () {
        notifier.updateFilters(priority: 'high');

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('week')); // Default value
        expect(state.priority, equals('high'));
        expect(state.status, equals('all')); // Default value
      });
    });

    group('resetFilters', () {
      test('should reset all filters to default values', () {
        notifier.updateTimeRange('month');
        notifier.updatePriority('high');
        notifier.updateStatus('active');

        notifier.resetFilters();

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('week'));
        expect(state.priority, equals('all'));
        expect(state.status, equals('all'));
        expect(state.hasActiveFilters, isFalse);
      });

      test('should reset from any state to defaults', () {
        notifier.updateFilters(
          timeRange: 'year',
          priority: 'low',
          status: 'cancelled',
        );

        notifier.resetFilters();

        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('week'));
        expect(state.priority, equals('all'));
        expect(state.status, equals('all'));
      });
    });

    group('hasActiveFilters', () {
      test('should return false for default filter state', () {
        expect(notifier.hasActiveFilters, isFalse);
      });

      test('should return true when time range is non-default', () {
        notifier.updateTimeRange('month');
        expect(notifier.hasActiveFilters, isTrue);
      });

      test('should return true when priority is non-default', () {
        notifier.updatePriority('high');
        expect(notifier.hasActiveFilters, isTrue);
      });

      test('should return true when status is non-default', () {
        notifier.updateStatus('active');
        expect(notifier.hasActiveFilters, isTrue);
      });

      test('should return true when any filter is non-default', () {
        notifier.updateFilters(
          timeRange: 'today',
          priority: 'medium',
          status: 'scheduled',
        );
        expect(notifier.hasActiveFilters, isTrue);
      });
    });

    group('filterSummary', () {
      test('should return "All interventions" for default filters', () {
        expect(notifier.filterSummary, equals('All interventions'));
      });

      test('should include time range in summary when non-default', () {
        notifier.updateTimeRange('month');
        expect(notifier.filterSummary, equals('This Month'));
      });

      test('should include priority in summary when non-default', () {
        notifier.updatePriority('high');
        expect(notifier.filterSummary, equals('High priority'));
      });

      test('should include status in summary when non-default', () {
        notifier.updateStatus('active');
        expect(notifier.filterSummary, equals('Active status'));
      });

      test('should combine multiple active filters in summary', () {
        notifier.updateFilters(
          timeRange: 'today',
          priority: 'high',
          status: 'active',
        );
        expect(
          notifier.filterSummary,
          equals('Today, High priority, Active status'),
        );
      });

      test('should handle partial filter combinations', () {
        notifier.updateTimeRange('month');
        notifier.updateStatus('completed');

        expect(notifier.filterSummary, equals('This Month, Completed status'));
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
        expect(state.timeRange, equals('week'));
      });

      test('should notify listeners when state changes', () {
        bool notified = false;
        container.listen(
          coachDashboardStateProvider,
          (_, __) => notified = true,
        );

        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updateTimeRange('month');

        expect(notified, isTrue);
      });
    });

    group('Convenience Providers', () {
      test('timeRangeFilterProvider should return current time range', () {
        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updateTimeRange('month');

        final timeRange = container.read(timeRangeFilterProvider);
        expect(timeRange, equals('month'));
      });

      test('priorityFilterProvider should return current priority', () {
        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updatePriority('high');

        final priority = container.read(priorityFilterProvider);
        expect(priority, equals('high'));
      });

      test('statusFilterProvider should return current status', () {
        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updateStatus('active');

        final status = container.read(statusFilterProvider);
        expect(status, equals('active'));
      });

      test('hasActiveFiltersProvider should reflect filter state', () {
        expect(container.read(hasActiveFiltersProvider), isFalse);

        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updatePriority('high');

        expect(container.read(hasActiveFiltersProvider), isTrue);
      });

      test('filterSummaryProvider should return current summary', () {
        final notifier = container.read(coachDashboardStateProvider.notifier);
        notifier.updateTimeRange('today');

        final summary = container.read(filterSummaryProvider);
        expect(summary, equals('Today'));
      });
    });

    group('Filter Options Providers', () {
      test('filterOptionsProvider should return all available options', () {
        final options = container.read(filterOptionsProvider);

        expect(options['timeRange'], isNotNull);
        expect(options['priority'], isNotNull);
        expect(options['status'], isNotNull);

        expect(options['timeRange'], contains('today'));
        expect(options['priority'], contains('high'));
        expect(options['status'], contains('active'));
      });

      test('enumFilterOptionsProvider should return enum values', () {
        final enumOptions = container.read(enumFilterOptionsProvider);

        expect(enumOptions['timeRange'], isNotNull);
        expect(enumOptions['priority'], isNotNull);
        expect(enumOptions['status'], isNotNull);

        expect(enumOptions['timeRange'], contains(TimeRangeFilter.today));
        expect(enumOptions['priority'], contains(PriorityFilter.high));
        expect(enumOptions['status'], contains(StatusFilter.active));
      });
    });

    group('State Actions Provider', () {
      test('should provide access to notifier methods', () {
        final actions = container.read(coachDashboardStateActionsProvider);
        expect(actions, isA<CoachDashboardStateNotifier>());

        actions.updateTimeRange('month');
        final state = container.read(coachDashboardStateProvider);
        expect(state.timeRange, equals('month'));
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

    test('should only rebuild dependent providers when their data changes', () {
      int timeRangeNotifications = 0;
      int priorityNotifications = 0;

      container.listen(
        timeRangeFilterProvider,
        (_, __) => timeRangeNotifications++,
      );

      container.listen(
        priorityFilterProvider,
        (_, __) => priorityNotifications++,
      );

      final notifier = container.read(coachDashboardStateProvider.notifier);

      // Update time range - should only notify timeRangeFilterProvider
      notifier.updateTimeRange('month');
      expect(timeRangeNotifications, equals(1));
      expect(priorityNotifications, equals(0));

      // Update priority - should only notify priorityFilterProvider
      notifier.updatePriority('high');
      expect(timeRangeNotifications, equals(1));
      expect(priorityNotifications, equals(1));
    });

    test('should handle rapid state updates correctly', () {
      final notifier = container.read(coachDashboardStateProvider.notifier);

      notifier.updateTimeRange('today');
      notifier.updatePriority('high');
      notifier.updateStatus('active');

      final state = container.read(coachDashboardStateProvider);
      expect(state.timeRange, equals('today'));
      expect(state.priority, equals('high'));
      expect(state.status, equals('active'));
    });

    test('should maintain consistency across multiple provider reads', () {
      final notifier = container.read(coachDashboardStateProvider.notifier);
      notifier.updateFilters(
        timeRange: 'month',
        priority: 'medium',
        status: 'scheduled',
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
      expect(state.timeRange, equals('week')); // Should remain default
      expect(state.priority, equals('all')); // Should remain default
      expect(state.status, equals('all')); // Should remain default
    });

    test('should handle multiple resets correctly', () {
      final notifier = container.read(coachDashboardStateProvider.notifier);

      notifier.updateFilters(
        timeRange: 'month',
        priority: 'high',
        status: 'active',
      );

      notifier.resetFilters();
      notifier.resetFilters(); // Multiple resets should be safe

      final state = container.read(coachDashboardStateProvider);
      expect(state.timeRange, equals('week'));
      expect(state.priority, equals('all'));
      expect(state.status, equals('all'));
    });

    test('should handle empty filter summary correctly', () {
      final notifier = container.read(coachDashboardStateProvider.notifier);
      expect(notifier.filterSummary, equals('All interventions'));

      // Even after updates and reset, should handle empty state
      notifier.updateTimeRange('month');
      notifier.resetFilters();
      expect(notifier.filterSummary, equals('All interventions'));
    });
  });
}
