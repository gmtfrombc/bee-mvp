import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/cache/today_feed_cache_migration_manager.dart';
import 'package:app/core/services/cache/today_feed_cache_configuration.dart';

void main() {
  group('TodayFeedCacheMigrationManager', () {
    setUp(() async {
      // Ensure test environment is set FIRST
      TodayFeedCacheConfiguration.forTestEnvironment();

      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});

      // Reset the migration manager completely
      await TodayFeedCacheMigrationManager.resetForTesting();
    });

    tearDown(() async {
      // Ensure complete cleanup after each test
      await TodayFeedCacheMigrationManager.resetForTesting();

      // Additional safety delay to prevent hanging
      await Future.delayed(const Duration(milliseconds: 5));
    });

    group('Initialization', () {
      test('should initialize with default values', () async {
        // Initialize the service
        await TodayFeedCacheMigrationManager.initialize();

        // Test basic functionality
        final phase = TodayFeedCacheMigrationManager.getCurrentMigrationPhase();
        final strategy =
            TodayFeedCacheMigrationManager.getCurrentRolloutStrategy();

        expect(phase, equals(MigrationPhase.compatibilityOnly));
        expect(strategy, isA<RolloutStrategy>());
      });

      test('should initialize with user ID', () async {
        const testUserId = 'test-user-123';
        await TodayFeedCacheMigrationManager.initialize(userId: testUserId);

        // Test basic functionality
        final phase = TodayFeedCacheMigrationManager.getCurrentMigrationPhase();
        expect(phase, equals(MigrationPhase.compatibilityOnly));
      });

      test('should handle double initialization gracefully', () async {
        // Initialize twice - should not throw or hang
        await TodayFeedCacheMigrationManager.initialize();
        await TodayFeedCacheMigrationManager.initialize();

        final phase = TodayFeedCacheMigrationManager.getCurrentMigrationPhase();
        expect(phase, equals(MigrationPhase.compatibilityOnly));
      });
    });

    group('Migration Phase Management', () {
      test('should set and get migration phases', () async {
        await TodayFeedCacheMigrationManager.initialize();

        // Test setting phase
        await TodayFeedCacheMigrationManager.setMigrationPhase(
          MigrationPhase.internalTesting,
        );

        final currentPhase =
            TodayFeedCacheMigrationManager.getCurrentMigrationPhase();
        expect(currentPhase, equals(MigrationPhase.internalTesting));
      });
    });

    group('Feature Flag Control', () {
      test('should return false for compatibility only phase', () async {
        await TodayFeedCacheMigrationManager.initialize();
        await TodayFeedCacheMigrationManager.setMigrationPhase(
          MigrationPhase.compatibilityOnly,
        );

        final shouldUse =
            await TodayFeedCacheMigrationManager.shouldUseNewArchitecture();
        expect(shouldUse, isFalse);
      });

      test('should return true for full deployment phase', () async {
        await TodayFeedCacheMigrationManager.initialize();
        await TodayFeedCacheMigrationManager.setMigrationPhase(
          MigrationPhase.fullDeployment,
        );

        final shouldUse =
            await TodayFeedCacheMigrationManager.shouldUseNewArchitecture();
        expect(shouldUse, isTrue);
      });
    });

    group('Test Environment Safety', () {
      test('should not create timers in test environment', () async {
        // Verify test environment is properly set
        expect(TodayFeedCacheConfiguration.isTestEnvironment, isTrue);

        await TodayFeedCacheMigrationManager.initialize();

        // Service should initialize without hanging
        final phase = TodayFeedCacheMigrationManager.getCurrentMigrationPhase();
        expect(phase, equals(MigrationPhase.compatibilityOnly));
      });
    });
  });
}
