import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Types of errors that can occur in the app
enum ErrorType {
  network,
  authentication,
  server,
  validation,
  unknown,
  offline,
  timeout,
  rateLimit,
}

/// Error severity levels
enum ErrorSeverity {
  low, // User can continue, minor inconvenience
  medium, // Some functionality affected
  high, // Major functionality broken
  critical, // App unusable
}

/// Comprehensive error information
class AppError {
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String? userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  final bool isRetryable;

  AppError({
    required this.type,
    required this.severity,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
    this.context,
    this.isRetryable = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create error from exception
  factory AppError.fromException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (exception is SocketException) {
      return AppError(
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: 'Network connection failed',
        userMessage: 'Please check your internet connection and try again.',
        originalError: exception,
        stackTrace: stackTrace,
        context: context,
        isRetryable: true,
      );
    }

    if (exception is TimeoutException) {
      return AppError(
        type: ErrorType.timeout,
        severity: ErrorSeverity.medium,
        message: 'Request timed out',
        userMessage: 'The request took too long. Please try again.',
        originalError: exception,
        stackTrace: stackTrace,
        context: context,
        isRetryable: true,
      );
    }

    if (exception is AuthException) {
      return AppError(
        type: ErrorType.authentication,
        severity: ErrorSeverity.high,
        message: 'Authentication failed: ${exception.message}',
        userMessage: 'Please sign in again to continue.',
        originalError: exception,
        stackTrace: stackTrace,
        context: context,
        isRetryable: false,
      );
    }

    if (exception is PostgrestException) {
      final isServerError =
          exception.code != null && exception.code!.startsWith('5');

      return AppError(
        type: ErrorType.server,
        severity: isServerError ? ErrorSeverity.high : ErrorSeverity.medium,
        message: 'Database error: ${exception.message}',
        userMessage:
            isServerError
                ? 'Server is temporarily unavailable. Please try again later.'
                : 'Unable to process your request. Please try again.',
        originalError: exception,
        stackTrace: stackTrace,
        context: context,
        isRetryable: isServerError,
      );
    }

    // Default unknown error
    return AppError(
      type: ErrorType.unknown,
      severity: ErrorSeverity.medium,
      message: 'Unexpected error: ${exception.toString()}',
      userMessage: 'Something went wrong. Please try again.',
      originalError: exception,
      stackTrace: stackTrace,
      context: context,
      isRetryable: true,
    );
  }

  @override
  String toString() {
    return 'AppError(type: $type, severity: $severity, message: $message)';
  }
}

/// Retry configuration for different error types
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });

  /// Get retry config for specific error type
  static RetryConfig forErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(seconds: 2),
          backoffMultiplier: 2.0,
        );
      case ErrorType.timeout:
        return const RetryConfig(
          maxAttempts: 2,
          initialDelay: Duration(seconds: 3),
          backoffMultiplier: 1.5,
        );
      case ErrorType.server:
        return const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(seconds: 5),
          backoffMultiplier: 2.0,
          maxDelay: Duration(minutes: 1),
        );
      case ErrorType.rateLimit:
        return const RetryConfig(
          maxAttempts: 2,
          initialDelay: Duration(seconds: 10),
          backoffMultiplier: 3.0,
          maxDelay: Duration(minutes: 5),
        );
      default:
        return const RetryConfig(maxAttempts: 1); // No retry for other types
    }
  }
}

/// Service for handling errors and retry logic
class ErrorHandlingService {
  static final List<AppError> _errorHistory = [];
  static const int _maxErrorHistory = 100;

  /// Execute a function with automatic retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? retryConfig,
    String? operationName,
    Map<String, dynamic>? context,
  }) async {
    int attempt = 0;
    AppError? lastError;
    final config = retryConfig ?? const RetryConfig();

    while (attempt < config.maxAttempts) {
      attempt++;

      try {
        final result = await operation();

        // Log successful retry if this wasn't the first attempt
        if (attempt > 1) {
          debugPrint(
            '✅ Operation succeeded on attempt $attempt: $operationName',
          );
        }

        return result;
      } catch (e, stackTrace) {
        lastError = AppError.fromException(
          e,
          stackTrace: stackTrace,
          context: {
            ...?context,
            'operation': operationName,
            'attempt': attempt,
            'maxAttempts': config.maxAttempts,
          },
        );

        _logError(lastError);

        // Don't retry if error is not retryable or this was the last attempt
        if (!lastError.isRetryable || attempt >= config.maxAttempts) {
          break;
        }

        // Calculate delay for next attempt
        final delay = Duration(
          milliseconds:
              (config.initialDelay.inMilliseconds *
                      (config.backoffMultiplier * (attempt - 1)))
                  .round(),
        );

        final actualDelay = delay > config.maxDelay ? config.maxDelay : delay;

        debugPrint(
          '⏳ Retrying operation in ${actualDelay.inSeconds}s (attempt $attempt/${config.maxAttempts}): $operationName',
        );

        await Future.delayed(actualDelay);
      }
    }

    // All attempts failed, throw the last error
    throw lastError!;
  }

  /// Log error to history and console
  static void _logError(AppError error) {
    // Add to error history
    _errorHistory.add(error);

    // Keep history size manageable
    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeAt(0);
    }

    // Log to console based on severity
    final logMessage = '${error.type.name.toUpperCase()}: ${error.message}';

    switch (error.severity) {
      case ErrorSeverity.low:
        debugPrint('ℹ️ $logMessage');
        break;
      case ErrorSeverity.medium:
        debugPrint('⚠️ $logMessage');
        break;
      case ErrorSeverity.high:
        debugPrint('🚨 $logMessage');
        break;
      case ErrorSeverity.critical:
        debugPrint('💥 CRITICAL: $logMessage');
        break;
    }

    // Print stack trace for high severity errors in debug mode
    if (kDebugMode &&
        error.severity.index >= ErrorSeverity.high.index &&
        error.stackTrace != null) {
      debugPrint('Stack trace: ${error.stackTrace}');
    }
  }

  /// Get recent errors for debugging
  static List<AppError> getRecentErrors({int? limit}) {
    final errors = List<AppError>.from(_errorHistory);
    if (limit != null && limit < errors.length) {
      return errors.sublist(errors.length - limit);
    }
    return errors;
  }

  /// Clear error history
  static void clearErrorHistory() {
    _errorHistory.clear();
  }

  /// Get error statistics
  static Map<String, dynamic> getErrorStats() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));

    final recentErrors =
        _errorHistory
            .where((error) => error.timestamp.isAfter(last24Hours))
            .toList();

    final errorsByType = <ErrorType, int>{};
    final errorsBySeverity = <ErrorSeverity, int>{};

    for (final error in recentErrors) {
      errorsByType[error.type] = (errorsByType[error.type] ?? 0) + 1;
      errorsBySeverity[error.severity] =
          (errorsBySeverity[error.severity] ?? 0) + 1;
    }

    return {
      'totalErrors': _errorHistory.length,
      'recentErrors': recentErrors.length,
      'errorsByType': errorsByType.map((k, v) => MapEntry(k.name, v)),
      'errorsBySeverity': errorsBySeverity.map((k, v) => MapEntry(k.name, v)),
      'lastError':
          _errorHistory.isNotEmpty ? _errorHistory.last.toString() : null,
    };
  }
}
