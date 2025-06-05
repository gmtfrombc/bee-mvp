import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:app/core/services/cache/strategies/today_feed_cache_initialization_strategy.dart';

/// **Consolidated Cache Strategies Tests**
///
/// Essential strategy tests for Epic 1.3 (Adaptive AI Coach Foundation)
/// Combines initialization and optimization strategy tests while removing redundancy
///
/// **Core Coverage:**
/// - Strategy selection patterns
/// - Context validation
/// - Basic strategy properties
/// - Core initialization flows
void main() {
  group('TodayFeed Cache Strategies', () {
    setUp(() {
      // Reset any state before each test
      debugDefaultTargetPlatformOverride = null;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    // ═════════════════════════════════════════════════════════════════════════
    // STRATEGY SELECTION TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Strategy Selection', () {
      test('should select test environment strategy for test context', () {
        // Arrange
        final context = InitializationContext.testEnvironment();

        // Act
        final strategy = TodayFeedCacheInitializationStrategy.selectStrategy(
          context,
        );

        // Assert
        expect(strategy, isA<TestEnvironmentInitializationStrategy>());
        expect(
          strategy.strategyType,
          InitializationStrategyType.testEnvironment,
        );
      });

      test('should select recovery strategy for recovery context', () {
        // Arrange
        final context = InitializationContext.recovery(
          previousError: 'test error',
        );

        // Act
        final strategy = TodayFeedCacheInitializationStrategy.selectStrategy(
          context,
        );

        // Assert
        expect(strategy, isA<RecoveryInitializationStrategy>());
        expect(strategy.strategyType, InitializationStrategyType.recovery);
      });

      test('should select cold start strategy for default context', () {
        // Arrange
        final context = InitializationContext.coldStart();

        // Act
        final strategy = TodayFeedCacheInitializationStrategy.selectStrategy(
          context,
        );

        // Assert
        expect(strategy, isA<ColdStartInitializationStrategy>());
        expect(strategy.strategyType, InitializationStrategyType.coldStart);
      });

      test('should select warm restart strategy for recent restart', () {
        // Arrange
        final context = InitializationContext.warmRestart(
          timeSinceLastInit: const Duration(minutes: 2),
        );

        // Act
        final strategy = TodayFeedCacheInitializationStrategy.selectStrategy(
          context,
        );

        // Assert
        expect(strategy, isA<WarmRestartInitializationStrategy>());
        expect(strategy.strategyType, InitializationStrategyType.warmRestart);
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // CONTEXT VALIDATION TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Context Validation', () {
      test('should validate test environment strategy context correctly', () {
        // Arrange
        final strategy = TestEnvironmentInitializationStrategy();

        // Act & Assert
        expect(
          strategy.canRunInContext(InitializationContext.testEnvironment()),
          isTrue,
        );
        expect(
          strategy.canRunInContext(InitializationContext.coldStart()),
          isFalse,
        );
      });

      test('should validate cold start strategy context correctly', () {
        // Arrange
        final strategy = ColdStartInitializationStrategy();

        // Act & Assert
        expect(
          strategy.canRunInContext(InitializationContext.coldStart()),
          isTrue,
        );
        expect(
          strategy.canRunInContext(InitializationContext.testEnvironment()),
          isFalse,
        );
      });

      test('should validate warm restart strategy context correctly', () {
        // Arrange
        final strategy = WarmRestartInitializationStrategy();
        final validContext = InitializationContext.warmRestart(
          timeSinceLastInit: const Duration(minutes: 2),
        );

        // Act & Assert
        expect(strategy.canRunInContext(validContext), isTrue);
        expect(
          strategy.canRunInContext(InitializationContext.testEnvironment()),
          isFalse,
        );
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // STRATEGY PROPERTIES TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Strategy Properties', () {
      test('should have correct properties for cold start strategy', () {
        // Arrange
        final strategy = ColdStartInitializationStrategy();

        // Act & Assert
        expect(strategy.requiresFullSetup, isTrue);
        expect(strategy.priority, 5);
        expect(strategy.estimatedTime.inMilliseconds, greaterThan(0));
        expect(strategy.memoryRequirementMB, greaterThan(0));
      });

      test('should have correct properties for test environment strategy', () {
        // Arrange
        final strategy = TestEnvironmentInitializationStrategy();

        // Act & Assert
        expect(strategy.requiresFullSetup, isFalse);
        expect(strategy.priority, 1); // Highest priority for testing
        expect(strategy.estimatedTime.inMilliseconds, lessThan(100));
      });

      test('should have correct properties for warm restart strategy', () {
        // Arrange
        final strategy = WarmRestartInitializationStrategy();

        // Act & Assert
        expect(strategy.requiresFullSetup, isFalse);
        expect(strategy.priority, 3);
        expect(strategy.estimatedTime.inMilliseconds, lessThan(100));
      });

      test('should have correct properties for recovery strategy', () {
        // Arrange
        final strategy = RecoveryInitializationStrategy();

        // Act & Assert
        expect(strategy.priority, 2); // High priority for recovery
        expect(strategy.estimatedTime.inMilliseconds, greaterThan(0));
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // CONTEXT FACTORY TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Context Factory Methods', () {
      test('should create cold start context correctly', () {
        // Act
        final context = InitializationContext.coldStart(
          isFirstLaunch: true,
          hasNetworkConnectivity: false,
        );

        // Assert
        expect(context.isFirstLaunch, isTrue);
        expect(context.hasNetworkConnectivity, isFalse);
        expect(context.isTestEnvironment, isFalse);
      });

      test('should create warm restart context correctly', () {
        // Arrange
        const duration = Duration(minutes: 3);

        // Act
        final context = InitializationContext.warmRestart(
          timeSinceLastInit: duration,
        );

        // Assert
        expect(context.isWarmRestart, isTrue);
        expect(context.timeSinceLastInit, duration);
      });

      test('should create test environment context correctly', () {
        // Act
        final context = InitializationContext.testEnvironment();

        // Assert
        expect(context.isTestEnvironment, isTrue);
        expect(context.isWarmRestart, isFalse);
        expect(context.isRecovery, isFalse);
      });

      test('should create recovery context correctly', () {
        // Act
        final context = InitializationContext.recovery(
          previousError: 'test error',
        );

        // Assert
        expect(context.isRecovery, isTrue);
        expect(context.isTestEnvironment, isFalse);
      });
    });

    // ═════════════════════════════════════════════════════════════════════════
    // INITIALIZATION RESULT TESTS
    // ═════════════════════════════════════════════════════════════════════════

    group('Initialization Results', () {
      test('should create success result correctly', () {
        // Act
        final result = InitializationResult.createSuccess(
          strategyType: InitializationStrategyType.coldStart,
          duration: const Duration(milliseconds: 100),
          stepsCompleted: ['step1', 'step2'],
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.strategyType, InitializationStrategyType.coldStart);
        expect(result.duration.inMilliseconds, 100);
        expect(result.stepsCompleted, ['step1', 'step2']);
        expect(result.error, isNull);
      });

      test('should create failure result correctly', () {
        // Act
        final result = InitializationResult.createFailure(
          strategyType: InitializationStrategyType.recovery,
          duration: const Duration(milliseconds: 50),
          error: 'Test error',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.strategyType, InitializationStrategyType.recovery);
        expect(result.error, 'Test error');
        expect(result.isFullInitialization, isFalse);
      });
    });
  });
}
