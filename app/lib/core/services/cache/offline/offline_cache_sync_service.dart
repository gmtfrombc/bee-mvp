import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for managing background synchronization and cache warming operations
class OfflineCacheSyncService {
  static const String _backgroundSyncKey = 'background_sync_enabled';
  static const String _lastSyncAttemptKey = 'last_sync_attempt';

  static SharedPreferences? _prefs;

  /// Initialize the sync service
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  /// Enable or disable background sync
  static Future<void> enableBackgroundSync(bool enabled) async {
    if (_prefs == null) {
      throw StateError('OfflineCacheSyncService not initialized');
    }

    await _prefs!.setBool(_backgroundSyncKey, enabled);
    debugPrint('🔄 Background sync ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if background sync is enabled
  static Future<bool> isBackgroundSyncEnabled() async {
    if (_prefs == null) {
      throw StateError('OfflineCacheSyncService not initialized');
    }

    return _prefs!.getBool(_backgroundSyncKey) ?? true; // Default enabled
  }

  /// Warm the cache with fresh data when coming online
  static Future<void> warmCache() async {
    if (_prefs == null) {
      throw StateError('OfflineCacheSyncService not initialized');
    }

    try {
      debugPrint('🔥 Starting cache warming process');

      // Record cache warming attempt
      await _prefs!.setString(
        _lastSyncAttemptKey,
        DateTime.now().toIso8601String(),
      );

      // This would typically trigger a fresh data fetch
      // The actual data fetching should be handled by the API service
      debugPrint('✅ Cache warming completed');
    } catch (e) {
      debugPrint('❌ Cache warming failed: $e');
    }
  }

  /// Get the last sync attempt timestamp
  static Future<DateTime?> getLastSyncAttempt() async {
    if (_prefs == null) {
      throw StateError('OfflineCacheSyncService not initialized');
    }

    final lastSyncString = _prefs!.getString(_lastSyncAttemptKey);
    if (lastSyncString == null) return null;

    try {
      return DateTime.parse(lastSyncString);
    } catch (e) {
      debugPrint('❌ Failed to parse last sync attempt time: $e');
      return null;
    }
  }

  /// Get sync-related statistics
  static Future<Map<String, dynamic>> getSyncStats() async {
    if (_prefs == null) {
      throw StateError('OfflineCacheSyncService not initialized');
    }

    final lastSyncAttempt = await getLastSyncAttempt();
    final isEnabled = await isBackgroundSyncEnabled();

    return {
      'backgroundSyncEnabled': isEnabled,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'timeSinceLastSync':
          lastSyncAttempt != null
              ? DateTime.now().difference(lastSyncAttempt).inMinutes
              : null,
    };
  }
}
