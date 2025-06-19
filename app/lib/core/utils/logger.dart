import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

// Global logger instance configured with pretty printing in debug builds
// and more concise output in release builds.
final Logger _logger = Logger(
  level: kDebugMode ? Level.debug : Level.warning,
  printer: PrettyPrinter(
    colors: false,
    printEmojis: false,
    // dateTimeFormat determines time display; use onlyTime for brevity.
    noBoxingByDefault: true,
  ),
);

/// Debug-level log – printed only in debug and profile builds.
void logD(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  if (!kDebugMode) return;
  _logger.d(message, error: error, stackTrace: stackTrace);
}

/// Info-level log – always printed.
void logI(dynamic message, [dynamic error, StackTrace? stackTrace]) {
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
