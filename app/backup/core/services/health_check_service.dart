import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/environment.dart';
import 'offline_cache_service.dart';
import 'firebase_service.dart';
import 'monitoring_service.dart';

/// Health check service for production monitoring
/// Provides comprehensive system health checks including database, cache, and external services
class HealthCheckService {
  static DateTime? _lastHealthCheck;
  static Map<String, dynamic>? _lastHealthStatus;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Get comprehensive health status
  static Future<Map<String, dynamic>> getHealthStatus({
    bool forceRefresh = false,
  }) async {
    // Return cached result if available and not expired
    if (!forceRefresh &&
        _lastHealthCheck != null &&
        _lastHealthStatus != null &&
        DateTime.now().difference(_lastHealthCheck!) < _cacheValidityDuration) {
      return _lastHealthStatus!;
    }

    final stopwatch = Stopwatch()..start();
    final checks = <String, dynamic>{};

    try {
      // Run all health checks in parallel for better performance
      final results = await Future.wait([
        _checkDatabase(),
        _checkCache(),
        _checkSupabase(),
        _checkFirebase(),
        _checkConnectivity(),
        _checkMemoryUsage(),
        _checkPerformance(),
      ]);

      checks['database'] = results[0];
      checks['cache'] = results[1];
      checks['supabase'] = results[2];
      checks['firebase'] = results[3];
      checks['connectivity'] = results[4];
      checks['memory'] = results[5];
      checks['performance'] = results[6];
    } catch (e) {
      MonitoringService.captureException(e, context: 'health_check');
      checks['error'] = {
        'status': 'unhealthy',
        'message': 'Health check failed: ${e.toString()}',
      };
    }

    stopwatch.stop();

    // Calculate overall health status
    final healthyChecks =
        checks.values
            .where((check) => check is Map && check['status'] == 'healthy')
            .length;
    final totalChecks = checks.length;
    final healthScore =
        totalChecks > 0 ? (healthyChecks / totalChecks * 100).round() : 0;

    String overallStatus;
    if (healthScore >= 90) {
      overallStatus = 'healthy';
    } else if (healthScore >= 70) {
      overallStatus = 'degraded';
    } else {
      overallStatus = 'unhealthy';
    }

    final healthStatus = {
      'status': overallStatus,
      'health_score': healthScore,
      'timestamp': DateTime.now().toIso8601String(),
      'version': Environment.appVersion,
      'environment': Environment.environment,
      'response_time_ms': stopwatch.elapsedMilliseconds,
      'checks': checks,
      'summary': {
        'total_checks': totalChecks,
        'healthy_checks': healthyChecks,
        'degraded_checks':
            checks.values
                .where((check) => check is Map && check['status'] == 'degraded')
                .length,
        'unhealthy_checks':
            checks.values
                .where(
                  (check) => check is Map && check['status'] == 'unhealthy',
                )
                .length,
      },
    };

    // Cache the result
    _lastHealthCheck = DateTime.now();
    _lastHealthStatus = healthStatus;

    // Record health metrics
    MonitoringService.recordGauge('health_score', healthScore.toDouble());
    MonitoringService.recordTiming(
      'health_check_duration',
      Duration(milliseconds: stopwatch.elapsedMilliseconds),
    );

    return healthStatus;
  }

  /// Check database connectivity and performance
  static Future<Map<String, dynamic>> _checkDatabase() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Test a simple query to verify database connectivity
      await Supabase.instance.client
          .from('daily_engagement_scores')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));

      stopwatch.stop();

      // Check response time
      final responseTime = stopwatch.elapsedMilliseconds;
      String status;
      if (responseTime < 500) {
        status = 'healthy';
      } else if (responseTime < 2000) {
        status = 'degraded';
      } else {
        status = 'unhealthy';
      }

      return {
        'status': status,
        'response_time_ms': responseTime,
        'connection': 'active',
        'query_success': true,
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'connection': 'failed',
        'query_success': false,
      };
    }
  }

  /// Check cache health and performance
  static Future<Map<String, dynamic>> _checkCache() async {
    try {
      final stats = await OfflineCacheService.getEnhancedCacheStats();
      final healthScore = stats['healthScore'] ?? 0;
      final hitRate = stats['hitRate'] ?? 0;

      String status;
      if (healthScore > 80 && hitRate > 70) {
        status = 'healthy';
      } else if (healthScore > 60 && hitRate > 50) {
        status = 'degraded';
      } else {
        status = 'unhealthy';
      }

      return {
        'status': status,
        'health_score': healthScore,
        'cache_size': stats['totalSize'] ?? 0,
        'hit_rate': hitRate,
        'miss_rate': stats['missRate'] ?? 0,
        'entries_count': stats['entriesCount'] ?? 0,
      };
    } catch (e) {
      return {'status': 'unhealthy', 'error': e.toString(), 'health_score': 0};
    }
  }

  /// Check Supabase service health
  static Future<Map<String, dynamic>> _checkSupabase() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Test Supabase connection with a simple auth check
      final response = await Supabase.instance.client.auth.getUser();

      stopwatch.stop();

      return {
        'status': 'healthy',
        'response_time_ms': stopwatch.elapsedMilliseconds,
        'authenticated': response.user != null,
        'user_id': response.user?.id,
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'authenticated': false,
      };
    }
  }

  /// Check Firebase service health
  static Future<Map<String, dynamic>> _checkFirebase() async {
    try {
      final isInitialized = FirebaseService.isInitialized;

      if (!isInitialized) {
        return {
          'status': 'degraded',
          'initialized': false,
          'message': 'Firebase not initialized (graceful fallback active)',
        };
      }

      final isAvailable = FirebaseService.isAvailable;

      return {
        'status': isAvailable ? 'healthy' : 'degraded',
        'initialized': isInitialized,
        'available': isAvailable,
        'project_id': FirebaseService.currentProjectId,
        'error': FirebaseService.initializationError,
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'initialized': false,
        'error': e.toString(),
      };
    }
  }

  /// Check network connectivity
  static Future<Map<String, dynamic>> _checkConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      final isConnected =
          !connectivityResults.contains(ConnectivityResult.none);

      // Test actual internet connectivity with a simple HTTP request
      bool internetAccess = false;
      String? internetError;

      if (isConnected) {
        try {
          final result = await InternetAddress.lookup(
            'google.com',
          ).timeout(const Duration(seconds: 5));
          internetAccess = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        } catch (e) {
          internetError = e.toString();
        }
      }

      String status;
      if (isConnected && internetAccess) {
        status = 'healthy';
      } else if (isConnected) {
        status = 'degraded';
      } else {
        status = 'unhealthy';
      }

      return {
        'status': status,
        'connectivity_types': connectivityResults.map((e) => e.name).toList(),
        'is_connected': isConnected,
        'internet_access': internetAccess,
        'internet_error': internetError,
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'is_connected': false,
        'internet_access': false,
      };
    }
  }

  /// Check memory usage
  static Future<Map<String, dynamic>> _checkMemoryUsage() async {
    try {
      // Note: Detailed memory info is limited on mobile platforms
      // This is a simplified check

      final info = ProcessInfo.currentRss;
      final memoryMB = info / (1024 * 1024);

      String status;
      if (memoryMB < 50) {
        status = 'healthy';
      } else if (memoryMB < 100) {
        status = 'degraded';
      } else {
        status = 'unhealthy';
      }

      return {
        'status': status,
        'memory_mb': memoryMB.round(),
        'rss_bytes': info,
      };
    } catch (e) {
      return {'status': 'unhealthy', 'error': e.toString(), 'memory_mb': 0};
    }
  }

  /// Check performance metrics
  static Future<Map<String, dynamic>> _checkPerformance() async {
    try {
      final metrics = MonitoringService.getMetrics();
      final timings = metrics['timings'] as Map<String, dynamic>? ?? {};

      // Check average response times
      bool hasSlowOperations = false;
      final slowOperations = <String>[];

      for (final entry in timings.entries) {
        final timing = entry.value as Map<String, dynamic>;
        final avgTime = timing['avg'] as double? ?? 0;

        if (avgTime > 2000) {
          // 2 seconds threshold
          hasSlowOperations = true;
          slowOperations.add('${entry.key}: ${avgTime.round()}ms');
        }
      }

      String status;
      if (!hasSlowOperations) {
        status = 'healthy';
      } else if (slowOperations.length <= 2) {
        status = 'degraded';
      } else {
        status = 'unhealthy';
      }

      return {
        'status': status,
        'slow_operations': slowOperations,
        'total_operations': timings.length,
        'metrics_available': timings.isNotEmpty,
      };
    } catch (e) {
      return {'status': 'unhealthy', 'error': e.toString()};
    }
  }

  /// Get a simple health status endpoint response
  static Future<Map<String, dynamic>> getSimpleHealthCheck() async {
    try {
      final health = await getHealthStatus();
      return {
        'status': health['status'],
        'timestamp': health['timestamp'],
        'version': health['version'],
        'environment': health['environment'],
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// Clear cached health status
  static void clearCache() {
    _lastHealthCheck = null;
    _lastHealthStatus = null;
  }
}
