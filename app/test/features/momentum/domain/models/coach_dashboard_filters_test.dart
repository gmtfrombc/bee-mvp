import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/momentum/domain/models/coach_dashboard_filters.dart';

void main() {
  group('CoachDashboardFilters Model Tests', () {
    late CoachDashboardFilters defaultFilters;
    late CoachDashboardFilters customFilters;

    setUp(() {
      defaultFilters = const CoachDashboardFilters();
      customFilters = const CoachDashboardFilters(
        timeRange: '30d',
        priority: 'high',
        status: 'in_progress',
      );
    });

    group('CoachDashboardFilters Construction', () {
      test('should create instance with default values', () {
        expect(defaultFilters.timeRange, equals('7d'));
        expect(defaultFilters.priority, equals('all'));
        expect(defaultFilters.status, equals('all'));
      });

      test('should create instance with custom values', () {
        expect(customFilters.timeRange, equals('30d'));
        expect(customFilters.priority, equals('high'));
        expect(customFilters.status, equals('in_progress'));
      });

      test('should create instance with partial custom values', () {
        final partial = const CoachDashboardFilters(timeRange: '24h');

        expect(partial.timeRange, equals('24h'));
        expect(partial.priority, equals('all'));
        expect(partial.status, equals('all'));
      });

      test('should be immutable (all fields final)', () {
        // This test verifies that the fields cannot be changed after construction
        expect(defaultFilters.timeRange, equals('7d'));
        expect(defaultFilters.priority, equals('all'));
        expect(defaultFilters.status, equals('all'));

        // Fields should remain the same (immutable)
        expect(defaultFilters.timeRange, equals('7d'));
        expect(defaultFilters.priority, equals('all'));
        expect(defaultFilters.status, equals('all'));
      });
    });

    group('CopyWith Method', () {
      test('should copy with single field change', () {
        final copied = defaultFilters.copyWith(timeRange: '30d');

        expect(copied.timeRange, equals('30d'));
        expect(copied.priority, equals('all'));
        expect(copied.status, equals('all'));
      });

      test('should copy with multiple field changes', () {
        final copied = defaultFilters.copyWith(
          timeRange: '24h',
          priority: 'high',
          status: 'pending',
        );

        expect(copied.timeRange, equals('24h'));
        expect(copied.priority, equals('high'));
        expect(copied.status, equals('pending'));
      });

      test('should copy with no changes when no parameters provided', () {
        final copied = customFilters.copyWith();

        expect(copied.timeRange, equals('30d'));
        expect(copied.priority, equals('high'));
        expect(copied.status, equals('in_progress'));
      });

      test('should copy with null values maintaining existing values', () {
        final copied = customFilters.copyWith(
          timeRange: null,
          priority: 'medium',
          status: null,
        );

        expect(copied.timeRange, equals('30d')); // Unchanged
        expect(copied.priority, equals('medium')); // Changed
        expect(copied.status, equals('in_progress')); // Unchanged
      });

      test('should create new instance (not mutate original)', () {
        final original = const CoachDashboardFilters(timeRange: '7d');
        final copied = original.copyWith(timeRange: '30d');

        expect(original.timeRange, equals('7d'));
        expect(copied.timeRange, equals('30d'));
        expect(identical(original, copied), isFalse);
      });
    });

    group('Reset Method', () {
      test('should reset all filters to default values', () {
        final reset = customFilters.reset();

        expect(reset.timeRange, equals('7d'));
        expect(reset.priority, equals('all'));
        expect(reset.status, equals('all'));
      });

      test('should return new instance equivalent to default constructor', () {
        final reset = customFilters.reset();
        final defaultInstance = const CoachDashboardFilters();

        expect(reset, equals(defaultInstance));
      });

      test('should not mutate original instance', () {
        final original = customFilters;
        final reset = original.reset();

        expect(original.timeRange, equals('30d'));
        expect(original.priority, equals('high'));
        expect(original.status, equals('in_progress'));

        expect(reset.timeRange, equals('7d'));
        expect(reset.priority, equals('all'));
        expect(reset.status, equals('all'));
      });
    });

    group('Filter State Detection', () {
      test('should detect active filters correctly', () {
        expect(defaultFilters.hasActiveFilters, isFalse);
        expect(customFilters.hasActiveFilters, isTrue);

        final partialFilters = const CoachDashboardFilters(timeRange: '24h');
        expect(partialFilters.hasActiveFilters, isTrue);
      });

      test('should detect default values correctly', () {
        expect(defaultFilters.isDefaultTimeRange, isTrue);
        expect(defaultFilters.isDefaultPriority, isTrue);
        expect(defaultFilters.isDefaultStatus, isTrue);

        expect(customFilters.isDefaultTimeRange, isFalse);
        expect(customFilters.isDefaultPriority, isFalse);
        expect(customFilters.isDefaultStatus, isFalse);
      });

      test('should detect mixed default and custom values', () {
        final mixed = const CoachDashboardFilters(
          timeRange: '7d', // Default
          priority: 'high', // Custom
          status: 'all', // Default
        );

        expect(mixed.hasActiveFilters, isTrue);
        expect(mixed.isDefaultTimeRange, isTrue);
        expect(mixed.isDefaultPriority, isFalse);
        expect(mixed.isDefaultStatus, isTrue);
      });
    });

    group('Display Name Methods', () {
      test('should return correct time range display names', () {
        final filter24h = const CoachDashboardFilters(timeRange: '24h');
        final filter7d = const CoachDashboardFilters(timeRange: '7d');
        final filter30d = const CoachDashboardFilters(timeRange: '30d');
        final filterInvalid = const CoachDashboardFilters(timeRange: 'invalid');

        expect(filter24h.timeRangeDisplayName, equals('Last 24 Hours'));
        expect(filter7d.timeRangeDisplayName, equals('Last 7 Days'));
        expect(filter30d.timeRangeDisplayName, equals('Last 30 Days'));
        expect(filterInvalid.timeRangeDisplayName, equals('Unknown Range'));
      });

      test('should return correct priority display names', () {
        final filterAll = const CoachDashboardFilters(priority: 'all');
        final filterHigh = const CoachDashboardFilters(priority: 'high');
        final filterMedium = const CoachDashboardFilters(priority: 'medium');
        final filterLow = const CoachDashboardFilters(priority: 'low');
        final filterInvalid = const CoachDashboardFilters(priority: 'invalid');

        expect(filterAll.priorityDisplayName, equals('All Priorities'));
        expect(filterHigh.priorityDisplayName, equals('High Priority'));
        expect(filterMedium.priorityDisplayName, equals('Medium Priority'));
        expect(filterLow.priorityDisplayName, equals('Low Priority'));
        expect(filterInvalid.priorityDisplayName, equals('Unknown Priority'));
      });

      test('should return correct status display names', () {
        final filterAll = const CoachDashboardFilters(status: 'all');
        final filterPending = const CoachDashboardFilters(status: 'pending');
        final filterInProgress = const CoachDashboardFilters(
          status: 'in_progress',
        );
        final filterCompleted = const CoachDashboardFilters(
          status: 'completed',
        );
        final filterInvalid = const CoachDashboardFilters(status: 'invalid');

        expect(filterAll.statusDisplayName, equals('All Statuses'));
        expect(filterPending.statusDisplayName, equals('Pending'));
        expect(filterInProgress.statusDisplayName, equals('In Progress'));
        expect(filterCompleted.statusDisplayName, equals('Completed'));
        expect(filterInvalid.statusDisplayName, equals('Unknown Status'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly with default values', () {
        final json = defaultFilters.toJson();

        expect(json['timeRange'], equals('7d'));
        expect(json['priority'], equals('all'));
        expect(json['status'], equals('all'));
        expect(json.keys.length, equals(3));
      });

      test('should serialize to JSON correctly with custom values', () {
        final json = customFilters.toJson();

        expect(json['timeRange'], equals('30d'));
        expect(json['priority'], equals('high'));
        expect(json['status'], equals('in_progress'));
        expect(json.keys.length, equals(3));
      });

      test('should include all required fields in JSON', () {
        final json = defaultFilters.toJson();

        expect(json.containsKey('timeRange'), isTrue);
        expect(json.containsKey('priority'), isTrue);
        expect(json.containsKey('status'), isTrue);
      });
    });

    group('JSON Deserialization', () {
      test('should deserialize from JSON correctly with all fields', () {
        final json = {
          'timeRange': '24h',
          'priority': 'medium',
          'status': 'pending',
        };

        final filters = CoachDashboardFilters.fromJson(json);

        expect(filters.timeRange, equals('24h'));
        expect(filters.priority, equals('medium'));
        expect(filters.status, equals('pending'));
      });

      test('should deserialize with default values for missing fields', () {
        final json = <String, dynamic>{};

        final filters = CoachDashboardFilters.fromJson(json);

        expect(filters.timeRange, equals('7d'));
        expect(filters.priority, equals('all'));
        expect(filters.status, equals('all'));
      });

      test('should deserialize with partial fields', () {
        final json = {
          'timeRange': '30d',
          'priority': 'high',
          // Missing status field
        };

        final filters = CoachDashboardFilters.fromJson(json);

        expect(filters.timeRange, equals('30d'));
        expect(filters.priority, equals('high'));
        expect(filters.status, equals('all')); // Default value
      });

      test('should handle null values gracefully', () {
        final json = {'timeRange': null, 'priority': 'low', 'status': null};

        final filters = CoachDashboardFilters.fromJson(json);

        expect(filters.timeRange, equals('7d')); // Default value
        expect(filters.priority, equals('low'));
        expect(filters.status, equals('all')); // Default value
      });

      test('should handle invalid types gracefully', () {
        final json = {
          'timeRange': 123, // Invalid type
          'priority': 'medium',
          'status': [], // Invalid type
        };

        final filters = CoachDashboardFilters.fromJson(json);

        expect(filters.timeRange, equals('7d')); // Default value
        expect(filters.priority, equals('medium'));
        expect(filters.status, equals('all')); // Default value
      });

      test('should round-trip JSON serialization correctly', () {
        final original = customFilters;
        final json = original.toJson();
        final deserialized = CoachDashboardFilters.fromJson(json);

        expect(deserialized, equals(original));
        expect(deserialized.timeRange, equals(original.timeRange));
        expect(deserialized.priority, equals(original.priority));
        expect(deserialized.status, equals(original.status));
      });
    });

    group('Equality and HashCode', () {
      test('should be equal for instances with same values', () {
        final filters1 = const CoachDashboardFilters(
          timeRange: '30d',
          priority: 'high',
          status: 'pending',
        );
        final filters2 = const CoachDashboardFilters(
          timeRange: '30d',
          priority: 'high',
          status: 'pending',
        );

        expect(filters1, equals(filters2));
        expect(filters1.hashCode, equals(filters2.hashCode));
      });

      test('should not be equal for instances with different values', () {
        final filters1 = const CoachDashboardFilters(timeRange: '7d');
        final filters2 = const CoachDashboardFilters(timeRange: '30d');

        expect(filters1, isNot(equals(filters2)));
        expect(filters1.hashCode, isNot(equals(filters2.hashCode)));
      });

      test('should be equal for default instances', () {
        final filters1 = const CoachDashboardFilters();
        final filters2 = const CoachDashboardFilters();

        expect(filters1, equals(filters2));
        expect(filters1.hashCode, equals(filters2.hashCode));
      });

      test('should handle identical instances correctly', () {
        final filters = defaultFilters;
        expect(identical(filters, filters), isTrue);
        expect(filters == filters, isTrue);
      });

      test('should not be equal to null or different types', () {
        expect(defaultFilters == null, isFalse);
        expect(defaultFilters.hashCode == null.hashCode, isFalse);
      });
    });

    group('ToString Method', () {
      test('should provide readable string representation', () {
        final str = defaultFilters.toString();

        expect(str, contains('CoachDashboardFilters'));
        expect(str, contains('timeRange: 7d'));
        expect(str, contains('priority: all'));
        expect(str, contains('status: all'));
      });

      test('should include all field values in string', () {
        final str = customFilters.toString();

        expect(str, contains('timeRange: 30d'));
        expect(str, contains('priority: high'));
        expect(str, contains('status: in_progress'));
      });

      test('should be useful for debugging', () {
        final str = customFilters.toString();

        // Should be in a format that helps debugging
        expect(str.startsWith('CoachDashboardFilters('), isTrue);
        expect(str.endsWith(')'), isTrue);
        expect(str.contains(', '), isTrue); // Multiple fields separated
      });
    });
  });

  group('TimeRangeFilter Enum Tests', () {
    test('should have correct values and display names', () {
      expect(TimeRangeFilter.day.value, equals('24h'));
      expect(TimeRangeFilter.day.displayName, equals('Last 24 Hours'));

      expect(TimeRangeFilter.week.value, equals('7d'));
      expect(TimeRangeFilter.week.displayName, equals('Last 7 Days'));

      expect(TimeRangeFilter.month.value, equals('30d'));
      expect(TimeRangeFilter.month.displayName, equals('Last 30 Days'));
    });

    test('should create from valid string values', () {
      expect(TimeRangeFilter.fromValue('24h'), equals(TimeRangeFilter.day));
      expect(TimeRangeFilter.fromValue('7d'), equals(TimeRangeFilter.week));
      expect(TimeRangeFilter.fromValue('30d'), equals(TimeRangeFilter.month));
    });

    test('should fallback to default for invalid values', () {
      expect(
        TimeRangeFilter.fromValue('invalid'),
        equals(TimeRangeFilter.week),
      );
      expect(TimeRangeFilter.fromValue(''), equals(TimeRangeFilter.week));
      expect(TimeRangeFilter.fromValue('1d'), equals(TimeRangeFilter.week));
    });
  });

  group('PriorityFilter Enum Tests', () {
    test('should have correct values and display names', () {
      expect(PriorityFilter.all.value, equals('all'));
      expect(PriorityFilter.all.displayName, equals('All Priorities'));

      expect(PriorityFilter.high.value, equals('high'));
      expect(PriorityFilter.high.displayName, equals('High Priority'));

      expect(PriorityFilter.medium.value, equals('medium'));
      expect(PriorityFilter.medium.displayName, equals('Medium Priority'));

      expect(PriorityFilter.low.value, equals('low'));
      expect(PriorityFilter.low.displayName, equals('Low Priority'));
    });

    test('should create from valid string values', () {
      expect(PriorityFilter.fromValue('all'), equals(PriorityFilter.all));
      expect(PriorityFilter.fromValue('high'), equals(PriorityFilter.high));
      expect(PriorityFilter.fromValue('medium'), equals(PriorityFilter.medium));
      expect(PriorityFilter.fromValue('low'), equals(PriorityFilter.low));
    });

    test('should fallback to default for invalid values', () {
      expect(PriorityFilter.fromValue('invalid'), equals(PriorityFilter.all));
      expect(PriorityFilter.fromValue(''), equals(PriorityFilter.all));
      expect(PriorityFilter.fromValue('urgent'), equals(PriorityFilter.all));
    });
  });

  group('StatusFilter Enum Tests', () {
    test('should have correct values and display names', () {
      expect(StatusFilter.all.value, equals('all'));
      expect(StatusFilter.all.displayName, equals('All Statuses'));

      expect(StatusFilter.pending.value, equals('pending'));
      expect(StatusFilter.pending.displayName, equals('Pending'));

      expect(StatusFilter.inProgress.value, equals('in_progress'));
      expect(StatusFilter.inProgress.displayName, equals('In Progress'));

      expect(StatusFilter.completed.value, equals('completed'));
      expect(StatusFilter.completed.displayName, equals('Completed'));
    });

    test('should create from valid string values', () {
      expect(StatusFilter.fromValue('all'), equals(StatusFilter.all));
      expect(StatusFilter.fromValue('pending'), equals(StatusFilter.pending));
      expect(
        StatusFilter.fromValue('in_progress'),
        equals(StatusFilter.inProgress),
      );
      expect(
        StatusFilter.fromValue('completed'),
        equals(StatusFilter.completed),
      );
    });

    test('should fallback to default for invalid values', () {
      expect(StatusFilter.fromValue('invalid'), equals(StatusFilter.all));
      expect(StatusFilter.fromValue(''), equals(StatusFilter.all));
      expect(StatusFilter.fromValue('active'), equals(StatusFilter.all));
    });
  });

  group('Integration Tests', () {
    test('should work with enum conversion round-trip', () {
      final filters = const CoachDashboardFilters(
        timeRange: '24h',
        priority: 'high',
        status: 'pending',
      );

      final timeEnum = TimeRangeFilter.fromValue(filters.timeRange);
      final priorityEnum = PriorityFilter.fromValue(filters.priority);
      final statusEnum = StatusFilter.fromValue(filters.status);

      expect(timeEnum.value, equals(filters.timeRange));
      expect(priorityEnum.value, equals(filters.priority));
      expect(statusEnum.value, equals(filters.status));
    });

    test('should maintain data integrity through serialization', () {
      final original = const CoachDashboardFilters(
        timeRange: '30d',
        priority: 'medium',
        status: 'in_progress',
      );

      // JSON round-trip
      final json = original.toJson();
      final fromJson = CoachDashboardFilters.fromJson(json);

      // copyWith round-trip
      final copied = original.copyWith();

      expect(fromJson, equals(original));
      expect(copied, equals(original));
      expect(fromJson.hashCode, equals(original.hashCode));
      expect(copied.hashCode, equals(original.hashCode));
    });

    test('should work with all possible enum combinations', () {
      for (final timeRange in ['24h', '7d', '30d']) {
        for (final priority in ['all', 'high', 'medium', 'low']) {
          for (final status in ['all', 'pending', 'in_progress', 'completed']) {
            final filters = CoachDashboardFilters(
              timeRange: timeRange,
              priority: priority,
              status: status,
            );

            // Should create successfully
            expect(filters.timeRange, equals(timeRange));
            expect(filters.priority, equals(priority));
            expect(filters.status, equals(status));

            // Should serialize/deserialize correctly
            final json = filters.toJson();
            final deserialized = CoachDashboardFilters.fromJson(json);
            expect(deserialized, equals(filters));
          }
        }
      }
    });
  });
}
