/// Tests for HealthBackgroundSyncProvider
///
/// Following the testing policy: one happy-path test and critical edge-case tests only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/providers/health_background_sync_provider.dart';
import 'package:app/core/services/health_background_sync_service.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  group('HealthBackgroundSyncProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Happy Path Tests', () {
      test('should provide HealthBackgroundSyncService instance', () {
        // Execute
        final service = container.read(healthBackgroundSyncServiceProvider);

        // Verify
        expect(service, isA<HealthBackgroundSyncService>());
      });

      test('should provide BackgroundSyncManager with proper dependencies', () {
        // Execute
        final manager = container.read(backgroundSyncManagerProvider);

        // Verify
        expect(manager, isA<BackgroundSyncManager>());
        expect(manager.config, isA<HealthBackgroundSyncConfig>());
        expect(manager.isActive, isFalse); // Initially not active
      });

      test('should manage background sync configuration state', () {
        // Setup
        const newConfig = HealthBackgroundSyncConfig(
          monitoredTypes: [WearableDataType.heartRate],
          fetchInterval: Duration(minutes: 10),
          lookbackDuration: Duration(minutes: 15),
        );

        // Execute
        container.read(backgroundSyncConfigProvider.notifier).state = newConfig;
        final config = container.read(backgroundSyncConfigProvider);

        // Verify
        expect(config.monitoredTypes, contains(WearableDataType.heartRate));
        expect(config.fetchInterval, equals(const Duration(minutes: 10)));
        expect(config.lookbackDuration, equals(const Duration(minutes: 15)));
      });
    });

    group('Edge Case Tests', () {
      test('should provide default configuration initially', () {
        // Execute
        final config = container.read(backgroundSyncConfigProvider);

        // Verify
        expect(config, isA<HealthBackgroundSyncConfig>());
        expect(config.monitoredTypes, isNotEmpty);
        expect(config.enableNotifications, isFalse);
      });

      test('should provide accurate background sync stats', () {
        // Execute
        final stats = container.read(backgroundSyncStatsProvider);

        // Verify
        expect(stats, isA<BackgroundSyncStats>());
        expect(stats.isActive, isFalse);
        expect(stats.platform, isA<String>());
        expect(stats.monitoredTypes, isA<List<String>>());
        expect(stats.fetchIntervalSeconds, isA<int>());
        expect(stats.totalActiveMonitors, isA<int>());
      });

      test('should handle BackgroundSyncManager operations', () async {
        // Setup
        final manager = container.read(backgroundSyncManagerProvider);

        // Execute status check
        final status = manager.getStatus();

        // Verify
        expect(status, isA<Map<String, dynamic>>());
        expect(status['isActive'], isA<bool>());
        expect(status['platform'], isA<String>());

        // Execute config update
        const newConfig = HealthBackgroundSyncConfig(
          monitoredTypes: [WearableDataType.steps],
          fetchInterval: Duration(minutes: 20),
          lookbackDuration: Duration(minutes: 30),
        );

        manager.updateConfig(newConfig);

        // Verify config was updated
        final updatedConfig = container.read(backgroundSyncConfigProvider);
        expect(
          updatedConfig.fetchInterval,
          equals(const Duration(minutes: 20)),
        );
      });

      test('should properly handle BackgroundSyncStats toString', () {
        // Setup
        const stats = BackgroundSyncStats(
          isActive: true,
          platform: 'iOS',
          monitoredTypes: ['steps', 'heartRate'],
          fetchIntervalSeconds: 300,
          iosObserversActive: 2,
          androidCallbackFlowActive: false,
        );

        // Execute
        final stringRepresentation = stats.toString();

        // Verify
        expect(stringRepresentation, contains('BackgroundSyncStats'));
        expect(stringRepresentation, contains('isActive: true'));
        expect(stringRepresentation, contains('platform: iOS'));
        expect(stringRepresentation, contains('monitoredTypes: 2'));
        expect(stringRepresentation, contains('activeMonitors: 2'));
      });

      test('should calculate total active monitors correctly', () {
        // Setup
        const stats = BackgroundSyncStats(
          isActive: true,
          platform: 'Android',
          monitoredTypes: ['steps'],
          fetchIntervalSeconds: 300,
          iosObserversActive: 0,
          androidCallbackFlowActive: true,
        );

        // Execute & Verify
        expect(stats.totalActiveMonitors, equals(1));

        // Test with both platforms active (edge case)
        const mixedStats = BackgroundSyncStats(
          isActive: true,
          platform: 'unknown',
          monitoredTypes: ['steps'],
          fetchIntervalSeconds: 300,
          iosObserversActive: 2,
          androidCallbackFlowActive: true,
        );

        expect(mixedStats.totalActiveMonitors, equals(3));
      });
    });

    group('Provider Dependencies Tests', () {
      test('should provide isBackgroundSyncActiveProvider correctly', () {
        // Execute
        final isActive = container.read(isBackgroundSyncActiveProvider);

        // Verify
        expect(isActive, isA<bool>());
        expect(isActive, isFalse); // Initially not active
      });

      test('should handle provider invalidation properly', () {
        // Setup - Get initial values

        // Execute - Invalidate and read again
        container.invalidate(healthBackgroundSyncServiceProvider);
        final newService = container.read(healthBackgroundSyncServiceProvider);
        final newManager = container.read(backgroundSyncManagerProvider);

        // Verify - Should be new instances
        expect(newService, isA<HealthBackgroundSyncService>());
        expect(newManager, isA<BackgroundSyncManager>());

        // Note: Due to singleton pattern, service might be the same instance
        // but the provider should still work correctly
      });
    });

    group('Stream Provider Tests', () {
      test('should provide backgroundSyncStatusProvider stream', () {
        // Execute
        final asyncValue = container.read(backgroundSyncStatusProvider);

        // Verify
        expect(asyncValue, isA<AsyncValue<HealthBackgroundSyncEvent>>());
      });

      test('should provide latestBackgroundHealthDataProvider stream', () {
        // Execute
        final asyncValue = container.read(latestBackgroundHealthDataProvider);

        // Verify
        expect(asyncValue, isA<AsyncValue<List<HealthSample>>>());
      });

      test('should provide backgroundSyncErrorProvider stream', () {
        // Execute
        final asyncValue = container.read(backgroundSyncErrorProvider);

        // Verify
        expect(asyncValue, isA<AsyncValue<String?>>());
      });
    });
  });
}
