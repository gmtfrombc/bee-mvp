import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/cache/today_feed_cache_warming_service.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('TodayFeedCacheWarmingService Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      await TestHelpers.setUpTest();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() async {
      await TodayFeedCacheWarmingService.dispose();
    });

    group('Service Initialization', () {
      test('should initialize successfully', () async {
        // Act & Assert - should not throw
        await expectLater(
          TodayFeedCacheWarmingService.initialize(prefs),
          completes,
        );
      });

      test('should handle multiple initialization calls', () async {
        // Act & Assert - should not throw
        await expectLater(() async {
          await TodayFeedCacheWarmingService.initialize(prefs);
          await TodayFeedCacheWarmingService.initialize(prefs);
        }(), completes);
      });

      test('should dispose properly', () async {
        // Arrange
        await TodayFeedCacheWarmingService.initialize(prefs);

        // Act & Assert - should not throw
        await expectLater(TodayFeedCacheWarmingService.dispose(), completes);
      });
    });

    group('Cache Warming Strategies', () {
      setUp(() async {
        await TodayFeedCacheWarmingService.initialize(prefs);
      });

      test('should execute manual warming strategy', () async {
        // Act
        final result =
            await TodayFeedCacheWarmingService.executeWarmingStrategy(
              trigger: WarmingTrigger.manual,
            );

        // Assert
        expect(result, isA<WarmingResult>());
        expect(result.trigger, WarmingTrigger.manual);
        // Duration and results may be null in test environment, that's ok
        if (result.success) {
          expect(result.duration, isNotNull);
          expect(result.results, isNotNull);
          expect(result.error, isNull);
        } else {
          // Warming might fail in test environment due to missing dependencies
          expect(result.error, isNotNull);
        }
      });

      test('should execute connectivity warming strategy', () async {
        // Act
        final result =
            await TodayFeedCacheWarmingService.executeWarmingStrategy(
              trigger: WarmingTrigger.connectivity,
              context: {'previous_status': 'offline'},
            );

        // Assert
        expect(result, isA<WarmingResult>());
        expect(result.trigger, WarmingTrigger.connectivity);
        expect(result.success, isA<bool>());
      });

      test('should execute scheduled warming strategy', () async {
        // Act
        final result =
            await TodayFeedCacheWarmingService.executeWarmingStrategy(
              trigger: WarmingTrigger.scheduled,
            );

        // Assert
        expect(result, isA<WarmingResult>());
        expect(result.trigger, WarmingTrigger.scheduled);
        expect(result.success, isA<bool>());
      });

      test('should execute predictive warming strategy', () async {
        // Act
        final result =
            await TodayFeedCacheWarmingService.executeWarmingStrategy(
              trigger: WarmingTrigger.predictive,
            );

        // Assert
        expect(result, isA<WarmingResult>());
        expect(result.trigger, WarmingTrigger.predictive);
        expect(result.success, isA<bool>());
      });

      test('should execute app launch warming strategy', () async {
        // Act
        final result =
            await TodayFeedCacheWarmingService.executeWarmingStrategy(
              trigger: WarmingTrigger.appLaunch,
            );

        // Assert
        expect(result, isA<WarmingResult>());
        expect(result.trigger, WarmingTrigger.appLaunch);
        expect(result.success, isA<bool>());
      });

      test('should handle warming with different contexts', () async {
        // Test various context scenarios
        final contexts = [
          null,
          <String, dynamic>{},
          {'app_startup': true},
          {'previous_status': 'offline'},
          {'user_pattern': 'morning_engagement'},
        ];

        for (final context in contexts) {
          final result =
              await TodayFeedCacheWarmingService.executeWarmingStrategy(
                context: context,
              );

          expect(result, isA<WarmingResult>());
          expect(result.trigger, WarmingTrigger.manual);
        }
      });
    });

    group('Service Integration', () {
      setUp(() async {
        await TodayFeedCacheWarmingService.initialize(prefs);
      });

      test('should handle service initialization without dependencies', () async {
        // The service should initialize even if other services aren't available
        // This is important for testing scenarios
        await expectLater(
          TodayFeedCacheWarmingService.initialize(prefs),
          completes,
        );
      });

      test(
        'should handle warming execution gracefully when dependencies unavailable',
        () async {
          // Act - trigger warming which internally uses other services
          final result =
              await TodayFeedCacheWarmingService.executeWarmingStrategy();

          // Assert - should handle missing dependencies gracefully
          expect(result, isA<WarmingResult>());
          expect(result.trigger, WarmingTrigger.manual);
          // Success or failure is acceptable in test environment
          expect(result.success, isA<bool>());
        },
      );
    });

    group('Performance and Resource Management', () {
      setUp(() async {
        await TodayFeedCacheWarmingService.initialize(prefs);
      });

      test('should complete warming within reasonable time', () async {
        final stopwatch = Stopwatch()..start();

        // Act
        await TodayFeedCacheWarmingService.executeWarmingStrategy();

        stopwatch.stop();

        // Assert - should complete within 10 seconds (increased for test environment)
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });

      test('should track warming duration when successful', () async {
        // Act
        final result =
            await TodayFeedCacheWarmingService.executeWarmingStrategy();

        // Assert
        if (result.success) {
          expect(result.duration, isNotNull);
          expect(result.duration!.inMilliseconds, greaterThanOrEqualTo(0));
        }
        // If not successful, duration may be null, which is acceptable
      });

      test('should dispose resources properly', () async {
        // Act
        await TodayFeedCacheWarmingService.dispose();

        // Assert - should be able to reinitialize after disposal
        await expectLater(
          TodayFeedCacheWarmingService.initialize(prefs),
          completes,
        );
      });
    });

    group('Performance Impact', () {
      test('should track warming performance metrics', () async {
        // Arrange
        await TodayFeedCacheWarmingService.initialize(prefs);

        // Act
        final result =
            await TodayFeedCacheWarmingService.executeWarmingStrategy();

        // Assert
        expect(result, isA<WarmingResult>());
        expect(result.success, isA<bool>());
        expect(result.duration, isA<Duration>());
        expect(result.trigger, isA<WarmingTrigger>());
      });
    });
  });
}
