import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/services/wearable_edge_case_logger.dart';

void main() {
  group('WearableEdgeCaseLogger - Core Business Logic Tests', () {
    late WearableEdgeCaseLogger logger;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // Create logger without repository to test core functionality
      logger = WearableEdgeCaseLogger();
    });

    test('happy path - initialization works correctly', () async {
      // Act
      final result = await logger.initialize();

      // Assert
      expect(result, isTrue);
    });

    test('happy path - edge case enum contains all required types', () {
      // Assert - Verify all required edge cases are defined
      expect(WearableEdgeCase.values.length, equals(5));
      expect(
        WearableEdgeCase.values,
        contains(WearableEdgeCase.permissionRevoked),
      );
      expect(WearableEdgeCase.values, contains(WearableEdgeCase.airplaneMode));
      expect(
        WearableEdgeCase.values,
        contains(WearableEdgeCase.timestampDrift),
      );
      expect(
        WearableEdgeCase.values,
        contains(WearableEdgeCase.healthConnectUnavailable),
      );
      expect(
        WearableEdgeCase.values,
        contains(WearableEdgeCase.backgroundSyncFailure),
      );
    });

    test('happy path - edge case log entry serialization works correctly', () {
      // Arrange
      final entry = EdgeCaseLogEntry(
        id: 'test_123',
        type: WearableEdgeCase.timestampDrift,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        context: {'drift_minutes': 10, 'threshold': 5},
        description: 'Timestamp drift detected',
      );

      // Act
      final json = entry.toJson();
      final restored = EdgeCaseLogEntry.fromJson(json);

      // Assert
      expect(restored.id, equals('test_123'));
      expect(restored.type, equals(WearableEdgeCase.timestampDrift));
      expect(restored.description, equals('Timestamp drift detected'));
      expect(restored.context['drift_minutes'], equals(10));
      expect(restored.context['threshold'], equals(5));
      expect(restored.timestamp, equals(DateTime(2024, 1, 1, 12, 0, 0)));
    });

    test('edge case - operations work when not initialized', () async {
      // Act & Assert - Should not throw, should handle gracefully
      expect(await logger.getRecentLogs(), isEmpty);

      // These should return early without throwing
      await logger.checkPermissionRevocation();
      await logger.checkConnectivityIssues();
      await logger.checkTimestampDrift();
      await logger.checkHealthConnectAvailability();
    });

    test('happy path - timestamp drift detection logic', () async {
      // Arrange
      await logger.initialize();
      final serverTime = DateTime.now().subtract(const Duration(minutes: 10));

      // Act
      await logger.checkTimestampDrift(serverTime: serverTime);
      final logs = await logger.getRecentLogs();

      // Assert
      expect(logs.length, equals(1));
      expect(logs.first.type, equals(WearableEdgeCase.timestampDrift));
      expect(logs.first.description, contains('drift'));
      expect(logs.first.context['drift_minutes'], equals(10));
    });

    test('edge case - no timestamp drift when under threshold', () async {
      // Arrange
      await logger.initialize();
      final serverTime = DateTime.now().subtract(const Duration(minutes: 2));

      // Act
      await logger.checkTimestampDrift(serverTime: serverTime);
      final logs = await logger.getRecentLogs();

      // Assert - No logs should be created for drift under threshold
      expect(logs, isEmpty);
    });

    test('happy path - mitigation report generation', () async {
      // Arrange
      await logger.initialize();

      // Act
      final report = await logger.generateMitigationReport();

      // Assert
      expect(report, containsPair('period', '7 days'));
      expect(report, containsPair('total_edge_cases', 0));
      expect(report, contains('summary_by_type'));
      expect(report, contains('mitigation_tickets'));
      expect(report['summary_by_type'], isA<Map>());
      expect(report['mitigation_tickets'], isA<List>());
    });

    test(
      'edge case - comprehensive check handles uninitialized state',
      () async {
        // Act & Assert - Should not throw
        await logger.performComprehensiveCheck();

        // Should complete without errors
        expect(true, isTrue); // Test completion marker
      },
    );

    test('edge case - invalid edge case type deserialization fallback', () {
      // Arrange
      final invalidJson = {
        'id': 'test_invalid',
        'type': 'non_existent_type',
        'timestamp': DateTime.now().toIso8601String(),
        'context': {'test': 'data'},
        'description': 'Invalid type test',
      };

      // Act
      final entry = EdgeCaseLogEntry.fromJson(invalidJson);

      // Assert - Should fall back to backgroundSyncFailure
      expect(entry.type, equals(WearableEdgeCase.backgroundSyncFailure));
      expect(entry.id, equals('test_invalid'));
      expect(entry.description, equals('Invalid type test'));
    });

    test('happy path - background sync failure logging', () async {
      // Arrange
      await logger.initialize();

      // Act
      await logger.logBackgroundSyncFailure(
        'Network timeout error',
        additionalContext: {
          'retry_count': 3,
          'last_sync': '2024-01-01T10:00:00Z',
        },
      );

      final logs = await logger.getRecentLogs();

      // Assert
      expect(logs.length, equals(1));
      expect(logs.first.type, equals(WearableEdgeCase.backgroundSyncFailure));
      expect(logs.first.context['error'], equals('Network timeout error'));
      expect(logs.first.context['retry_count'], equals(3));
      expect(logs.first.context['last_sync'], equals('2024-01-01T10:00:00Z'));
      expect(logs.first.context, contains('sync_time'));
    });

    test('happy path - log filtering by type and time', () async {
      // Arrange
      await logger.initialize();

      // Add different types of logs
      await logger.logBackgroundSyncFailure('Error 1');
      await logger.checkTimestampDrift(
        serverTime: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      // Act & Assert - Filter by type
      final syncLogs = await logger.getRecentLogs(
        filterType: WearableEdgeCase.backgroundSyncFailure,
      );
      expect(syncLogs.length, equals(1));
      expect(
        syncLogs.first.type,
        equals(WearableEdgeCase.backgroundSyncFailure),
      );

      final driftLogs = await logger.getRecentLogs(
        filterType: WearableEdgeCase.timestampDrift,
      );
      expect(driftLogs.length, equals(1));
      expect(driftLogs.first.type, equals(WearableEdgeCase.timestampDrift));

      // All logs
      final allLogs = await logger.getRecentLogs();
      expect(allLogs.length, equals(2));
    });
  });
}
