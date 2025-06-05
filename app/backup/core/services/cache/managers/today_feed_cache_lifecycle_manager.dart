/// **TodayFeedCacheLifecycleManager**
///
/// Manages the complete lifecycle of the Today Feed cache service including:
/// - Service initialization and startup sequence
/// - Dependency injection and service coordination
/// - Shutdown and cleanup procedures
/// - Health monitoring and recovery
/// - Timer and resource management
///
/// This manager extracts the complex lifecycle logic from the main service
/// to improve maintainability and enable better testing of initialization flows.
///
/// **Key Features**:
/// - Environment-aware initialization (production, test, development)
/// - Service dependency ordering and coordination
/// - Proper resource cleanup and disposal
/// - Timer lifecycle management
/// - Configuration validation
/// - Error handling and recovery
///
/// **Usage**:
/// ```dart
/// // Initialize the entire cache system
/// await TodayFeedCacheLifecycleManager.initialize();
///
/// // Check initialization status
/// if (TodayFeedCacheLifecycleManager.isInitialized) {
///   // Use cache services
/// }
///
/// // Clean shutdown
/// await TodayFeedCacheLifecycleManager.dispose();
/// ```
library;

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../today_feed_cache_configuration.dart';
import '../today_feed_cache_health_service.dart';
import '../today_feed_cache_maintenance_service.dart';
import '../today_feed_cache_performance_service.dart';
import '../today_feed_cache_statistics_service.dart';
import '../today_feed_cache_sync_service.dart';
import '../today_feed_cache_warming_service.dart';
import '../today_feed_content_service.dart';
import '../today_feed_timezone_service.dart';
import '../strategies/today_feed_cache_initialization_strategy.dart';

/// **Today Feed Cache Lifecycle Manager**
///
/// Orchestrates the complete lifecycle of the Today Feed cache system
/// with proper service coordination, resource management, and strategy-based
/// initialization following ResponsiveService patterns.
class TodayFeedCacheLifecycleManager {
  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE STATE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialization state flag
  static bool _isInitialized = false;

  /// SharedPreferences instance for cache storage
  static SharedPreferences? _prefs;

  /// Test environment flag for disabling timers and subscriptions
  static bool _isTestEnvironment = false;

  /// Timer for automatic content refresh
  static Timer? _refreshTimer;

  /// Timer for timezone change detection
  static Timer? _timezoneCheckTimer;

  /// Timer for automatic cache cleanup
  static Timer? _automaticCleanupTimer;

  /// List of initialization steps for debugging
  static final List<String> _initializationSteps = [];

  /// Last initialization error for debugging
  static String? _lastInitializationError;

  /// Initialization start time for performance tracking
  static DateTime? _initializationStartTime;

  /// Last initialization strategy used
  static TodayFeedCacheInitializationStrategy? _lastInitializationStrategy;

  /// Last initialization result
  static InitializationResult? _lastInitializationResult;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC LIFECYCLE API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get initialization status
  static bool get isInitialized => _isInitialized;

  /// Get test environment status
  static bool get isTestEnvironment => _isTestEnvironment;

  /// Get SharedPreferences instance (null if not initialized)
  static SharedPreferences? get preferences => _prefs;

  /// Get initialization steps for debugging
  static List<String> get initializationSteps =>
      List.from(_initializationSteps);

  /// Get last initialization error
  static String? get lastInitializationError => _lastInitializationError;

  /// Get last initialization strategy used
  static TodayFeedCacheInitializationStrategy? get lastInitializationStrategy =>
      _lastInitializationStrategy;

  /// Get last initialization result
  static InitializationResult? get lastInitializationResult =>
      _lastInitializationResult;

  /// Set test environment mode to disable timers and subscriptions
  static void setTestEnvironment(bool isTest) {
    _isTestEnvironment = isTest;
    // Update configuration environment based on test flag
    if (isTest) {
      TodayFeedCacheConfiguration.forTestEnvironment();
    } else {
      TodayFeedCacheConfiguration.forProductionEnvironment();
    }
    debugPrint('🧪 Test environment set to: $isTest');
  }

  /// Initialize the Today Feed cache service system using strategy pattern
  ///
  /// Automatically selects the best initialization strategy based on context
  /// and executes it. Sets up all specialized services in proper dependency order
  /// and configures timezone handling, cache validation, and refresh scheduling.
  static Future<void> initialize([InitializationContext? context]) async {
    if (_isInitialized) {
      debugPrint('✅ TodayFeedCacheLifecycleManager already initialized');
      return;
    }

    _initializationStartTime = DateTime.now();
    _initializationSteps.clear();
    _lastInitializationError = null;

    try {
      // Always perform essential initialization first
      await _initializePreferences();
      await _validateConfiguration();

      // Create initialization context if not provided
      context ??= _createInitializationContext();

      // Select and execute initialization strategy
      _lastInitializationStrategy =
          TodayFeedCacheInitializationStrategy.selectStrategy(context);
      debugPrint(
        '📋 Selected initialization strategy: ${_lastInitializationStrategy!.strategyType.name}',
      );

      // Delegate to strategy for the actual initialization work
      _lastInitializationResult = await _executeInitializationStrategy(context);

      if (_lastInitializationResult!.success) {
        _isInitialized = true;
        _logSuccessfulInitialization();
      } else {
        throw Exception(
          'Strategy initialization failed: ${_lastInitializationResult!.error}',
        );
      }
    } catch (e) {
      _lastInitializationError = e.toString();
      debugPrint('❌ Failed to initialize TodayFeedCacheLifecycleManager: $e');
      rethrow;
    }
  }

  /// Execute the selected initialization strategy with fallback handling
  static Future<InitializationResult> _executeInitializationStrategy(
    InitializationContext context,
  ) async {
    try {
      // For test environment, perform minimal additional initialization
      if (context.isTestEnvironment || _isTestEnvironment) {
        return await _executeTestEnvironmentStrategy(context);
      }

      // Use strategy pattern with automatic fallback for other contexts
      return await TodayFeedCacheInitializationStrategy.executeWithAutoSelection(
        context,
      );
    } catch (e) {
      debugPrint(
        '❌ Strategy execution failed, performing manual initialization: $e',
      );

      // Fallback to manual initialization if strategy fails
      await _performManualInitialization();

      final duration = DateTime.now().difference(_initializationStartTime!);
      return InitializationResult.createSuccess(
        strategyType: InitializationStrategyType.recovery,
        duration: duration,
        stepsCompleted: _initializationSteps,
        metrics: {'fallback_mode': true, 'manual_initialization': true},
      );
    }
  }

  /// Execute test environment strategy with essential setup
  static Future<InitializationResult> _executeTestEnvironmentStrategy(
    InitializationContext context,
  ) async {
    final startTime = DateTime.now();
    final steps = <String>[];

    try {
      debugPrint('🧪 Executing test environment strategy with essential setup');
      steps.add('test_strategy_with_essentials');

      // Complete test environment initialization (skip full services but mark as complete)
      _initializationSteps.add('test_mode_completed');
      steps.add('test_mode_completed');

      final duration = DateTime.now().difference(startTime);

      return InitializationResult.createSuccess(
        strategyType: InitializationStrategyType.testEnvironment,
        duration: duration,
        stepsCompleted: steps,
        metrics: {
          'test_mode': true,
          'essential_setup_completed': true,
          'skipped_expensive_operations': true,
        },
        isFullInitialization: false,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      return InitializationResult.createFailure(
        strategyType: InitializationStrategyType.testEnvironment,
        duration: duration,
        error: e.toString(),
        stepsCompleted: steps,
      );
    }
  }

  /// Create initialization context based on current state
  static InitializationContext _createInitializationContext() {
    // Check if this is test environment
    if (_isTestEnvironment || TodayFeedCacheConfiguration.isTestEnvironment) {
      return InitializationContext.testEnvironment();
    }

    // Check if we have a previous error
    if (_lastInitializationError != null) {
      return InitializationContext.recovery(
        previousError: _lastInitializationError!,
      );
    }

    // Check if this is a warm restart (if we've been initialized recently)
    if (_lastInitializationResult != null && _initializationStartTime != null) {
      final timeSinceLastInit = DateTime.now().difference(
        _initializationStartTime!,
      );
      if (timeSinceLastInit <
          TodayFeedCacheConfiguration.warmRestartThreshold) {
        return InitializationContext.warmRestart(
          timeSinceLastInit: timeSinceLastInit,
        );
      }
    }

    // Default to cold start
    return InitializationContext.coldStart(isFirstLaunch: _prefs == null);
  }

  /// Perform manual initialization as fallback
  static Future<void> _performManualInitialization() async {
    // Preferences and configuration are already initialized

    if (!_shouldSkipFullInitialization()) {
      await _initializeServices();
      await _validateCacheVersion();
      await _setupTimezoneHandling();
      await _scheduleBackgroundTasks();
    }
  }

  /// Dispose of resources and cleanup timers
  ///
  /// Properly disposes all services and cleans up timers to prevent memory leaks.
  /// Follows proper disposal order to maintain service dependencies.
  static Future<void> dispose() async {
    if (!_isInitialized) {
      debugPrint(
        '⚠️ TodayFeedCacheLifecycleManager not initialized, skipping disposal',
      );
      return;
    }

    try {
      debugPrint('🧹 Starting TodayFeedCacheLifecycleManager disposal...');

      // Cancel all timers first
      await _cancelAllTimers();

      // Dispose services in reverse dependency order
      await _disposeServices();

      // Clear state
      _clearInternalState();

      debugPrint('✅ TodayFeedCacheLifecycleManager disposed successfully');
    } catch (e) {
      debugPrint('❌ Failed to dispose TodayFeedCacheLifecycleManager: $e');
    }
  }

  /// Reset service for testing (clears all state)
  static void resetForTesting() {
    _isInitialized = false;
    _prefs = null;
    _isTestEnvironment = false;
    _lastInitializationError = null;
    _initializationStartTime = null;
    _initializationSteps.clear();

    // Clear strategy-related state
    _lastInitializationStrategy = null;
    _lastInitializationResult = null;

    // Cancel and clear all timers
    _refreshTimer?.cancel();
    _timezoneCheckTimer?.cancel();
    _automaticCleanupTimer?.cancel();

    _refreshTimer = null;
    _timezoneCheckTimer = null;
    _automaticCleanupTimer = null;

    debugPrint('🔄 TodayFeedCacheLifecycleManager reset for testing');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get timer status for debugging and monitoring
  static Map<String, dynamic> getTimerStatus() {
    return {
      'refresh_timer_active': _refreshTimer != null,
      'timezone_timer_active': _timezoneCheckTimer != null,
      'cleanup_timer_active': _automaticCleanupTimer != null,
      'refresh_timer_id': _refreshTimer?.hashCode,
      'timezone_timer_id': _timezoneCheckTimer?.hashCode,
      'cleanup_timer_id': _automaticCleanupTimer?.hashCode,
    };
  }

  /// Schedule next refresh based on timezone and DST
  ///
  /// Calculates and schedules the next refresh time accounting for timezone
  /// changes and DST transitions.
  static Future<void> scheduleNextRefresh({
    required Future<void> Function() onRefresh,
  }) async {
    _refreshTimer?.cancel();

    try {
      final now = DateTime.now();
      final nextRefreshTime =
          await TodayFeedTimezoneService.calculateNextRefreshTime(now);
      final delay = nextRefreshTime.difference(now);

      if (delay.isNegative) {
        debugPrint(
          '⚠️ Next refresh time is in the past, triggering immediately',
        );
        await onRefresh();
        return;
      }

      _refreshTimer = Timer(delay, () async {
        debugPrint('⏰ Scheduled refresh triggered by lifecycle manager');
        await onRefresh();
      });

      debugPrint('⏰ Next refresh scheduled for: $nextRefreshTime');
      debugPrint(
        '⏰ Time until refresh: ${delay.inHours}h ${delay.inMinutes % 60}m',
      );

      _initializationSteps.add('scheduled_refresh_timer');
    } catch (e) {
      debugPrint('❌ Failed to schedule next refresh: $e');
      // Fallback to configured fallback refresh interval
      final fallbackInterval =
          TodayFeedCacheConfiguration.fallbackRefreshInterval;
      _refreshTimer = Timer(fallbackInterval, () async {
        debugPrint('⏰ Fallback refresh triggered by lifecycle manager');
        await onRefresh();
      });
      _initializationSteps.add('fallback_refresh_timer');
    }
  }

  /// Cancel refresh timer
  static void cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    debugPrint('⏹️ Refresh timer cancelled by lifecycle manager');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE INITIALIZATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialize SharedPreferences
  static Future<void> _initializePreferences() async {
    _prefs ??= await SharedPreferences.getInstance();
    _initializationSteps.add('shared_preferences_initialized');
    debugPrint('📱 SharedPreferences initialized');
  }

  /// Validate configuration before initialization
  static Future<void> _validateConfiguration() async {
    if (!TodayFeedCacheConfiguration.validateConfiguration()) {
      throw Exception('Invalid cache configuration detected');
    }
    _initializationSteps.add('configuration_validated');
    debugPrint('✅ Cache configuration validated');
  }

  /// Check if full initialization should be skipped
  static bool _shouldSkipFullInitialization() {
    return _isTestEnvironment || TodayFeedCacheConfiguration.isTestEnvironment;
  }

  /// Initialize all services in proper dependency order
  static Future<void> _initializeServices() async {
    debugPrint('🔧 Initializing cache services in dependency order...');

    // Core services first (no dependencies)
    await TodayFeedContentService.initialize(_prefs!);
    _initializationSteps.add('content_service_initialized');

    await TodayFeedCacheStatisticsService.initialize(_prefs!);
    _initializationSteps.add('statistics_service_initialized');

    await TodayFeedCacheHealthService.initialize(_prefs!);
    _initializationSteps.add('health_service_initialized');

    await TodayFeedCachePerformanceService.initialize(_prefs!);
    _initializationSteps.add('performance_service_initialized');

    // Timezone service (depends on content service)
    await TodayFeedTimezoneService.initialize(_prefs!);
    _initializationSteps.add('timezone_service_initialized');

    // Sync service (depends on content and timezone services)
    await TodayFeedCacheSyncService.initialize(_prefs!);
    _initializationSteps.add('sync_service_initialized');

    // Maintenance service (depends on all core services)
    await TodayFeedCacheMaintenanceService.initialize(_prefs!);
    _initializationSteps.add('maintenance_service_initialized');

    // Warming service (depends on all other services)
    await TodayFeedCacheWarmingService.initialize(_prefs!);
    _initializationSteps.add('warming_service_initialized');

    debugPrint('✅ All cache services initialized successfully');
  }

  /// Validate cache version and migrate if needed
  static Future<void> _validateCacheVersion() async {
    final cacheVersionKey = TodayFeedCacheConfiguration.cacheVersionKey;
    final currentCacheVersion = TodayFeedCacheConfiguration.currentCacheVersion;

    final currentVersion = _prefs!.getInt(cacheVersionKey) ?? 0;
    if (currentVersion < currentCacheVersion) {
      debugPrint(
        '🔄 Cache version outdated ($currentVersion < $currentCacheVersion), migrating...',
      );

      // Clear old cache data through content service
      await TodayFeedContentService.clearAllContentData();

      // Clear timezone metadata
      await _prefs!.remove(TodayFeedCacheConfiguration.timezoneMetadataKey);
      await _prefs!.remove(TodayFeedCacheConfiguration.lastTimezoneCheckKey);

      // Update version
      await _prefs!.setInt(cacheVersionKey, currentCacheVersion);

      debugPrint('✅ Cache migration completed to version $currentCacheVersion');
      _initializationSteps.add('cache_migration_completed');
    } else {
      _initializationSteps.add('cache_version_current');
    }
  }

  /// Setup timezone handling and change detection
  static Future<void> _setupTimezoneHandling() async {
    try {
      final timezoneChange =
          await TodayFeedTimezoneService.detectAndHandleTimezoneChanges();

      if (timezoneChange != null) {
        debugPrint('🌍 Timezone change detected during initialization');
        _initializationSteps.add('timezone_change_detected');

        // Note: refresh will be handled by the main service
        if (timezoneChange['should_refresh'] == true) {
          _initializationSteps.add('timezone_refresh_required');
        }
      } else {
        _initializationSteps.add('timezone_stable');
      }
    } catch (e) {
      debugPrint('❌ Failed to setup timezone handling: $e');
      _initializationSteps.add('timezone_setup_failed');
      rethrow;
    }
  }

  /// Schedule background tasks and timers
  static Future<void> _scheduleBackgroundTasks() async {
    if (_isTestEnvironment) {
      _initializationSteps.add('background_tasks_skipped_test');
      return;
    }

    // Schedule timezone check timer
    _timezoneCheckTimer = Timer.periodic(
      TodayFeedCacheConfiguration.timezoneCheckInterval,
      (timer) async {
        await TodayFeedTimezoneService.detectAndHandleTimezoneChanges();
      },
    );

    // Note: Refresh timer will be set up by the main service
    // Cleanup timer will be managed by maintenance service

    _initializationSteps.add('background_tasks_scheduled');
    debugPrint('⏰ Background tasks scheduled');
  }

  /// Log successful initialization
  static void _logSuccessfulInitialization() {
    final duration =
        _initializationStartTime != null
            ? DateTime.now().difference(_initializationStartTime!)
            : Duration.zero;
    final env = TodayFeedCacheConfiguration.environment;

    debugPrint('✅ TodayFeedCacheLifecycleManager initialized successfully');
    debugPrint('📊 Environment: ${env.name}');
    debugPrint(
      '🎯 Strategy: ${_lastInitializationStrategy?.strategyType.name ?? 'manual'}',
    );
    debugPrint('⏱️ Initialization time: ${duration.inMilliseconds}ms');

    if (_lastInitializationResult != null) {
      debugPrint(
        '📋 Strategy steps: ${_lastInitializationResult!.stepsCompleted.length}',
      );
      debugPrint(
        '🔧 Full initialization: ${_lastInitializationResult!.isFullInitialization}',
      );
    }

    if (kDebugMode && _initializationSteps.isNotEmpty) {
      debugPrint('🔍 Manual steps: ${_initializationSteps.join(' → ')}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE DISPOSAL METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cancel all active timers
  static Future<void> _cancelAllTimers() async {
    _refreshTimer?.cancel();
    _timezoneCheckTimer?.cancel();
    _automaticCleanupTimer?.cancel();

    _refreshTimer = null;
    _timezoneCheckTimer = null;
    _automaticCleanupTimer = null;

    debugPrint('⏹️ All timers cancelled');
  }

  /// Dispose services in reverse dependency order
  static Future<void> _disposeServices() async {
    // Dispose in reverse order of initialization
    // Note: Only dispose services that have dispose methods implemented

    try {
      await TodayFeedCacheWarmingService.dispose();
      debugPrint('🧹 Warming service disposed');
    } catch (e) {
      debugPrint('⚠️ Failed to dispose warming service: $e');
    }

    try {
      await TodayFeedCacheMaintenanceService.dispose();
      debugPrint('🧹 Maintenance service disposed');
    } catch (e) {
      debugPrint('⚠️ Failed to dispose maintenance service: $e');
    }

    try {
      await TodayFeedCacheSyncService.dispose();
      debugPrint('🧹 Sync service disposed');
    } catch (e) {
      debugPrint('⚠️ Failed to dispose sync service: $e');
    }

    try {
      await TodayFeedTimezoneService.dispose();
      debugPrint('🧹 Timezone service disposed');
    } catch (e) {
      debugPrint('⚠️ Failed to dispose timezone service: $e');
    }

    // These services don't have dispose methods yet - skip them
    debugPrint(
      '📝 Performance, Health, and Statistics services - no dispose needed',
    );

    try {
      await TodayFeedContentService.dispose();
      debugPrint('🧹 Content service disposed');
    } catch (e) {
      debugPrint('⚠️ Failed to dispose content service: $e');
    }
  }

  /// Clear internal state
  static void _clearInternalState() {
    _isInitialized = false;
    _prefs = null;
    _initializationSteps.clear();
    _lastInitializationError = null;
    _initializationStartTime = null;

    // Clear strategy-related state
    _lastInitializationStrategy = null;
    _lastInitializationResult = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIAGNOSTIC AND MONITORING (ENHANCED WITH STRATEGY INFORMATION)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get comprehensive lifecycle status for debugging
  static Map<String, dynamic> getLifecycleStatus() {
    return {
      'is_initialized': _isInitialized,
      'is_test_environment': _isTestEnvironment,
      'has_preferences': _prefs != null,
      'initialization_steps_count': _initializationSteps.length,
      'initialization_steps': _initializationSteps,
      'last_error': _lastInitializationError,
      'timer_status': getTimerStatus(),
      'initialization_time': _initializationStartTime?.toIso8601String(),
      'strategy_info': {
        'last_strategy_type': _lastInitializationStrategy?.strategyType.name,
        'last_strategy_priority': _lastInitializationStrategy?.priority,
        'last_result_success': _lastInitializationResult?.success,
        'last_result_duration_ms':
            _lastInitializationResult?.duration.inMilliseconds,
        'last_result_full_init':
            _lastInitializationResult?.isFullInitialization,
        'strategy_steps_completed':
            _lastInitializationResult?.stepsCompleted.length,
      },
    };
  }

  /// Get initialization performance metrics with strategy details
  static Map<String, dynamic> getInitializationMetrics() {
    final duration =
        _initializationStartTime != null
            ? DateTime.now().difference(_initializationStartTime!)
            : null;

    return {
      'initialization_duration_ms': duration?.inMilliseconds,
      'steps_completed': _initializationSteps.length,
      'has_error': _lastInitializationError != null,
      'environment': TodayFeedCacheConfiguration.environment.name,
      'test_mode': _isTestEnvironment,
      'strategy_metrics': {
        'strategy_type': _lastInitializationStrategy?.strategyType.name,
        'strategy_estimated_time_ms':
            _lastInitializationStrategy?.estimatedTime.inMilliseconds,
        'strategy_actual_duration_ms':
            _lastInitializationResult?.duration.inMilliseconds,
        'strategy_performance_ratio': _calculateStrategyPerformanceRatio(),
        'strategy_memory_requirement_mb':
            _lastInitializationStrategy?.memoryRequirementMB,
        'strategy_requires_full_setup':
            _lastInitializationStrategy?.requiresFullSetup,
        'strategy_priority': _lastInitializationStrategy?.priority,
      },
    };
  }

  /// Calculate strategy performance ratio (actual vs estimated)
  static double? _calculateStrategyPerformanceRatio() {
    if (_lastInitializationStrategy == null ||
        _lastInitializationResult == null) {
      return null;
    }

    final estimated = _lastInitializationStrategy!.estimatedTime.inMilliseconds;
    final actual = _lastInitializationResult!.duration.inMilliseconds;

    if (estimated <= 0) return null;

    return actual / estimated;
  }

  /// Get strategy performance benchmarks for comparison
  static Map<String, dynamic> getStrategyBenchmarks() {
    final benchmarks = TodayFeedCacheInitializationStrategy.getBenchmarks();
    return benchmarks.map((key, value) => MapEntry(key.name, value));
  }
}
