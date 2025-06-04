import 'package:flutter/foundation.dart';

/// Typed filter model for Coach Dashboard state management.
///
/// This immutable model represents the current filter state across all
/// dashboard tabs with type-safe filter values. It follows the established
/// domain model patterns with copyWith functionality for immutable updates.
///
/// Example usage:
/// ```dart
/// final filters = CoachDashboardFilters(
///   timeRange: TimeRange.week,
///   priority: InterventionPriority.high,
///   status: InterventionStatus.active,
/// );
///
/// final updatedFilters = filters.copyWith(
///   timeRange: TimeRange.month,
/// );
/// ```
@immutable
class CoachDashboardFilters {
  /// Creates a new instance of CoachDashboardFilters.
  ///
  /// Uses default values that match the current dashboard behavior:
  /// - timeRange: '7d' (7 days)
  /// - priority: 'all' (all priorities)
  /// - status: 'all' (all statuses)
  const CoachDashboardFilters({
    this.timeRange = '7d',
    this.priority = 'all',
    this.status = 'all',
  });

  /// The selected time range filter for overview and analytics tabs.
  ///
  /// Valid values: '24h', '7d', '30d'
  /// Default: '7d'
  final String timeRange;

  /// The selected priority filter for active interventions tab.
  ///
  /// Valid values: 'all', 'high', 'medium', 'low'
  /// Default: 'all'
  final String priority;

  /// The selected status filter for active interventions tab.
  ///
  /// Valid values: 'all', 'pending', 'in_progress', 'completed'
  /// Default: 'all'
  final String status;

  /// Creates a copy of this filter model with optional field updates.
  ///
  /// This method enables immutable updates to the filter state while
  /// preserving existing values for unchanged fields.
  ///
  /// Example:
  /// ```dart
  /// final newFilters = currentFilters.copyWith(
  ///   timeRange: '30d',
  ///   priority: 'high',
  /// );
  /// ```
  CoachDashboardFilters copyWith({
    String? timeRange,
    String? priority,
    String? status,
  }) {
    return CoachDashboardFilters(
      timeRange: timeRange ?? this.timeRange,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }

  /// Resets all filters to their default values.
  ///
  /// This is equivalent to creating a new instance with default parameters.
  ///
  /// Returns a new CoachDashboardFilters with:
  /// - timeRange: '7d'
  /// - priority: 'all'
  /// - status: 'all'
  CoachDashboardFilters reset() {
    return const CoachDashboardFilters();
  }

  /// Checks if the current filters have any non-default values applied.
  ///
  /// Returns true if any filter is set to a value other than its default,
  /// false if all filters are at their default values.
  bool get hasActiveFilters {
    return timeRange != '7d' || priority != 'all' || status != 'all';
  }

  /// Checks if time range filter is at its default value.
  bool get isDefaultTimeRange => timeRange == '7d';

  /// Checks if priority filter is at its default value.
  bool get isDefaultPriority => priority == 'all';

  /// Checks if status filter is at its default value.
  bool get isDefaultStatus => status == 'all';

  /// Gets a human-readable display name for the current time range.
  String get timeRangeDisplayName {
    switch (timeRange) {
      case '24h':
        return 'Last 24 Hours';
      case '7d':
        return 'Last 7 Days';
      case '30d':
        return 'Last 30 Days';
      default:
        return 'Unknown Range';
    }
  }

  /// Gets a human-readable display name for the current priority filter.
  String get priorityDisplayName {
    switch (priority) {
      case 'all':
        return 'All Priorities';
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
        return 'Low Priority';
      default:
        return 'Unknown Priority';
    }
  }

  /// Gets a human-readable display name for the current status filter.
  String get statusDisplayName {
    switch (status) {
      case 'all':
        return 'All Statuses';
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown Status';
    }
  }

  /// JSON serialization support for potential future state persistence.
  ///
  /// Converts the filter model to a Map for JSON serialization.
  Map<String, dynamic> toJson() {
    return {'timeRange': timeRange, 'priority': priority, 'status': status};
  }

  /// JSON deserialization support for potential future state persistence.
  ///
  /// Creates a CoachDashboardFilters instance from a JSON Map with
  /// proper validation and fallback to default values.
  factory CoachDashboardFilters.fromJson(Map<String, dynamic> json) {
    // Helper function to safely extract string values with defaults
    String safeGetString(String key, String defaultValue) {
      final value = json[key];
      return (value is String) ? value : defaultValue;
    }

    return CoachDashboardFilters(
      timeRange: safeGetString('timeRange', '7d'),
      priority: safeGetString('priority', 'all'),
      status: safeGetString('status', 'all'),
    );
  }

  /// Equality comparison for filter instances.
  ///
  /// Returns true if all filter values are identical between instances.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoachDashboardFilters &&
        other.timeRange == timeRange &&
        other.priority == priority &&
        other.status == status;
  }

  /// Hash code implementation for use in collections and maps.
  @override
  int get hashCode {
    return Object.hash(timeRange, priority, status);
  }

  /// String representation for debugging and logging.
  @override
  String toString() {
    return 'CoachDashboardFilters('
        'timeRange: $timeRange, '
        'priority: $priority, '
        'status: $status'
        ')';
  }
}

/// Enumeration of valid time range filter values for type safety.
///
/// This enum provides compile-time validation for time range values
/// and can be used as an alternative to string-based filtering.
enum TimeRangeFilter {
  /// Last 24 hours
  day('24h', 'Last 24 Hours'),

  /// Last 7 days (default)
  week('7d', 'Last 7 Days'),

  /// Last 30 days
  month('30d', 'Last 30 Days');

  const TimeRangeFilter(this.value, this.displayName);

  /// The string value used in the filter model
  final String value;

  /// Human-readable display name
  final String displayName;

  /// Creates a TimeRangeFilter from a string value
  static TimeRangeFilter fromValue(String value) {
    switch (value) {
      case '24h':
        return TimeRangeFilter.day;
      case '7d':
        return TimeRangeFilter.week;
      case '30d':
        return TimeRangeFilter.month;
      default:
        return TimeRangeFilter.week; // Default fallback
    }
  }
}

/// Enumeration of valid priority filter values for type safety.
///
/// This enum provides compile-time validation for priority values
/// and can be used as an alternative to string-based filtering.
enum PriorityFilter {
  /// All priority levels (default)
  all('all', 'All Priorities'),

  /// High priority interventions
  high('high', 'High Priority'),

  /// Medium priority interventions
  medium('medium', 'Medium Priority'),

  /// Low priority interventions
  low('low', 'Low Priority');

  const PriorityFilter(this.value, this.displayName);

  /// The string value used in the filter model
  final String value;

  /// Human-readable display name
  final String displayName;

  /// Creates a PriorityFilter from a string value
  static PriorityFilter fromValue(String value) {
    switch (value) {
      case 'all':
        return PriorityFilter.all;
      case 'high':
        return PriorityFilter.high;
      case 'medium':
        return PriorityFilter.medium;
      case 'low':
        return PriorityFilter.low;
      default:
        return PriorityFilter.all; // Default fallback
    }
  }
}

/// Enumeration of valid status filter values for type safety.
///
/// This enum provides compile-time validation for status values
/// and can be used as an alternative to string-based filtering.
enum StatusFilter {
  /// All status types (default)
  all('all', 'All Statuses'),

  /// Pending interventions
  pending('pending', 'Pending'),

  /// In progress interventions
  inProgress('in_progress', 'In Progress'),

  /// Completed interventions
  completed('completed', 'Completed');

  const StatusFilter(this.value, this.displayName);

  /// The string value used in the filter model
  final String value;

  /// Human-readable display name
  final String displayName;

  /// Creates a StatusFilter from a string value
  static StatusFilter fromValue(String value) {
    switch (value) {
      case 'all':
        return StatusFilter.all;
      case 'pending':
        return StatusFilter.pending;
      case 'in_progress':
        return StatusFilter.inProgress;
      case 'completed':
        return StatusFilter.completed;
      default:
        return StatusFilter.all; // Default fallback
    }
  }
}
