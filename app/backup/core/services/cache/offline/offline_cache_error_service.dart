import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Error management and queuing service for offline cache
class OfflineCacheErrorService {
  // SharedPreferences key for error queue
  static const String _errorQueueKey = 'error_queue';

  static SharedPreferences? _prefs;

  /// Initialize the error service with SharedPreferences
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  /// Queue an error for later reporting
  static Future<void> queueError(Map<String, dynamic> error) async {
    try {
      final existingErrors = await getQueuedErrors();
      existingErrors.add({
        ...error,
        'queued_at': DateTime.now().toIso8601String(),
      });

      // Keep only the last 50 errors to prevent storage bloat
      if (existingErrors.length > 50) {
        existingErrors.removeRange(0, existingErrors.length - 50);
      }

      await _prefs!.setString(_errorQueueKey, jsonEncode(existingErrors));
      debugPrint('✅ Error queued for reporting');
    } catch (e) {
      debugPrint('❌ Failed to queue error: $e');
    }
  }

  /// Get all queued errors
  static Future<List<Map<String, dynamic>>> getQueuedErrors() async {
    try {
      final jsonString = _prefs!.getString(_errorQueueKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get queued errors: $e');
      return [];
    }
  }

  /// Clear all queued errors
  static Future<void> clearQueuedErrors() async {
    await _prefs!.remove(_errorQueueKey);
    debugPrint('✅ All queued errors cleared');
  }

  /// Clean up old error queue entries (keep only recent ones)
  /// Used by cache cleanup operations
  static Future<void> cleanupOldErrors({int maxErrors = 5}) async {
    try {
      final queuedErrors = await getQueuedErrors();
      if (queuedErrors.length > maxErrors) {
        final recentErrors = queuedErrors.take(maxErrors).toList();
        await _prefs!.setString(_errorQueueKey, jsonEncode(recentErrors));
        debugPrint(
          '🧹 Cleaned up ${queuedErrors.length - maxErrors} old error entries',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup old errors: $e');
    }
  }

  /// Get error queue statistics
  static Future<Map<String, dynamic>> getErrorStats() async {
    try {
      final errors = await getQueuedErrors();
      final now = DateTime.now();

      // Count errors by age
      int recentErrors = 0; // Last hour
      int todayErrors = 0; // Last 24 hours

      for (final error in errors) {
        final queuedAtStr = error['queued_at'] as String?;
        if (queuedAtStr != null) {
          final queuedAt = DateTime.tryParse(queuedAtStr);
          if (queuedAt != null) {
            final age = now.difference(queuedAt);
            if (age.inHours < 1) recentErrors++;
            if (age.inHours < 24) todayErrors++;
          }
        }
      }

      return {
        'totalErrors': errors.length,
        'recentErrors': recentErrors,
        'todayErrors': todayErrors,
        'oldestError': errors.isNotEmpty ? errors.first['queued_at'] : null,
        'newestError': errors.isNotEmpty ? errors.last['queued_at'] : null,
      };
    } catch (e) {
      debugPrint('❌ Failed to get error stats: $e');
      return {
        'totalErrors': 0,
        'recentErrors': 0,
        'todayErrors': 0,
        'oldestError': null,
        'newestError': null,
      };
    }
  }
}
