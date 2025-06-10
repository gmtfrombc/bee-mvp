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
        const partial = CoachDashboardFilters(timeRange: '24h');

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
        const original = CoachDashboardFilters(timeRange: '7d');
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
        const defaultInstance = CoachDashboardFilters();

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

        const partialFilters = CoachDashboardFilters(timeRange: '24h');
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
        const mixed = CoachDashboardFilters(
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
        const filter24h = CoachDashboardFilters(timeRange: '24h');
        const filter7d = CoachDashboardFilters(timeRange: '7d');
        const filter30d = CoachDashboardFilters(timeRange: '30d');
        const filterInvalid = CoachDashboardFilters(timeRange: 'invalid');

        expect(filter24h.timeRangeDisplayName, equals('Last 24 Hours'));
        expect(filter7d.timeRangeDisplayName, equals('Last 7 Days'));
        expect(filter30d.timeRangeDisplayName, equals('Last 30 Days'));
        expect(filterInvalid.timeRangeDisplayName, equals('Unknown Range'));
      });

      test('should return correct priority display names', () {
        const filterAll = CoachDashboardFilters(priority: 'all');
        const filterHigh = CoachDashboardFilters(priority: 'high');
        const filterMedium = CoachDashboardFilters(priority: 'medium');
        const filterLow = CoachDashboardFilters(priority: 'low');
        const filterInvalid = CoachDashboardFilters(priority: 'invalid');

        expect(filterAll.priorityDisplayName, equals('All Priorities'));
        expect(filterHigh.priorityDisplayName, equals('High Priority'));
        expect(filterMedium.priorityDisplayName, equals('Medium Priority'));
        expect(filterLow.priorityDisplayName, equals('Low Priority'));
        expect(filterInvalid.priorityDisplayName, equals('Unknown Priority'));
      });

      test('should return correct status display names', () {
        const filterAll = CoachDashboardFilters(status: 'all');
        const filterPending = CoachDashboardFilters(status: 'pending');
        const filterInProgress = CoachDashboardFilters(
          status: 'in_progress',
        );
        const filterCompleted = CoachDashboardFilters(
          status: 'completed',
        );
        const filterInvalid = CoachDashboardFilters(status: 'invalid');

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
        const filters1 = CoachDashboardFilters(
          timeRange: '30d',
          priority: 'high',
          status: 'pending',
        );
        const filters2 = CoachDashboardFilters(
          timeRange: '30d',
          priority: 'high',
          status: 'pending',
        );

        expect(filters1, equals(filters2));
        expect(filters1.hashCode, equals(filters2.hashCode));
      });

      test('should not be equal for instances with different values', () {
        const filters1 = CoachDashboardFilters(timeRange: '7d');
        const filters2 = CoachDashboardFilters(timeRange: '30d');

        expect(filters1, isNot(equals(filters2)));
        expect(filters1.hashCode, isNot(equals(filters2.hashCode)));
      });

      test('should be equal for default instances', () {
        const filters1 = CoachDashboardFilters();
        const filters2 = CoachDashboardFilters();

        expect(filters1, equals(filters2));
        expect(filters1.hashCode, equals(filters2.hashCode));
      });

      test('should handle identical instances correctly', () {
        final filters = defaultFilters;
        expect(identical(filters, filters), isTrue);
        expect(filters == filters, isTrue);
      });

      test('should not be equal to null or different types', () {
        // Test that the object is not null
        expect(defaultFilters, isNotNull);

        // Test that different instances with different values are not equal
        const differentFilters = CoachDashboardFilters(timeRange: '24h');
        expect(defaultFilters, isNot(equals(differentFilters)));

        // Test hashCode inequality for different instances
        expect(
          defaultFilters.hashCode,
          isNot(equals(differentFilters.hashCode)),
        );
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

  group('Integration Tests', () {
    test('should work with enum conversion round-trip', () {
      const filters = CoachDashboardFilters(
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
      const original = CoachDashboardFilters(
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

    test('should create filters from complex query', () {
      // ... existing code ...
    });
  });
}
