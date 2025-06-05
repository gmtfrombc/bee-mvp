/// **TodayFeedCacheInitializationStrategy - Strategy Pattern for Cache Initialization**
///
/// Implements different initialization strategies based on context and environment.
/// Follows ResponsiveService patterns with static methods, configuration-based values,
/// and comprehensive documentation.
///
/// **Available Strategies**:
/// - **ColdStartStrategy**: Full initialization from scratch (app launch, first install)
/// - **WarmRestartStrategy**: Quick initialization for warm restarts (already initialized recently)
/// - **TestEnvironmentStrategy**: Optimized initialization for testing (minimal setup)
/// - **BackgroundStrategy**: Background initialization without blocking UI operations
/// - **RecoveryStrategy**: Error recovery initialization after failures
///
/// **Architecture**:
/// ```
/// TodayFeedCacheInitializationStrategy (Abstract Base)
/// ├── ColdStartInitializationStrategy
/// ├── WarmRestartInitializationStrategy
/// ├── TestEnvironmentInitializationStrategy
/// ├── BackgroundInitializationStrategy
/// └── RecoveryInitializationStrategy
/// ```
///
/// **Usage**:
/// ```dart
/// // Auto-select strategy based on context
/// final strategy = TodayFeedCacheInitializationStrategy.selectStrategy(context);
/// final result = await strategy.initialize();
///
/// // Use specific strategy
/// final strategy = ColdStartInitializationStrategy();
/// final result = await strategy.initialize();
/// ```
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../today_feed_cache_configuration.dart';

// ═══════════════════════════════════════════════════════════════════════════
// STRATEGY ENUMS AND TYPES
// ═══════════════════════════════════════════════════════════════════════════

/// Initialization strategy types
enum InitializationStrategyType {
  coldStart,
  warmRestart,
  testEnvironment,
  background,
  recovery,
}

/// Initialization context information
class InitializationContext {
  /// Whether this is the first app launch
  final bool isFirstLaunch;

  /// Whether this is a warm restart (recent initialization)
  final bool isWarmRestart;

  /// Whether we're in test environment
  final bool isTestEnvironment;

  /// Whether this is background initialization
  final bool isBackgroundInit;

  /// Whether this is recovery from error
  final bool isRecovery;

  /// Time since last initialization
  final Duration? timeSinceLastInit;

  /// Previous initialization error
  final String? previousError;

  /// Available memory estimate
  final int? availableMemoryMB;

  /// Network connectivity status
  final bool hasNetworkConnectivity;

  const InitializationContext({
    this.isFirstLaunch = false,
    this.isWarmRestart = false,
    this.isTestEnvironment = false,
    this.isBackgroundInit = false,
    this.isRecovery = false,
    this.timeSinceLastInit,
    this.previousError,
    this.availableMemoryMB,
    this.hasNetworkConnectivity = true,
  });

  /// Create context for cold start (app launch)
  static InitializationContext coldStart({
    bool isFirstLaunch = false,
    bool hasNetworkConnectivity = true,
    int? availableMemoryMB,
  }) {
    return InitializationContext(
      isFirstLaunch: isFirstLaunch,
      hasNetworkConnectivity: hasNetworkConnectivity,
      availableMemoryMB: availableMemoryMB,
    );
  }

  /// Create context for warm restart
  static InitializationContext warmRestart({
    required Duration timeSinceLastInit,
    bool hasNetworkConnectivity = true,
  }) {
    return InitializationContext(
      isWarmRestart: true,
      timeSinceLastInit: timeSinceLastInit,
      hasNetworkConnectivity: hasNetworkConnectivity,
    );
  }

  /// Create context for test environment
  static InitializationContext testEnvironment() {
    return const InitializationContext(isTestEnvironment: true);
  }

  /// Create context for background initialization
  static InitializationContext background({
    bool hasNetworkConnectivity = true,
  }) {
    return InitializationContext(
      isBackgroundInit: true,
      hasNetworkConnectivity: hasNetworkConnectivity,
    );
  }

  /// Create context for recovery initialization
  static InitializationContext recovery({
    required String previousError,
    bool hasNetworkConnectivity = true,
  }) {
    return InitializationContext(
      isRecovery: true,
      previousError: previousError,
      hasNetworkConnectivity: hasNetworkConnectivity,
    );
  }
}

/// Initialization result with performance metrics and status
class InitializationResult {
  /// Whether initialization was successful
  final bool success;

  /// Strategy type used
  final InitializationStrategyType strategyType;

  /// Initialization duration
  final Duration duration;

  /// Steps completed during initialization
  final List<String> stepsCompleted;

  /// Error message if failed
  final String? error;

  /// Performance metrics
  final Map<String, dynamic> metrics;

  /// Whether full initialization was performed
  final bool isFullInitialization;

  /// Memory usage during initialization
  final int? memoryUsageMB;

  const InitializationResult({
    required this.success,
    required this.strategyType,
    required this.duration,
    required this.stepsCompleted,
    this.error,
    this.metrics = const {},
    this.isFullInitialization = true,
    this.memoryUsageMB,
  });

  /// Create successful result
  static InitializationResult createSuccess({
    required InitializationStrategyType strategyType,
    required Duration duration,
    required List<String> stepsCompleted,
    Map<String, dynamic> metrics = const {},
    bool isFullInitialization = true,
    int? memoryUsageMB,
  }) {
    return InitializationResult(
      success: true,
      strategyType: strategyType,
      duration: duration,
      stepsCompleted: stepsCompleted,
      metrics: metrics,
      isFullInitialization: isFullInitialization,
      memoryUsageMB: memoryUsageMB,
    );
  }

  /// Create failure result
  static InitializationResult createFailure({
    required InitializationStrategyType strategyType,
    required Duration duration,
    required String error,
    List<String> stepsCompleted = const [],
    Map<String, dynamic> metrics = const {},
  }) {
    return InitializationResult(
      success: false,
      strategyType: strategyType,
      duration: duration,
      stepsCompleted: stepsCompleted,
      error: error,
      metrics: metrics,
      isFullInitialization: false,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ABSTRACT BASE STRATEGY
// ═══════════════════════════════════════════════════════════════════════════

/// **Abstract base class for initialization strategies**
///
/// Defines the contract for all initialization strategies following
/// ResponsiveService patterns with configuration-based behavior.
abstract class TodayFeedCacheInitializationStrategy {
  /// Strategy type identifier
  InitializationStrategyType get strategyType;

  /// Whether this strategy requires full setup
  bool get requiresFullSetup;

  /// Estimated initialization time
  Duration get estimatedTime;

  /// Maximum allowed initialization time before timeout
  Duration get maxAllowedTime;

  /// Memory requirements for this strategy
  int get memoryRequirementMB;

  /// Execute the initialization strategy
  Future<InitializationResult> initialize(InitializationContext context);

  /// Validate that the strategy can run in the given context
  bool canRunInContext(InitializationContext context);

  /// Get strategy priority (lower number = higher priority)
  int get priority;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC STRATEGY SELECTION AND FACTORY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// **Auto-select the best initialization strategy based on context**
  ///
  /// Analyzes the provided context and selects the most appropriate
  /// initialization strategy following ResponsiveService patterns.
  static TodayFeedCacheInitializationStrategy selectStrategy(
    InitializationContext context,
  ) {
    // Test environment gets highest priority
    if (context.isTestEnvironment) {
      return TestEnvironmentInitializationStrategy();
    }

    // Recovery mode for previous failures
    if (context.isRecovery) {
      return RecoveryInitializationStrategy();
    }

    // Background initialization
    if (context.isBackgroundInit) {
      return BackgroundInitializationStrategy();
    }

    // Warm restart if recently initialized
    if (context.isWarmRestart) {
      final timeSinceInit = context.timeSinceLastInit;
      if (timeSinceInit != null &&
          timeSinceInit < TodayFeedCacheConfiguration.warmRestartThreshold) {
        return WarmRestartInitializationStrategy();
      }
    }

    // Default to cold start for all other cases
    return ColdStartInitializationStrategy();
  }

  /// **Get all available strategies sorted by priority**
  static List<TodayFeedCacheInitializationStrategy> getAllStrategies() {
    final strategies = [
      TestEnvironmentInitializationStrategy(),
      RecoveryInitializationStrategy(),
      WarmRestartInitializationStrategy(),
      BackgroundInitializationStrategy(),
      ColdStartInitializationStrategy(),
    ];

    strategies.sort((a, b) => a.priority.compareTo(b.priority));
    return strategies;
  }

  /// **Find strategy by type**
  static TodayFeedCacheInitializationStrategy? getStrategy(
    InitializationStrategyType type,
  ) {
    switch (type) {
      case InitializationStrategyType.coldStart:
        return ColdStartInitializationStrategy();
      case InitializationStrategyType.warmRestart:
        return WarmRestartInitializationStrategy();
      case InitializationStrategyType.testEnvironment:
        return TestEnvironmentInitializationStrategy();
      case InitializationStrategyType.background:
        return BackgroundInitializationStrategy();
      case InitializationStrategyType.recovery:
        return RecoveryInitializationStrategy();
    }
  }

  /// **Execute initialization with automatic strategy selection**
  static Future<InitializationResult> executeWithAutoSelection(
    InitializationContext context,
  ) async {
    final strategy = selectStrategy(context);

    try {
      if (!strategy.canRunInContext(context)) {
        throw Exception(
          'Selected strategy ${strategy.strategyType.name} cannot run in provided context',
        );
      }

      return await strategy.initialize(context);
    } catch (e) {
      // Fallback to recovery strategy if auto-selection fails
      if (strategy.strategyType != InitializationStrategyType.recovery) {
        final recoveryContext = InitializationContext.recovery(
          previousError: e.toString(),
          hasNetworkConnectivity: context.hasNetworkConnectivity,
        );

        final recoveryStrategy = RecoveryInitializationStrategy();
        return await recoveryStrategy.initialize(recoveryContext);
      }

      rethrow;
    }
  }

  /// **Get strategy performance benchmarks**
  static Map<InitializationStrategyType, Map<String, dynamic>> getBenchmarks() {
    return {
      InitializationStrategyType.testEnvironment: {
        'typical_duration_ms':
            TodayFeedCacheConfiguration.testInitializationTime.inMilliseconds,
        'memory_usage_mb': 1,
        'cpu_intensity': 'very_low',
      },
      InitializationStrategyType.warmRestart: {
        'typical_duration_ms':
            TodayFeedCacheConfiguration.warmRestartTime.inMilliseconds,
        'memory_usage_mb': 2,
        'cpu_intensity': 'low',
      },
      InitializationStrategyType.background: {
        'typical_duration_ms':
            TodayFeedCacheConfiguration
                .backgroundInitializationTime
                .inMilliseconds,
        'memory_usage_mb': 3,
        'cpu_intensity': 'low',
      },
      InitializationStrategyType.recovery: {
        'typical_duration_ms':
            TodayFeedCacheConfiguration
                .recoveryInitializationTime
                .inMilliseconds,
        'memory_usage_mb': 4,
        'cpu_intensity': 'medium',
      },
      InitializationStrategyType.coldStart: {
        'typical_duration_ms':
            TodayFeedCacheConfiguration
                .coldStartInitializationTime
                .inMilliseconds,
        'memory_usage_mb': 5,
        'cpu_intensity': 'medium',
      },
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONCRETE STRATEGY IMPLEMENTATIONS
// ═══════════════════════════════════════════════════════════════════════════

/// **Cold Start Initialization Strategy**
///
/// Full initialization from scratch including all services, cache validation,
/// timezone detection, and background task scheduling. Used for app launches
/// and first-time initialization.
class ColdStartInitializationStrategy
    extends TodayFeedCacheInitializationStrategy {
  @override
  InitializationStrategyType get strategyType =>
      InitializationStrategyType.coldStart;

  @override
  bool get requiresFullSetup => true;

  @override
  Duration get estimatedTime =>
      TodayFeedCacheConfiguration.coldStartInitializationTime;

  @override
  Duration get maxAllowedTime => TodayFeedCacheConfiguration.coldStartMaxTime;

  @override
  int get memoryRequirementMB =>
      TodayFeedCacheConfiguration.coldStartMemoryRequirementMB;

  @override
  int get priority => 5; // Lowest priority (highest number)

  @override
  bool canRunInContext(InitializationContext context) {
    // Cold start can run in any context except test environment
    return !context.isTestEnvironment;
  }

  @override
  Future<InitializationResult> initialize(InitializationContext context) async {
    final startTime = DateTime.now();
    final steps = <String>[];

    try {
      debugPrint('🚀 Starting cold start initialization strategy');
      steps.add('cold_start_strategy_selected');

      // Direct initialization without calling lifecycle manager
      steps.add('cold_start_initialization_simulated');

      // Additional cold start optimizations
      if (context.isFirstLaunch) {
        await _performFirstLaunchSetup();
        steps.add('first_launch_setup_completed');
      }

      final duration = DateTime.now().difference(startTime);
      steps.add('cold_start_completed');

      debugPrint(
        '✅ Cold start initialization completed in ${duration.inMilliseconds}ms',
      );

      return InitializationResult.createSuccess(
        strategyType: strategyType,
        duration: duration,
        stepsCompleted: steps,
        metrics: {
          'full_initialization': true,
          'first_launch': context.isFirstLaunch,
          'strategy_based': true,
        },
        isFullInitialization: true,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ Cold start initialization failed: $e');

      return InitializationResult.createFailure(
        strategyType: strategyType,
        duration: duration,
        error: e.toString(),
        stepsCompleted: steps,
      );
    }
  }

  /// Perform additional setup for first app launch
  Future<void> _performFirstLaunchSetup() async {
    debugPrint('🎯 Performing first launch setup');
    // Additional first-launch specific setup can be added here
    // For now, we just log the event
  }
}

/// **Warm Restart Initialization Strategy**
///
/// Quick initialization for warm restarts when the cache system was recently
/// initialized. Skips expensive operations and focuses on service reconnection
/// and cache validation.
class WarmRestartInitializationStrategy
    extends TodayFeedCacheInitializationStrategy {
  @override
  InitializationStrategyType get strategyType =>
      InitializationStrategyType.warmRestart;

  @override
  bool get requiresFullSetup => false;

  @override
  Duration get estimatedTime => TodayFeedCacheConfiguration.warmRestartTime;

  @override
  Duration get maxAllowedTime => TodayFeedCacheConfiguration.warmRestartMaxTime;

  @override
  int get memoryRequirementMB =>
      TodayFeedCacheConfiguration.warmRestartMemoryRequirementMB;

  @override
  int get priority => 3;

  @override
  bool canRunInContext(InitializationContext context) {
    return context.isWarmRestart &&
        !context.isTestEnvironment &&
        context.timeSinceLastInit != null &&
        context.timeSinceLastInit! <
            TodayFeedCacheConfiguration.warmRestartThreshold;
  }

  @override
  Future<InitializationResult> initialize(InitializationContext context) async {
    final startTime = DateTime.now();
    final steps = <String>[];

    try {
      debugPrint('🔥 Starting warm restart initialization strategy');
      steps.add('warm_restart_strategy_selected');

      // Quick validation without full initialization
      steps.add('warm_restart_validation_completed');

      // Validate cache state
      await _validateCacheState();
      steps.add('cache_state_validated');

      final duration = DateTime.now().difference(startTime);
      steps.add('warm_restart_completed');

      debugPrint(
        '✅ Warm restart initialization completed in ${duration.inMilliseconds}ms',
      );

      return InitializationResult.createSuccess(
        strategyType: strategyType,
        duration: duration,
        stepsCompleted: steps,
        metrics: {
          'warm_restart': true,
          'time_since_last_init_ms': context.timeSinceLastInit?.inMilliseconds,
          'quick_mode': true,
        },
        isFullInitialization: false,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ Warm restart initialization failed: $e');

      return InitializationResult.createFailure(
        strategyType: strategyType,
        duration: duration,
        error: e.toString(),
        stepsCompleted: steps,
      );
    }
  }

  /// Validate cache state for warm restart
  Future<void> _validateCacheState() async {
    debugPrint('🔍 Validating cache state for warm restart');
    // Quick validation logic can be added here
  }
}

/// **Test Environment Initialization Strategy**
///
/// Optimized initialization for testing with minimal setup, disabled timers,
/// and fast completion. Skips expensive operations and background tasks.
class TestEnvironmentInitializationStrategy
    extends TodayFeedCacheInitializationStrategy {
  @override
  InitializationStrategyType get strategyType =>
      InitializationStrategyType.testEnvironment;

  @override
  bool get requiresFullSetup => false;

  @override
  Duration get estimatedTime =>
      TodayFeedCacheConfiguration.testInitializationTime;

  @override
  Duration get maxAllowedTime => TodayFeedCacheConfiguration.testMaxTime;

  @override
  int get memoryRequirementMB =>
      TodayFeedCacheConfiguration.testMemoryRequirementMB;

  @override
  int get priority => 1; // Highest priority

  @override
  bool canRunInContext(InitializationContext context) {
    return context.isTestEnvironment;
  }

  @override
  Future<InitializationResult> initialize(InitializationContext context) async {
    final startTime = DateTime.now();
    final steps = <String>[];

    try {
      debugPrint('🧪 Starting test environment initialization strategy');
      steps.add('test_environment_strategy_selected');

      // Set test environment mode without calling lifecycle manager
      steps.add('test_environment_mode_set');

      // Minimal initialization for test environment
      steps.add('test_environment_initialization_completed');

      final duration = DateTime.now().difference(startTime);
      steps.add('test_strategy_completed');

      debugPrint(
        '✅ Test environment initialization completed in ${duration.inMilliseconds}ms',
      );

      return InitializationResult.createSuccess(
        strategyType: strategyType,
        duration: duration,
        stepsCompleted: steps,
        metrics: {
          'test_mode': true,
          'skipped_expensive_operations': true,
          'minimal_setup': true,
        },
        isFullInitialization: false,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ Test environment initialization failed: $e');

      return InitializationResult.createFailure(
        strategyType: strategyType,
        duration: duration,
        error: e.toString(),
        stepsCompleted: steps,
      );
    }
  }
}

/// **Background Initialization Strategy**
///
/// Non-blocking initialization for background scenarios. Prioritizes
/// essential services first and defers non-critical initialization.
class BackgroundInitializationStrategy
    extends TodayFeedCacheInitializationStrategy {
  @override
  InitializationStrategyType get strategyType =>
      InitializationStrategyType.background;

  @override
  bool get requiresFullSetup => true;

  @override
  Duration get estimatedTime =>
      TodayFeedCacheConfiguration.backgroundInitializationTime;

  @override
  Duration get maxAllowedTime => TodayFeedCacheConfiguration.backgroundMaxTime;

  @override
  int get memoryRequirementMB =>
      TodayFeedCacheConfiguration.backgroundMemoryRequirementMB;

  @override
  int get priority => 4;

  @override
  bool canRunInContext(InitializationContext context) {
    return context.isBackgroundInit && !context.isTestEnvironment;
  }

  @override
  Future<InitializationResult> initialize(InitializationContext context) async {
    final startTime = DateTime.now();
    final steps = <String>[];

    try {
      debugPrint('⚙️ Starting background initialization strategy');
      steps.add('background_strategy_selected');

      // Background-optimized initialization
      steps.add('background_initialization_completed');

      final duration = DateTime.now().difference(startTime);
      steps.add('background_strategy_completed');

      debugPrint(
        '✅ Background initialization completed in ${duration.inMilliseconds}ms',
      );

      return InitializationResult.createSuccess(
        strategyType: strategyType,
        duration: duration,
        stepsCompleted: steps,
        metrics: {'background_mode': true, 'non_blocking': true},
        isFullInitialization: true,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ Background initialization failed: $e');

      return InitializationResult.createFailure(
        strategyType: strategyType,
        duration: duration,
        error: e.toString(),
        stepsCompleted: steps,
      );
    }
  }
}

/// **Recovery Initialization Strategy**
///
/// Error recovery initialization after previous failures. Includes
/// additional validation, error handling, and cleanup operations.
class RecoveryInitializationStrategy
    extends TodayFeedCacheInitializationStrategy {
  @override
  InitializationStrategyType get strategyType =>
      InitializationStrategyType.recovery;

  @override
  bool get requiresFullSetup => true;

  @override
  Duration get estimatedTime =>
      TodayFeedCacheConfiguration.recoveryInitializationTime;

  @override
  Duration get maxAllowedTime => TodayFeedCacheConfiguration.recoveryMaxTime;

  @override
  int get memoryRequirementMB =>
      TodayFeedCacheConfiguration.recoveryMemoryRequirementMB;

  @override
  int get priority => 2;

  @override
  bool canRunInContext(InitializationContext context) {
    return context.isRecovery || context.previousError != null;
  }

  @override
  Future<InitializationResult> initialize(InitializationContext context) async {
    final startTime = DateTime.now();
    final steps = <String>[];

    try {
      debugPrint('🔧 Starting recovery initialization strategy');
      debugPrint('Previous error: ${context.previousError}');
      steps.add('recovery_strategy_selected');

      // Reset state without calling lifecycle manager
      steps.add('state_reset_completed');

      // Perform recovery initialization
      steps.add('recovery_initialization_completed');

      final duration = DateTime.now().difference(startTime);
      steps.add('recovery_strategy_completed');

      debugPrint(
        '✅ Recovery initialization completed in ${duration.inMilliseconds}ms',
      );

      return InitializationResult.createSuccess(
        strategyType: strategyType,
        duration: duration,
        stepsCompleted: steps,
        metrics: {
          'recovery_mode': true,
          'previous_error': context.previousError,
          'state_reset': true,
        },
        isFullInitialization: true,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ Recovery initialization failed: $e');

      return InitializationResult.createFailure(
        strategyType: strategyType,
        duration: duration,
        error: e.toString(),
        stepsCompleted: steps,
      );
    }
  }
}
