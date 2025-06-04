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

/// **Today Feed Cache Lifecycle Manager**
///
/// Orchestrates the complete lifecycle of the Today Feed cache system
/// with proper service coordination and resource management.
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

  /// Initialize the Today Feed cache service system
  ///
  /// Sets up all specialized services in proper dependency order and configures
  /// timezone handling, cache validation, and refresh scheduling. Optimized for
  /// test environments to skip expensive operations.
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ TodayFeedCacheLifecycleManager already initialized');
      return;
    }

    _initializationStartTime = DateTime.now();
    _initializationSteps.clear();
    _lastInitializationError = null;

    try {
      await _initializePreferences();
      await _validateConfiguration();

      // Handle test environment early exit
      if (_shouldSkipFullInitialization()) {
        await _completeTestInitialization();
        return;
      }

      await _initializeServices();
      await _validateCacheVersion();
      await _setupTimezoneHandling();
      await _scheduleBackgroundTasks();

      _isInitialized = true;
      _logSuccessfulInitialization();
    } catch (e) {
      _lastInitializationError = e.toString();
      debugPrint('❌ Failed to initialize TodayFeedCacheLifecycleManager: $e');
      rethrow;
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

  /// Complete test environment initialization
  static Future<void> _completeTestInitialization() async {
    _isInitialized = true;
    _initializationSteps.add('test_mode_completed');
    debugPrint(
      '✅ TodayFeedCacheLifecycleManager test mode - skipping full initialization',
    );

    final duration = DateTime.now().difference(_initializationStartTime!);
    debugPrint(
      '⏱️ Test initialization completed in ${duration.inMilliseconds}ms',
    );
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
    final duration = DateTime.now().difference(_initializationStartTime!);
    final env = TodayFeedCacheConfiguration.environment;

    debugPrint('✅ TodayFeedCacheLifecycleManager initialized successfully');
    debugPrint('📊 Environment: ${env.name}');
    debugPrint('⏱️ Initialization time: ${duration.inMilliseconds}ms');
    debugPrint('📋 Steps completed: ${_initializationSteps.length}');

    if (kDebugMode) {
      debugPrint(
        '🔍 Initialization steps: ${_initializationSteps.join(' → ')}',
      );
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
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIAGNOSTIC AND MONITORING
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
    };
  }

  /// Get initialization performance metrics
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
    };
  }
}
