import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'offline_cache_error_service.dart';

/// Service for managing pending action queue with priority and retry logic
class OfflineCacheActionService {
  static const String _pendingActionsKey = 'pending_actions';

  static SharedPreferences? _prefs;

  /// Initialize the action service
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    await _cleanupExpiredDataSafe();
  }

  /// Clean up expired data safely without recursive initialization
  static Future<void> _cleanupExpiredDataSafe() async {
    try {
      // Get pending actions without calling initialize() recursively
      final jsonString = _prefs!.getString(_pendingActionsKey);
      if (jsonString == null) return;

      final pendingActions =
          (jsonDecode(jsonString) as List<dynamic>)
              .cast<Map<String, dynamic>>();

      final cutoffTime = DateTime.now().subtract(const Duration(days: 7));

      final validActions =
          pendingActions.where((action) {
            final queuedAt = DateTime.tryParse(action['queued_at'] ?? '');
            return queuedAt != null && queuedAt.isAfter(cutoffTime);
          }).toList();

      if (validActions.length != pendingActions.length) {
        await _prefs!.setString(_pendingActionsKey, jsonEncode(validActions));
        debugPrint(
          '🧹 Cleaned up ${pendingActions.length - validActions.length} expired pending actions',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to clean up expired data: $e');
    }
  }

  /// Enhanced pending action management with priority and retry logic
  static Future<void> queuePendingAction(
    Map<String, dynamic> action, {
    int priority = 1, // 1 = low, 2 = medium, 3 = high
    int maxRetries = 3,
  }) async {
    try {
      final existingActions = await getPendingActions();

      // Check for duplicate actions
      final isDuplicate = existingActions.any(
        (existing) =>
            existing['type'] == action['type'] &&
            existing['data'] == action['data'],
      );

      if (isDuplicate) {
        debugPrint('⚠️ Skipping duplicate pending action: ${action['type']}');
        return;
      }

      existingActions.add({
        ...action,
        'queued_at': DateTime.now().toIso8601String(),
        'priority': priority,
        'max_retries': maxRetries,
        'retry_count': 0,
      });

      // Sort by priority (high to low)
      existingActions.sort(
        (a, b) => (b['priority'] ?? 1).compareTo(a['priority'] ?? 1),
      );

      await _prefs!.setString(_pendingActionsKey, jsonEncode(existingActions));
      debugPrint(
        '✅ Enhanced action queued: ${action['type']} (priority: $priority)',
      );
    } catch (e) {
      debugPrint('❌ Failed to queue action: $e');
    }
  }

  /// Process pending actions when back online
  static Future<List<Map<String, dynamic>>> processPendingActions() async {
    try {
      final pendingActions = await getPendingActions();
      if (pendingActions.isEmpty) return [];

      debugPrint('🔄 Processing ${pendingActions.length} pending actions');

      final processedActions = <Map<String, dynamic>>[];
      final failedActions = <Map<String, dynamic>>[];

      for (final action in pendingActions) {
        try {
          // Mark action as processed (this would be handled by the calling service)
          processedActions.add(action);
          debugPrint('✅ Processed pending action: ${action['type']}');
        } catch (e) {
          // Increment retry count
          final retryCount = (action['retry_count'] ?? 0) + 1;
          final maxRetries = action['max_retries'] ?? 3;

          if (retryCount < maxRetries) {
            action['retry_count'] = retryCount;
            failedActions.add(action);
            debugPrint(
              '⚠️ Action failed, will retry ($retryCount/$maxRetries): ${action['type']}',
            );
          } else {
            debugPrint(
              '❌ Action failed permanently after $maxRetries attempts: ${action['type']}',
            );
            await OfflineCacheErrorService.queueError({
              'type': 'pending_action_failed',
              'action': action,
              'error': e.toString(),
            });
          }
        }
      }

      // Update pending actions list with only failed actions that can be retried
      await _prefs!.setString(_pendingActionsKey, jsonEncode(failedActions));

      return processedActions;
    } catch (e) {
      debugPrint('❌ Failed to process pending actions: $e');
      return [];
    }
  }

  /// Get all pending actions
  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    try {
      final jsonString = _prefs!.getString(_pendingActionsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get pending actions: $e');
      return [];
    }
  }

  /// Remove a pending action (after successful execution)
  static Future<void> removePendingAction(Map<String, dynamic> action) async {
    try {
      final existingActions = await getPendingActions();
      existingActions.removeWhere(
        (a) =>
            a['type'] == action['type'] &&
            a['queued_at'] == action['queued_at'],
      );

      await _prefs!.setString(_pendingActionsKey, jsonEncode(existingActions));
      debugPrint('✅ Pending action removed: ${action['type']}');
    } catch (e) {
      debugPrint('❌ Failed to remove pending action: $e');
    }
  }

  /// Clear all pending actions
  static Future<void> clearPendingActions() async {
    await _prefs!.remove(_pendingActionsKey);
    debugPrint('✅ All pending actions cleared');
  }
}
