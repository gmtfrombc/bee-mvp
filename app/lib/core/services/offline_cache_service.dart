import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../features/momentum/domain/models/momentum_data.dart';

/// Service for caching momentum data offline
class OfflineCacheService {
  static const String _momentumDataKey = 'cached_momentum_data';
  static const String _lastUpdateKey = 'momentum_last_update';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _errorQueueKey = 'error_queue';

  static SharedPreferences? _prefs;

  /// Initialize the cache service
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Cache momentum data
  static Future<void> cacheMomentumData(MomentumData data) async {
    await initialize();

    try {
      final jsonData = data.toJson();
      await _prefs!.setString(_momentumDataKey, jsonEncode(jsonData));
      await _prefs!.setString(_lastUpdateKey, DateTime.now().toIso8601String());

      debugPrint('✅ Momentum data cached successfully');
    } catch (e) {
      debugPrint('❌ Failed to cache momentum data: $e');
    }
  }

  /// Get cached momentum data
  static Future<MomentumData?> getCachedMomentumData() async {
    await initialize();

    try {
      final jsonString = _prefs!.getString(_momentumDataKey);
      if (jsonString == null) return null;

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return MomentumData.fromJson(jsonData);
    } catch (e) {
      debugPrint('❌ Failed to load cached momentum data: $e');
      return null;
    }
  }

  /// Check if cached data is still valid (within last 24 hours)
  static Future<bool> isCachedDataValid() async {
    await initialize();

    try {
      final lastUpdateString = _prefs!.getString(_lastUpdateKey);
      if (lastUpdateString == null) return false;

      final lastUpdate = DateTime.parse(lastUpdateString);
      final now = DateTime.now();
      final difference = now.difference(lastUpdate);

      // Consider data valid if it's less than 24 hours old
      return difference.inHours < 24;
    } catch (e) {
      debugPrint('❌ Failed to check cache validity: $e');
      return false;
    }
  }

  /// Get the age of cached data
  static Future<Duration?> getCachedDataAge() async {
    await initialize();

    try {
      final lastUpdateString = _prefs!.getString(_lastUpdateKey);
      if (lastUpdateString == null) return null;

      final lastUpdate = DateTime.parse(lastUpdateString);
      return DateTime.now().difference(lastUpdate);
    } catch (e) {
      debugPrint('❌ Failed to get cache age: $e');
      return null;
    }
  }

  /// Queue an action to be performed when back online
  static Future<void> queuePendingAction(Map<String, dynamic> action) async {
    await initialize();

    try {
      final existingActions = await getPendingActions();
      existingActions.add({
        ...action,
        'queued_at': DateTime.now().toIso8601String(),
      });

      await _prefs!.setString(_pendingActionsKey, jsonEncode(existingActions));
      debugPrint('✅ Action queued for when online: ${action['type']}');
    } catch (e) {
      debugPrint('❌ Failed to queue action: $e');
    }
  }

  /// Get all pending actions
  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    await initialize();

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
    await initialize();

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
    await initialize();
    await _prefs!.remove(_pendingActionsKey);
    debugPrint('✅ All pending actions cleared');
  }

  /// Queue an error for later reporting
  static Future<void> queueError(Map<String, dynamic> error) async {
    await initialize();

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
    await initialize();

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
    await initialize();
    await _prefs!.remove(_errorQueueKey);
    debugPrint('✅ All queued errors cleared');
  }

  /// Clear all cached data
  static Future<void> clearAllCache() async {
    await initialize();

    await Future.wait([
      _prefs!.remove(_momentumDataKey),
      _prefs!.remove(_lastUpdateKey),
      _prefs!.remove(_pendingActionsKey),
      _prefs!.remove(_errorQueueKey),
    ]);

    debugPrint('✅ All cache cleared');
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    await initialize();

    final hasCachedData = _prefs!.containsKey(_momentumDataKey);
    final cacheAge = await getCachedDataAge();
    final pendingActions = await getPendingActions();
    final queuedErrors = await getQueuedErrors();

    return {
      'hasCachedData': hasCachedData,
      'cacheAge': cacheAge?.inHours,
      'isValid': await isCachedDataValid(),
      'pendingActionsCount': pendingActions.length,
      'queuedErrorsCount': queuedErrors.length,
      'lastUpdate': _prefs!.getString(_lastUpdateKey),
    };
  }
}
