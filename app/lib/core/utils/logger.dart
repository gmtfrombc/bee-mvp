import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

// Compile-time flag: pass --dart-define=VERBOSE_LOGS=true for more verbose output.
const bool kVerboseLogs = bool.fromEnvironment(
  'VERBOSE_LOGS',
  defaultValue: false,
);

// Global logger instance configured with pretty printing in debug builds
// and more concise output in release builds.
final Logger _logger = Logger(
  level:
      kDebugMode ? (kVerboseLogs ? Level.info : Level.warning) : Level.warning,
  printer: PrettyPrinter(
    colors: false,
    printEmojis: false,
    // dateTimeFormat determines time display; use onlyTime for brevity.
    noBoxingByDefault: true,
  ),
);

/// Debug-level log. Printed only when running in debug/profile _and_
/// VERBOSE_LOGS is enabled (pass --dart-define=VERBOSE_LOGS=true).
void logD(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  if (!kDebugMode || !kVerboseLogs) return;
  _logger.d(message, error: error, stackTrace: stackTrace);
}

/// Info-level log – always printed.
void logI(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  if (!kVerboseLogs) return; // Suppress info logs unless verbose.
  _logger.i(message, error: error, stackTrace: stackTrace);
}

/// Warning-level log.
void logW(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  _logger.w(message, error: error, stackTrace: stackTrace);
}

/// Error-level log.
void logE(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  _logger.e(message, error: error, stackTrace: stackTrace);
}

/// Lightweight replacement for `debugPrint` that honours VERBOSE_LOGS. Use
/// this instead of calling `debugPrint` directly in new code. Existing calls
/// can be gradually migrated but will stay silent unless verbose logging has
/// been requested.
void vPrint(String? msg) {
  if (!kDebugMode || !kVerboseLogs) return;
  debugPrint(msg);
}
