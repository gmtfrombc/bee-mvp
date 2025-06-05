import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/coach_dashboard_filters.dart';

/// State notifier for managing coach dashboard filter state
///
/// This provider manages the filter state for the coach dashboard, including:
/// - Time range filter (24h, 7d, 30d)
/// - Priority filter (all, high, medium, low)
/// - Status filter (all, pending, in_progress, completed)
///
/// Uses immutable state updates with copyWith pattern for performance
class CoachDashboardStateNotifier extends StateNotifier<CoachDashboardFilters> {
  CoachDashboardStateNotifier() : super(const CoachDashboardFilters());

  // Performance: Track analytics for component usage
  final Map<String, int> _analyticsData = {
    'timeRangeChanges': 0,
    'priorityChanges': 0,
    'statusChanges': 0,
    'filterResets': 0,
    'batchUpdates': 0,
  };

  /// Get analytics data for performance monitoring
  Map<String, int> get analyticsData => Map.unmodifiable(_analyticsData);

  /// Update the time range filter
  ///
  /// [timeRange] - New time range value ('24h', '7d', '30d')
  void updateTimeRange(String timeRange) {
    // Performance: Only update if value actually changed
    if (state.timeRange != timeRange) {
      state = state.copyWith(timeRange: timeRange);
      _analyticsData['timeRangeChanges'] =
          (_analyticsData['timeRangeChanges'] ?? 0) + 1;
    }
  }

  /// Update the priority filter
  ///
  /// [priority] - New priority value ('all', 'high', 'medium', 'low')
  void updatePriority(String priority) {
    // Performance: Only update if value actually changed
    if (state.priority != priority) {
      state = state.copyWith(priority: priority);
      _analyticsData['priorityChanges'] =
          (_analyticsData['priorityChanges'] ?? 0) + 1;
    }
  }

  /// Update the status filter
  ///
  /// [status] - New status value ('all', 'pending', 'in_progress', 'completed')
  void updateStatus(String status) {
    // Performance: Only update if value actually changed
    if (state.status != status) {
      state = state.copyWith(status: status);
      _analyticsData['statusChanges'] =
          (_analyticsData['statusChanges'] ?? 0) + 1;
    }
  }

  /// Reset all filters to their default values
  void resetFilters() {
    state = const CoachDashboardFilters();
    _analyticsData['filterResets'] = (_analyticsData['filterResets'] ?? 0) + 1;
  }

  /// Update multiple filters at once
  ///
  /// More efficient than multiple individual updates for batch operations
  void updateFilters({String? timeRange, String? priority, String? status}) {
    // Performance: Only update if at least one value is different
    bool hasChanges = false;
    if (timeRange != null && state.timeRange != timeRange) hasChanges = true;
    if (priority != null && state.priority != priority) hasChanges = true;
    if (status != null && state.status != status) hasChanges = true;

    if (hasChanges) {
      state = state.copyWith(
        timeRange: timeRange,
        priority: priority,
        status: status,
      );
      _analyticsData['batchUpdates'] =
          (_analyticsData['batchUpdates'] ?? 0) + 1;
    }
  }

  /// Check if any non-default filters are active
  bool get hasActiveFilters => state.hasActiveFilters;

  /// Get display-friendly filter summary
  String get filterSummary {
    final List<String> activeFilters = [];

    if (!state.isDefaultTimeRange) {
      activeFilters.add(state.timeRangeDisplayName);
    }
    if (!state.isDefaultPriority) {
      activeFilters.add('${state.priorityDisplayName} priority');
    }
    if (!state.isDefaultStatus) {
      activeFilters.add('${state.statusDisplayName} status');
    }

    if (activeFilters.isEmpty) {
      return 'All interventions';
    }

    return activeFilters.join(', ');
  }

  /// Performance: Clear analytics data
  void clearAnalytics() {
    _analyticsData.clear();
  }
}

/// Main provider for coach dashboard state management
///
/// This is the primary provider for accessing and modifying dashboard filter state.
/// Use this provider to watch filter changes and trigger state updates.
final coachDashboardStateProvider =
    StateNotifierProvider<CoachDashboardStateNotifier, CoachDashboardFilters>((
      ref,
    ) {
      return CoachDashboardStateNotifier();
    });

/// Convenience providers for accessing specific filter values
///
/// These providers allow widgets to watch only the specific filter values they need,
/// minimizing unnecessary rebuilds when other filter values change.

/// Provider for the current time range filter value
/// Performance: Using select for granular updates
final timeRangeFilterProvider = Provider<String>((ref) {
  return ref.watch(
    coachDashboardStateProvider.select((state) => state.timeRange),
  );
});

/// Provider for the current priority filter value
/// Performance: Using select for granular updates
final priorityFilterProvider = Provider<String>((ref) {
  return ref.watch(
    coachDashboardStateProvider.select((state) => state.priority),
  );
});

/// Provider for the current status filter value
/// Performance: Using select for granular updates
final statusFilterProvider = Provider<String>((ref) {
  return ref.watch(coachDashboardStateProvider.select((state) => state.status));
});

/// Provider for checking if any filters are active
/// Performance: Using select for granular updates
final hasActiveFiltersProvider = Provider<bool>((ref) {
  return ref.watch(
    coachDashboardStateProvider.select((state) => state.hasActiveFilters),
  );
});

/// Provider for getting a display-friendly filter summary
/// Performance: Using select to only rebuild when relevant filters change
final filterSummaryProvider = Provider<String>((ref) {
  return ref
      .watch(
        coachDashboardStateProvider.select(
          (state) => '${state.timeRange}|${state.priority}|${state.status}',
        ),
      )
      .split('|')
      .let((parts) {
        final timeRange = parts[0];
        final priority = parts[1];
        final status = parts[2];

        final List<String> activeFilters = [];

        if (timeRange != '7d') {
          final displayName =
              timeRange == '24h'
                  ? 'Last 24 Hours'
                  : timeRange == '30d'
                  ? 'Last 30 Days'
                  : 'Last 7 Days';
          activeFilters.add(displayName);
        }
        if (priority != 'all') {
          final displayName =
              priority == 'high'
                  ? 'High Priority'
                  : priority == 'medium'
                  ? 'Medium Priority'
                  : priority == 'low'
                  ? 'Low Priority'
                  : 'All Priorities';
          activeFilters.add('$displayName priority');
        }
        if (status != 'all') {
          final displayName =
              status == 'pending'
                  ? 'Pending'
                  : status == 'in_progress'
                  ? 'In Progress'
                  : status == 'completed'
                  ? 'Completed'
                  : 'All Statuses';
          activeFilters.add('$displayName status');
        }

        return activeFilters.isEmpty
            ? 'All interventions'
            : activeFilters.join(', ');
      });
});

/// Extension for let operator
extension Let<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}

/// Provider for accessing the state notifier methods
///
/// Use this provider when you need to call methods on the notifier,
/// such as updating filters or resetting state.
final coachDashboardStateActionsProvider =
    Provider<CoachDashboardStateNotifier>((ref) {
      return ref.read(coachDashboardStateProvider.notifier);
    });

/// Provider for getting all available filter options
///
/// This provider returns the available options for each filter type,
/// useful for building filter UI components.
/// Performance: Using const values for immutable data
final filterOptionsProvider = Provider<Map<String, List<String>>>((ref) {
  return const {
    'timeRange': ['24h', '7d', '30d'],
    'priority': ['all', 'high', 'medium', 'low'],
    'status': ['all', 'pending', 'in_progress', 'completed'],
  };
});

/// Provider for getting enum-based filter options
///
/// This provider returns strongly-typed enum alternatives for filter values,
/// useful for type-safe filter operations.
/// Performance: Using const values for immutable data
final enumFilterOptionsProvider = Provider<Map<String, List<Object>>>((ref) {
  return const {
    'timeRange': TimeRangeFilter.values,
    'priority': PriorityFilter.values,
    'status': StatusFilter.values,
  };
});

/// Performance Analytics Provider
///
/// Provides access to usage analytics for monitoring component performance
final dashboardAnalyticsProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(coachDashboardStateProvider.notifier).analyticsData;
});

/// Performance: Auto-dispose provider for analytics that clears data when not watched
final autoDisposingAnalyticsProvider = Provider.autoDispose<Map<String, int>>((
  ref,
) {
  final analytics =
      ref.watch(coachDashboardStateProvider.notifier).analyticsData;

  // Performance: Clear analytics when provider is disposed
  ref.onDispose(() {
    ref.read(coachDashboardStateProvider.notifier).clearAnalytics();
  });

  return analytics;
});
