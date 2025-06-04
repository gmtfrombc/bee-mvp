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

  /// Update the time range filter
  ///
  /// [timeRange] - New time range value ('24h', '7d', '30d')
  void updateTimeRange(String timeRange) {
    state = state.copyWith(timeRange: timeRange);
  }

  /// Update the priority filter
  ///
  /// [priority] - New priority value ('all', 'high', 'medium', 'low')
  void updatePriority(String priority) {
    state = state.copyWith(priority: priority);
  }

  /// Update the status filter
  ///
  /// [status] - New status value ('all', 'pending', 'in_progress', 'completed')
  void updateStatus(String status) {
    state = state.copyWith(status: status);
  }

  /// Reset all filters to their default values
  void resetFilters() {
    state = const CoachDashboardFilters();
  }

  /// Update multiple filters at once
  ///
  /// More efficient than multiple individual updates for batch operations
  void updateFilters({String? timeRange, String? priority, String? status}) {
    state = state.copyWith(
      timeRange: timeRange,
      priority: priority,
      status: status,
    );
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
final timeRangeFilterProvider = Provider<String>((ref) {
  return ref.watch(coachDashboardStateProvider).timeRange;
});

/// Provider for the current priority filter value
final priorityFilterProvider = Provider<String>((ref) {
  return ref.watch(coachDashboardStateProvider).priority;
});

/// Provider for the current status filter value
final statusFilterProvider = Provider<String>((ref) {
  return ref.watch(coachDashboardStateProvider).status;
});

/// Provider for checking if any filters are active
final hasActiveFiltersProvider = Provider<bool>((ref) {
  return ref.watch(coachDashboardStateProvider).hasActiveFilters;
});

/// Provider for getting a display-friendly filter summary
final filterSummaryProvider = Provider<String>((ref) {
  return ref.read(coachDashboardStateProvider.notifier).filterSummary;
});

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
final filterOptionsProvider = Provider<Map<String, List<String>>>((ref) {
  return {
    'timeRange': ['24h', '7d', '30d'],
    'priority': ['all', 'high', 'medium', 'low'],
    'status': ['all', 'pending', 'in_progress', 'completed'],
  };
});

/// Provider for getting enum-based filter options
///
/// This provider returns strongly-typed enum alternatives for filter values,
/// useful for type-safe filter operations.
final enumFilterOptionsProvider = Provider<Map<String, List<Object>>>((ref) {
  return {
    'timeRange': TimeRangeFilter.values,
    'priority': PriorityFilter.values,
    'status': StatusFilter.values,
  };
});
