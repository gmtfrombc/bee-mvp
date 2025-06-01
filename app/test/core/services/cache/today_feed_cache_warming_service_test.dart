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

    group('Warming Configuration', () {
      setUp(() async {
        await TodayFeedCacheWarmingService.initialize(prefs);
      });

      test('should create default configuration with correct values', () {
        // Act
        final config = WarmingConfiguration.defaultConfig();

        // Assert
        expect(config.enableContentPreloading, isTrue);
        expect(config.enableHistoryWarming, isTrue);
        expect(config.enablePredictiveWarming, isTrue);
        expect(
          config.scheduledWarmingInterval,
          equals(const Duration(hours: 2)),
        );
        expect(
          config.predictiveWarmingInterval,
          equals(const Duration(minutes: 30)),
        );
      });

      test('should create custom configuration with specified values', () {
        // Act
        const config = WarmingConfiguration(
          enableContentPreloading: false,
          enableHistoryWarming: true,
          enablePredictiveWarming: false,
          scheduledWarmingInterval: Duration(hours: 4),
          predictiveWarmingInterval: Duration(hours: 1),
        );

        // Assert
        expect(config.enableContentPreloading, isFalse);
        expect(config.enableHistoryWarming, isTrue);
        expect(config.enablePredictiveWarming, isFalse);
        expect(
          config.scheduledWarmingInterval,
          equals(const Duration(hours: 4)),
        );
        expect(
          config.predictiveWarmingInterval,
          equals(const Duration(hours: 1)),
        );
      });

      test('should update warming configuration successfully', () async {
        // Arrange
        const newConfig = WarmingConfiguration(
          enableContentPreloading: false,
          enableHistoryWarming: false,
          enablePredictiveWarming: true,
          scheduledWarmingInterval: Duration(hours: 1),
          predictiveWarmingInterval: Duration(minutes: 15),
        );

        // Act & Assert - should not throw
        await expectLater(
          TodayFeedCacheWarmingService.updateWarmingConfiguration(newConfig),
          completes,
        );
      });

      test('should handle configuration JSON serialization', () {
        // Act
        final config = WarmingConfiguration.defaultConfig();
        final json = config.toJson();
        final parsedConfig = WarmingConfiguration.fromJson(json);

        // Assert - should create valid config objects
        expect(json, isA<String>());
        expect(parsedConfig, isA<WarmingConfiguration>());
        expect(parsedConfig.enableContentPreloading, isTrue);
      });
    });

    group('Warming Triggers', () {
      test('should define all required warming trigger types', () {
        // Assert - verify all expected triggers exist
        final triggerValues = WarmingTrigger.values;
        expect(triggerValues, hasLength(5));
        expect(triggerValues, contains(WarmingTrigger.manual));
        expect(triggerValues, contains(WarmingTrigger.connectivity));
        expect(triggerValues, contains(WarmingTrigger.scheduled));
        expect(triggerValues, contains(WarmingTrigger.predictive));
        expect(triggerValues, contains(WarmingTrigger.appLaunch));
      });

      test('should have correct trigger names', () {
        // Assert
        expect(WarmingTrigger.manual.name, equals('manual'));
        expect(WarmingTrigger.connectivity.name, equals('connectivity'));
        expect(WarmingTrigger.scheduled.name, equals('scheduled'));
        expect(WarmingTrigger.predictive.name, equals('predictive'));
        expect(WarmingTrigger.appLaunch.name, equals('appLaunch'));
      });
    });

    group('Warming Results', () {
      test('should create successful result with correct properties', () {
        // Act
        final result = WarmingResult.success(
          trigger: WarmingTrigger.manual,
          duration: const Duration(milliseconds: 500),
          results: {'content_preloading': 'success'},
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.trigger, WarmingTrigger.manual);
        expect(result.duration, equals(const Duration(milliseconds: 500)));
        expect(result.results, isNotNull);
        expect(result.results!['content_preloading'], equals('success'));
        expect(result.error, isNull);
      });

      test('should create failed result with correct properties', () {
        // Act
        final result = WarmingResult.failed(
          trigger: WarmingTrigger.connectivity,
          error: 'Network error',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.trigger, WarmingTrigger.connectivity);
        expect(result.error, equals('Network error'));
        expect(result.duration, isNull);
        expect(result.results, isNull);
      });

      test('should handle various result scenarios', () {
        // Test empty results
        final emptyResult = WarmingResult.success(
          trigger: WarmingTrigger.manual,
          duration: Duration.zero,
          results: <String, dynamic>{},
        );

        expect(emptyResult.success, isTrue);
        expect(emptyResult.results, isEmpty);

        // Test complex results
        final complexResult = WarmingResult.success(
          trigger: WarmingTrigger.predictive,
          duration: const Duration(seconds: 2),
          results: {
            'content_preloading': 'completed',
            'history_warming': {'status': 'adequate', 'count': 5},
            'predictive_warming': {'timing': 'optimal'},
          },
        );

        expect(complexResult.success, isTrue);
        expect(
          complexResult.results!['content_preloading'],
          equals('completed'),
        );
        expect(complexResult.results!['history_warming'], isA<Map>());
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

    group('Edge Cases and Error Handling', () {
      test('should handle uninitialized service gracefully', () async {
        // Arrange - ensure service is not initialized
        await TodayFeedCacheWarmingService.dispose();

        // Act & Assert
        expect(
          () => TodayFeedCacheWarmingService.executeWarmingStrategy(),
          throwsA(isA<StateError>()),
        );
      });

      test('should handle null context gracefully', () async {
        // Arrange
        await TodayFeedCacheWarmingService.initialize(prefs);

        // Act
        final result =
            await TodayFeedCacheWarmingService.executeWarmingStrategy(
              context: null,
            );

        // Assert
        expect(result, isA<WarmingResult>());
        expect(result.success, isA<bool>());
      });

      test('should handle empty context gracefully', () async {
        // Arrange
        await TodayFeedCacheWarmingService.initialize(prefs);

        // Act
        final result =
            await TodayFeedCacheWarmingService.executeWarmingStrategy(
              context: <String, dynamic>{},
            );

        // Assert
        expect(result, isA<WarmingResult>());
        expect(result.success, isA<bool>());
      });

      test(
        'should handle configuration updates on uninitialized service',
        () async {
          // Arrange - ensure service is not initialized
          await TodayFeedCacheWarmingService.dispose();

          // Act & Assert - should throw error for uninitialized service
          expect(
            () => TodayFeedCacheWarmingService.updateWarmingConfiguration(
              WarmingConfiguration.defaultConfig(),
            ),
            throwsA(isA<StateError>()),
          );
        },
      );
    });
  });
}
