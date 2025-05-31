import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/environment.dart';

/// Production monitoring service for error tracking, performance monitoring,
/// and health checks. Integrates with Sentry for production error tracking.
class MonitoringService {
  static bool _isInitialized = false;
  static final Map<String, int> _counters = {};
  static final Map<String, List<double>> _timings = {};
  static DateTime? _lastHealthCheck;
  static Map<String, dynamic>? _lastHealthStatus;

  /// Initialize monitoring service with Sentry integration
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[MonitoringService] Already initialized');
      return;
    }

    try {
      // Only initialize Sentry in production
      if (Environment.isProduction) {
        await SentryFlutter.init((options) {
          options.dsn = Environment.sentryDsn;
          options.environment = Environment.environment;
          options.release = Environment.appVersion;

          // Performance monitoring configuration
          options.tracesSampleRate = 0.1; // Sample 10% of transactions
          options.profilesSampleRate = 0.1; // Sample 10% of profiles

          // Error filtering and user context configuration
          options.beforeSend = (event, hint) {
            // Filter out non-critical errors in production
            if (event.level == SentryLevel.info ||
                event.level == SentryLevel.debug) {
              return null;
            }

            // Set user context if available
            if (Environment.userId != null) {
              final currentUser = event.user ?? SentryUser();
              return event.copyWith(
                user: currentUser.copyWith(
                  id: Environment.userId,
                  data: {
                    ...?currentUser.data,
                    'environment': Environment.environment,
                    'app_version': Environment.appVersion,
                  },
                ),
              );
            }

            return event;
          };
        });
        debugPrint('[MonitoringService] Sentry initialized for production');
      } else {
        debugPrint(
          '[MonitoringService] Skipping Sentry initialization (not production)',
        );
      }

      _isInitialized = true;
      addBreadcrumb('MonitoringService initialized');
    } catch (e) {
      debugPrint('[MonitoringService] Failed to initialize: $e');
      // Don't let monitoring failures crash the app
      if (kDebugMode) {
        rethrow;
      }
    }
  }

  /// Capture exception with context
  static void captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.error,
  }) {
    try {
      debugPrint('[MonitoringService] Exception: $exception');

      if (Environment.isProduction && _isInitialized) {
        Sentry.captureException(
          exception,
          stackTrace: stackTrace,
          withScope: (scope) {
            if (context != null) {
              scope.setTag('context', context);
            }
            if (extra != null) {
              scope.setContexts('extra', extra);
            }
            scope.level = level;
          },
        );
      }

      // Always increment error counter for metrics
      incrementCounter(
        'errors_total',
        tags: {
          'context': context ?? 'unknown',
          'type': exception.runtimeType.toString(),
        },
      );
    } catch (e) {
      debugPrint('[MonitoringService] Failed to capture exception: $e');
    }
  }

  /// Capture message with level
  static void captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    String? context,
    Map<String, dynamic>? extra,
  }) {
    try {
      debugPrint('[MonitoringService] Message: $message');

      if (Environment.isProduction && _isInitialized) {
        Sentry.captureMessage(
          message,
          level: level,
          withScope: (scope) {
            if (context != null) {
              scope.setTag('context', context);
            }
            if (extra != null) {
              scope.setContexts('extra', extra);
            }
          },
        );
      }
    } catch (e) {
      debugPrint('[MonitoringService] Failed to capture message: $e');
    }
  }

  /// Add breadcrumb for debugging
  static void addBreadcrumb(
    String message, {
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    try {
      if (Environment.isProduction && _isInitialized) {
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: message,
            category: category ?? 'app',
            timestamp: DateTime.now(),
            level: level,
            data: data,
          ),
        );
      }
    } catch (e) {
      debugPrint('[MonitoringService] Failed to add breadcrumb: $e');
    }
  }

  /// Increment counter metric
  static void incrementCounter(String name, {Map<String, String>? tags}) {
    try {
      _counters[name] = (_counters[name] ?? 0) + 1;

      // Send to monitoring service in production
      if (Environment.isProduction) {
        _sendMetric('counter', name, _counters[name]!.toDouble(), tags: tags);
      }
    } catch (e) {
      debugPrint('[MonitoringService] Failed to increment counter: $e');
    }
  }

  /// Record timing metric
  static void recordTiming(
    String name,
    Duration duration, {
    Map<String, String>? tags,
  }) {
    try {
      _timings[name] ??= [];
      _timings[name]!.add(duration.inMilliseconds.toDouble());

      // Keep only last 100 measurements to prevent memory leaks
      if (_timings[name]!.length > 100) {
        _timings[name]!.removeAt(0);
      }

      // Send to monitoring service in production
      if (Environment.isProduction) {
        _sendMetric(
          'timing',
          name,
          duration.inMilliseconds.toDouble(),
          tags: tags,
        );
      }
    } catch (e) {
      debugPrint('[MonitoringService] Failed to record timing: $e');
    }
  }

  /// Record gauge metric
  static void recordGauge(
    String name,
    double value, {
    Map<String, String>? tags,
  }) {
    try {
      // Send to monitoring service in production
      if (Environment.isProduction) {
        _sendMetric('gauge', name, value, tags: tags);
      }
    } catch (e) {
      debugPrint('[MonitoringService] Failed to record gauge: $e');
    }
  }

  /// Get current metrics for health check
  static Map<String, dynamic> getMetrics() {
    return {
      'counters': Map<String, int>.from(_counters),
      'timings': _timings.map(
        (key, value) => MapEntry(key, {
          'count': value.length,
          'avg':
              value.isNotEmpty
                  ? value.reduce((a, b) => a + b) / value.length
                  : 0,
          'min': value.isNotEmpty ? value.reduce((a, b) => a < b ? a : b) : 0,
          'max': value.isNotEmpty ? value.reduce((a, b) => a > b ? a : b) : 0,
        }),
      ),
      'last_health_check': _lastHealthCheck?.toIso8601String(),
      'health_status': _lastHealthStatus,
    };
  }

  /// Send metric to monitoring service
  static Future<void> _sendMetric(
    String type,
    String name,
    double value, {
    Map<String, String>? tags,
  }) async {
    try {
      // In a real implementation, this would send to services like:
      // - DataDog
      // - New Relic
      // - CloudWatch
      // - Custom monitoring endpoint

      final metric = {
        'type': type,
        'name': name,
        'value': value,
        'tags': tags ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'environment': Environment.environment,
        'app_version': Environment.appVersion,
      };

      // For now, just log the metric (replace with actual monitoring service)
      debugPrint('[MonitoringService] Metric: ${json.encode(metric)}');
    } catch (e) {
      debugPrint('[MonitoringService] Failed to send metric: $e');
    }
  }

  /// Set user context for monitoring
  static void setUserContext({
    String? userId,
    String? email,
    Map<String, dynamic>? data,
  }) {
    try {
      if (Environment.isProduction && _isInitialized) {
        Sentry.configureScope((scope) {
          scope.setUser(SentryUser(id: userId, email: email, data: data));
        });
      }
    } catch (e) {
      debugPrint('[MonitoringService] Failed to set user context: $e');
    }
  }

  /// Clear user context (e.g., on logout)
  static void clearUserContext() {
    try {
      if (Environment.isProduction && _isInitialized) {
        Sentry.configureScope((scope) {
          scope.setUser(null);
        });
      }
    } catch (e) {
      debugPrint('[MonitoringService] Failed to clear user context: $e');
    }
  }

  /// Start performance transaction
  static ISentrySpan? startTransaction(
    String name,
    String operation, {
    Map<String, dynamic>? data,
  }) {
    try {
      if (Environment.isProduction && _isInitialized) {
        final transaction = Sentry.startTransaction(name, operation);
        if (data != null) {
          for (final entry in data.entries) {
            transaction.setData(entry.key, entry.value);
          }
        }
        return transaction;
      }
      return null;
    } catch (e) {
      debugPrint('[MonitoringService] Failed to start transaction: $e');
      return null;
    }
  }

  /// Dispose of resources
  static void dispose() {
    try {
      _counters.clear();
      _timings.clear();
      _lastHealthCheck = null;
      _lastHealthStatus = null;
      _isInitialized = false;
    } catch (e) {
      debugPrint('[MonitoringService] Failed to dispose: $e');
    }
  }
}
