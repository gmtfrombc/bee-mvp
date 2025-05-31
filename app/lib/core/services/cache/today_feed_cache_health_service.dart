import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../features/today_feed/domain/models/today_feed_content.dart';
import 'today_feed_cache_performance_service.dart';

/// Health monitoring and diagnostics service for Today Feed cache
class TodayFeedCacheHealthService {
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  // Cache configuration constants from main service
  static const int _maxCacheSizeMB = 10;
  static const int _maxHistoryDays = 30;

  // Cache keys from main service
  static const String _todayContentKey = 'today_feed_content';
  static const String _previousDayContentKey = 'today_feed_previous_day';
  static const String _contentMetadataKey = 'today_feed_metadata';
  static const String _contentHistoryKey = 'today_feed_content_history';
  static const String _timezoneMetadataKey = 'today_feed_timezone_metadata';

  /// Initialize the health service
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _isInitialized = true;
  }

  /// Get comprehensive cache health status with real-time metrics
  static Future<Map<String, dynamic>> getCacheHealthStatus(
    Map<String, dynamic> cacheStats,
    Map<String, dynamic> syncStatus,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheHealthService not initialized');
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Gather all health metrics
      final errors = await _getSyncErrors();
      final hitRateMetrics = await _calculateHitRateMetrics(cacheStats);
      final performanceMetrics = await _calculatePerformanceMetrics();
      final integrityCheck = await performCacheIntegrityCheck();

      stopwatch.stop();

      // Calculate overall health score (0-100)
      final healthScore = _calculateOverallHealthScore(
        cacheStats,
        syncStatus,
        errors,
        hitRateMetrics,
        performanceMetrics,
        integrityCheck,
      );

      // Determine health status
      String healthStatus;
      if (healthScore >= 90) {
        healthStatus = 'healthy';
      } else if (healthScore >= 70) {
        healthStatus = 'degraded';
      } else {
        healthStatus = 'unhealthy';
      }

      final result = {
        'overall_status': healthStatus,
        'health_score': healthScore,
        'timestamp': DateTime.now().toIso8601String(),
        'check_duration_ms': stopwatch.elapsedMilliseconds,
        'cache_stats': cacheStats,
        'sync_status': syncStatus,
        'hit_rate_metrics': hitRateMetrics,
        'performance_metrics': performanceMetrics,
        'integrity_check': integrityCheck,
        'error_summary': {
          'total_errors': errors.length,
          'recent_errors':
              errors.where((e) {
                try {
                  final errorTime = DateTime.parse(e['timestamp'] as String);
                  return DateTime.now().difference(errorTime).inHours <= 24;
                } catch (_) {
                  return false;
                }
              }).length,
          'error_rate': errors.isNotEmpty ? _calculateErrorRate(errors) : 0.0,
        },
        'recommendations': _generateHealthRecommendations(
          healthScore,
          cacheStats,
          syncStatus,
          errors,
        ),
      };

      debugPrint(
        '🏥 Cache health check completed: $healthStatus ($healthScore/100)',
      );
      return result;
    } catch (e) {
      debugPrint('❌ Failed to get cache health status: $e');
      return {
        'overall_status': 'unhealthy',
        'health_score': 0,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Calculate hit rate metrics for cache performance analysis
  static Future<Map<String, dynamic>> _calculateHitRateMetrics(
    Map<String, dynamic> cacheStats,
  ) async {
    try {
      final errors = await _getSyncErrors();

      // Estimate hit rate based on available data
      final hasToday = cacheStats['has_today_content'] as bool? ?? false;
      final hasPrevious =
          cacheStats['has_previous_day_content'] as bool? ?? false;
      final historyCount = cacheStats['content_history_count'] as int? ?? 0;
      final errorCount = errors.length;

      // Calculate estimated hit rate
      double hitRate = 0.0;
      if (hasToday) hitRate += 40.0;
      if (hasPrevious) hitRate += 20.0;
      if (historyCount > 0) hitRate += 20.0;
      if (errorCount < 5) hitRate += 20.0;

      final missRate = 100.0 - hitRate;

      return {
        'hit_rate_percentage': hitRate,
        'miss_rate_percentage': missRate,
        'cache_utilization': _calculateCacheUtilization(cacheStats),
        'content_availability': {
          'today_available': hasToday,
          'previous_day_available': hasPrevious,
          'history_items': historyCount,
        },
      };
    } catch (e) {
      debugPrint('❌ Failed to calculate hit rate metrics: $e');
      return {
        'hit_rate_percentage': 0.0,
        'miss_rate_percentage': 100.0,
        'error': e.toString(),
      };
    }
  }

  /// Calculate cache utilization percentage
  static double _calculateCacheUtilization(Map<String, dynamic> cacheStats) {
    try {
      final sizeBytes = cacheStats['cache_size_bytes'] as int? ?? 0;
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;
      return (sizeBytes / maxSizeBytes * 100).clamp(0.0, 100.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate performance metrics for cache operations
  static Future<Map<String, dynamic>> _calculatePerformanceMetrics() async {
    // Delegate to performance service
    return await TodayFeedCachePerformanceService.calculatePerformanceMetrics();
  }

  /// Perform comprehensive cache integrity check
  static Future<Map<String, dynamic>> performCacheIntegrityCheck() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheHealthService not initialized');
    }

    try {
      final issues = <String>[];
      final warnings = <String>[];

      // Check for corrupted JSON data
      final corruptedKeys = <String>[];
      final keysToCheck = [
        _todayContentKey,
        _previousDayContentKey,
        _contentMetadataKey,
        _contentHistoryKey,
        _timezoneMetadataKey,
      ];

      for (final key in keysToCheck) {
        final value = _prefs!.getString(key);
        if (value != null) {
          try {
            jsonDecode(value);
          } catch (e) {
            corruptedKeys.add(key);
            issues.add('Corrupted JSON data in $key');
          }
        }
      }

      // Check cache size violations
      final cacheSize = await _calculateCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;
      if (cacheSize > maxSizeBytes) {
        issues.add(
          'Cache size (${(cacheSize / 1024 / 1024).toStringAsFixed(2)}MB) exceeds limit (${_maxCacheSizeMB}MB)',
        );
      } else if (cacheSize > maxSizeBytes * 0.8) {
        warnings.add(
          'Cache size approaching limit (${(cacheSize / maxSizeBytes * 100).toStringAsFixed(1)}% full)',
        );
      }

      // Check content consistency
      final todayContent = await _getTodayContent();
      final metadata = await _getContentMetadata();
      if (todayContent != null && metadata != null) {
        final contentDate = todayContent.contentDate;
        final metadataDate = DateTime.parse(metadata['content_date'] as String);
        if (contentDate != metadataDate) {
          issues.add('Content date mismatch between content and metadata');
        }
      }

      // Check for orphaned or outdated content
      final history = await _getContentHistory();
      final outdatedCount =
          history.where((item) {
            try {
              final content = TodayFeedContent.fromJson(item);
              final age = DateTime.now().difference(content.contentDate);
              return age.inDays > _maxHistoryDays;
            } catch (e) {
              return true; // Count corrupted items as outdated
            }
          }).length;

      if (outdatedCount > 0) {
        warnings.add('$outdatedCount outdated content items in history');
      }

      final integrityScore = _calculateIntegrityScore(
        issues,
        warnings,
        corruptedKeys,
      );

      return {
        'integrity_score': integrityScore,
        'is_healthy': issues.isEmpty && corruptedKeys.isEmpty,
        'has_warnings': warnings.isNotEmpty,
        'issues': issues,
        'warnings': warnings,
        'corrupted_keys': corruptedKeys,
        'cache_size_status':
            cacheSize <= maxSizeBytes ? 'within_limit' : 'exceeded',
        'outdated_content_count': outdatedCount,
        'recommendations': _generateIntegrityRecommendations(
          issues,
          warnings,
          corruptedKeys,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to perform cache integrity check: $e');
      return {
        'integrity_score': 0,
        'is_healthy': false,
        'error': e.toString(),
        'recommendations': [
          'Unable to perform integrity check - consider clearing cache',
        ],
      };
    }
  }

  /// Calculate integrity score based on issues found
  static int _calculateIntegrityScore(
    List<String> issues,
    List<String> warnings,
    List<String> corruptedKeys,
  ) {
    int score = 100;

    // Deduct points for issues
    score -= issues.length * 20;
    score -= warnings.length * 10;
    score -= corruptedKeys.length * 25;

    return score.clamp(0, 100);
  }

  /// Generate integrity recommendations
  static List<String> _generateIntegrityRecommendations(
    List<String> issues,
    List<String> warnings,
    List<String> corruptedKeys,
  ) {
    final recommendations = <String>[];

    if (corruptedKeys.isNotEmpty) {
      recommendations.add('Clear corrupted cache data and refresh content');
    }
    if (issues.isNotEmpty) {
      recommendations.add(
        'Resolve critical issues by clearing cache or refreshing content',
      );
    }
    if (warnings.isNotEmpty) {
      recommendations.add('Consider cleanup operations to resolve warnings');
    }
    if (issues.isEmpty && warnings.isEmpty && corruptedKeys.isEmpty) {
      recommendations.add('Cache integrity is excellent - no action needed');
    }

    return recommendations;
  }

  /// Calculate overall health score from all metrics
  static int _calculateOverallHealthScore(
    Map<String, dynamic> cacheStats,
    Map<String, dynamic> syncStatus,
    List<Map<String, dynamic>> errors,
    Map<String, dynamic> hitRateMetrics,
    Map<String, dynamic> performanceMetrics,
    Map<String, dynamic> integrityCheck,
  ) {
    try {
      int score = 100;

      // Content availability (30 points)
      final hasToday = cacheStats['has_today_content'] as bool? ?? false;
      final hasPrevious =
          cacheStats['has_previous_day_content'] as bool? ?? false;
      final historyCount = cacheStats['content_history_count'] as int? ?? 0;

      if (!hasToday) score -= 15;
      if (!hasPrevious) score -= 10;
      if (historyCount == 0) score -= 5;

      // Error rate (25 points)
      final recentErrors =
          errors.where((e) {
            try {
              final errorTime = DateTime.parse(e['timestamp'] as String);
              return DateTime.now().difference(errorTime).inHours <= 24;
            } catch (_) {
              return false;
            }
          }).length;

      if (recentErrors > 5)
        score -= 25;
      else if (recentErrors > 2)
        score -= 15;
      else if (recentErrors > 0)
        score -= 5;

      // Cache performance (20 points)
      final readTime = performanceMetrics['average_read_time_ms'] as int? ?? 0;
      final writeTime =
          performanceMetrics['average_write_time_ms'] as int? ?? 0;

      if (readTime > 200 || writeTime > 100)
        score -= 20;
      else if (readTime > 100 || writeTime > 50)
        score -= 10;

      // Cache utilization (15 points)
      final utilization = _calculateCacheUtilization(cacheStats);
      if (utilization > 90)
        score -= 15;
      else if (utilization > 80)
        score -= 10;

      // Integrity (10 points)
      final integrityScore = integrityCheck['integrity_score'] as int? ?? 100;
      if (integrityScore < 60)
        score -= 10;
      else if (integrityScore < 80)
        score -= 5;

      return score.clamp(0, 100);
    } catch (e) {
      debugPrint('❌ Failed to calculate overall health score: $e');
      return 0;
    }
  }

  /// Calculate error rate from error history
  static double _calculateErrorRate(List<Map<String, dynamic>> errors) {
    if (errors.isEmpty) return 0.0;

    final now = DateTime.now();
    final last24Hours =
        errors.where((e) {
          try {
            final errorTime = DateTime.parse(e['timestamp'] as String);
            return now.difference(errorTime).inHours <= 24;
          } catch (_) {
            return false;
          }
        }).length;

    // Calculate errors per hour over last 24 hours
    return last24Hours / 24.0;
  }

  /// Generate health recommendations based on current status
  static List<String> _generateHealthRecommendations(
    int healthScore,
    Map<String, dynamic> cacheStats,
    Map<String, dynamic> syncStatus,
    List<Map<String, dynamic>> errors,
  ) {
    final recommendations = <String>[];

    if (healthScore >= 90) {
      recommendations.add('Cache health is excellent - no action needed');
      return recommendations;
    }

    final hasToday = cacheStats['has_today_content'] as bool? ?? false;
    final utilization = _calculateCacheUtilization(cacheStats);
    final recentErrors =
        errors.where((e) {
          try {
            final errorTime = DateTime.parse(e['timestamp'] as String);
            return DateTime.now().difference(errorTime).inHours <= 24;
          } catch (_) {
            return false;
          }
        }).length;

    if (!hasToday) {
      recommendations.add(
        'No current content available - check network and refresh',
      );
    }

    if (utilization > 80) {
      recommendations.add('Cache approaching size limit - consider cleanup');
    }

    if (recentErrors > 2) {
      recommendations.add(
        'High error rate detected - check connectivity and app logs',
      );
    }

    if (healthScore < 50) {
      recommendations.add(
        'Critical health issues - consider clearing cache and reinitializing',
      );
    }

    return recommendations;
  }

  /// Get diagnostic information for troubleshooting
  static Future<Map<String, dynamic>> getDiagnosticInfo(
    bool isInitialized,
    bool syncInProgress,
    dynamic connectivitySubscription,
    Map<String, bool> timers,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheHealthService not initialized');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final todayFeedKeys =
          allKeys.where((key) => key.startsWith('today_feed')).toList();

      final diagnosticData = <String, dynamic>{};

      // Collect all Today Feed related data
      for (final key in todayFeedKeys) {
        try {
          final value = prefs.get(key);
          diagnosticData[key] = {
            'type': value.runtimeType.toString(),
            'value':
                value is String && value.length > 200
                    ? '${value.substring(0, 200)}...[truncated]'
                    : value,
            'size_bytes': value is String ? value.length * 2 : 0,
          };
        } catch (e) {
          diagnosticData[key] = {'error': e.toString()};
        }
      }

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'is_initialized': isInitialized,
        'total_keys': todayFeedKeys.length,
        'cache_keys': todayFeedKeys,
        'cache_data': diagnosticData,
        'active_timers': timers,
        'sync_in_progress': syncInProgress,
        'connectivity_listener_active': connectivitySubscription != null,
        'system_info': {
          'current_time': DateTime.now().toIso8601String(),
          'timezone': DateTime.now().timeZoneName,
          'timezone_offset_hours': DateTime.now().timeZoneOffset.inHours,
        },
      };
    } catch (e) {
      debugPrint('❌ Failed to get diagnostic info: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Helper methods for accessing cache data (delegates to main service methods)

  /// Helper method to get today content
  static Future<TodayFeedContent?> _getTodayContent() async {
    try {
      final jsonString = _prefs!.getString(_todayContentKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> json = jsonDecode(jsonString);
      return TodayFeedContent.fromJson(json);
    } catch (e) {
      debugPrint('Failed to get today content for health check: $e');
      return null;
    }
  }

  /// Helper method to get content metadata
  static Future<Map<String, dynamic>?> _getContentMetadata() async {
    try {
      final jsonString = _prefs!.getString(_contentMetadataKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to get content metadata for health check: $e');
      return null;
    }
  }

  /// Helper method to get content history
  static Future<List<Map<String, dynamic>>> _getContentHistory() async {
    try {
      final jsonString = _prefs!.getString(_contentHistoryKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Failed to get content history for health check: $e');
      return [];
    }
  }

  /// Helper method to calculate cache size
  static Future<int> _calculateCacheSize() async {
    try {
      int totalSize = 0;
      final keys = [
        _todayContentKey,
        _previousDayContentKey,
        _contentMetadataKey,
        _contentHistoryKey,
        _timezoneMetadataKey,
      ];

      for (final key in keys) {
        final value = _prefs!.getString(key);
        if (value != null) {
          totalSize += value.length * 2; // Approximate UTF-16 encoding
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Failed to calculate cache size: $e');
      return 0;
    }
  }

  /// Helper method to get sync errors - delegates to main service
  static Future<List<Map<String, dynamic>>> _getSyncErrors() async {
    try {
      final errorsJson = _prefs!.getString('today_feed_sync_errors');
      if (errorsJson == null) return [];

      final List<dynamic> errorsList = jsonDecode(errorsJson);
      return errorsList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Failed to get sync errors: $e');
      return [];
    }
  }
}
