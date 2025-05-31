import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../features/today_feed/domain/models/today_feed_content.dart';
import 'today_feed_cache_sync_service.dart';

/// Service responsible for cache maintenance, cleanup, and invalidation
class TodayFeedCacheMaintenanceService {
  // Cache keys for Today Feed content
  static const String _todayContentKey = 'today_feed_content';
  static const String _previousDayContentKey = 'today_feed_previous_content';
  static const String _contentMetadataKey = 'today_feed_metadata';
  static const String _contentHistoryKey = 'today_feed_history'; // Last 7 days
  static const String _timezoneMetadataKey = 'today_feed_timezone_metadata';
  // Cache configuration
  static const int _maxHistoryDays = 7; // Keep 7 days of content history
  static const int _maxCacheSizeMB = 10; // Maximum cache size limit

  // Cache invalidation and cleanup configuration
  static const Duration _automaticCleanupInterval = Duration(hours: 6);
  static const String _manualInvalidationKey = 'today_feed_manual_invalidation';

  static SharedPreferences? _prefs;
  static bool _isInitialized = false;
  static Timer? _automaticCleanupTimer;

  /// Initialize the maintenance service
  static Future<void> initialize(SharedPreferences prefs) async {
    if (_isInitialized) return;

    try {
      _prefs = prefs;
      await _scheduleAutomaticCleanup();
      _isInitialized = true;
      debugPrint('✅ TodayFeedCacheMaintenanceService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedCacheMaintenanceService: $e');
      rethrow;
    }
  }

  /// Calculate current cache size in bytes
  static Future<int> calculateCacheSize() async {
    try {
      int totalSize = 0;

      // Calculate size of main content keys
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
          totalSize += value.length * 2; // UTF-16 encoding
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('❌ Failed to calculate cache size: $e');
      return 0;
    }
  }

  /// Perform cache cleanup to free space
  static Future<void> performCacheCleanup() async {
    try {
      debugPrint('🧹 Starting cache cleanup...');

      // Remove old content history entries
      await cleanupContentHistory();

      final finalSize = await calculateCacheSize();
      debugPrint(
        '✅ Cache cleanup completed. Final size: ${(finalSize / 1024).toStringAsFixed(1)} KB',
      );
    } catch (e) {
      debugPrint('❌ Failed to perform cache cleanup: $e');
    }
  }

  /// Cleanup old content history entries
  static Future<void> cleanupContentHistory() async {
    try {
      final historyJson = _prefs!.getString(_contentHistoryKey);
      if (historyJson == null) return;

      final historyData = jsonDecode(historyJson) as List<dynamic>;
      final history = historyData.cast<Map<String, dynamic>>();

      // Keep only entries from last _maxHistoryDays
      final cutoffDate = DateTime.now().subtract(
        Duration(days: _maxHistoryDays),
      );

      final filteredHistory =
          history.where((entry) {
            try {
              final cachedAt = DateTime.parse(entry['cached_at'] as String);
              return cachedAt.isAfter(cutoffDate);
            } catch (e) {
              return false; // Remove invalid entries
            }
          }).toList();

      if (filteredHistory.length != history.length) {
        await _prefs!.setString(
          _contentHistoryKey,
          jsonEncode(filteredHistory),
        );
        debugPrint(
          '🧹 Cleaned up content history: ${history.length} → ${filteredHistory.length} entries',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup content history: $e');
    }
  }

  /// Schedule automatic cleanup
  static Future<void> _scheduleAutomaticCleanup() async {
    try {
      _automaticCleanupTimer?.cancel();

      _automaticCleanupTimer = Timer.periodic(_automaticCleanupInterval, (
        timer,
      ) async {
        debugPrint('⏰ Automatic cleanup triggered');
        await cleanupContentHistory();
        // Delegate interaction and sync error cleanup to sync service
        await TodayFeedCacheSyncService.cleanupPendingInteractions();
        await TodayFeedCacheSyncService.cleanupSyncErrors();
      });

      debugPrint('⏰ Automatic cleanup scheduled');
    } catch (e) {
      debugPrint('❌ Failed to schedule automatic cleanup: $e');
    }
  }

  /// Selective cleanup - cleans up content history and delegated sync cleanup
  static Future<void> selectiveCleanup() async {
    if (!_isInitialized) {
      debugPrint('❌ Maintenance service not initialized');
      return;
    }

    try {
      await cleanupContentHistory();
      await TodayFeedCacheSyncService.cleanupPendingInteractions();
      await TodayFeedCacheSyncService.cleanupSyncErrors();
      debugPrint('✅ Selective cleanup completed');
    } catch (e) {
      debugPrint('❌ Failed to perform selective cleanup: $e');
      rethrow;
    }
  }

  /// Invalidate content with options
  static Future<void> invalidateContent({
    bool clearHistory = false,
    bool clearMetadata = false,
    String? reason,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ Maintenance service not initialized');
      return;
    }

    try {
      debugPrint('🔄 Invalidating content: ${reason ?? 'No reason specified'}');

      if (clearHistory) {
        await _prefs!.remove(_contentHistoryKey);
        debugPrint('🧹 Content history cleared');
      }

      if (clearMetadata) {
        await _prefs!.remove(_contentMetadataKey);
        debugPrint('🧹 Content metadata cleared');
      }

      // Clear today's content
      await _prefs!.remove(_todayContentKey);
      debugPrint('🧹 Today content cleared');

      debugPrint('✅ Content invalidation completed');
    } catch (e) {
      debugPrint('❌ Failed to invalidate content: $e');
      rethrow;
    }
  }

  /// Get cache invalidation stats
  static Future<Map<String, dynamic>> getCacheInvalidationStats() async {
    if (!_isInitialized) {
      debugPrint('❌ Maintenance service not initialized');
      return {
        'error': 'Service not initialized',
        'last_invalidation': null,
        'invalidation_count': 0,
      };
    }

    try {
      // Simple implementation for compatibility
      return {
        'last_invalidation': null,
        'invalidation_count': 0,
        'has_pending_invalidation': false,
        'invalidation_reasons': <String>[],
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache invalidation stats: $e');
      return {
        'error': e.toString(),
        'last_invalidation': null,
        'invalidation_count': 0,
      };
    }
  }

  /// Manual invalidation for testing
  static Future<void> invalidateCache({String? reason}) async {
    if (!_isInitialized) {
      debugPrint('❌ Maintenance service not initialized');
      return;
    }

    try {
      await _prefs!.setString(
        _manualInvalidationKey,
        jsonEncode({
          'timestamp': DateTime.now().toIso8601String(),
          'reason': reason ?? 'Manual invalidation',
        }),
      );

      await _prefs!.remove(_todayContentKey);
      debugPrint(
        '🔄 Cache manually invalidated: ${reason ?? 'No reason provided'}',
      );
    } catch (e) {
      debugPrint('❌ Failed to invalidate cache: $e');
    }
  }

  /// Check if cache size exceeds limits
  static Future<bool> isOverSizeLimit() async {
    if (!_isInitialized) return false;

    try {
      final currentSize = await calculateCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;
      return currentSize > maxSizeBytes;
    } catch (e) {
      debugPrint('❌ Failed to check size limit: $e');
      return false;
    }
  }

  /// Enforce entry limits and perform cleanup if needed
  static Future<void> enforceEntryLimits() async {
    if (!_isInitialized) return;

    try {
      final isOverLimit = await isOverSizeLimit();
      if (isOverLimit) {
        debugPrint('⚠️ Cache over size limit, performing cleanup');
        await performCacheCleanup();
      }
    } catch (e) {
      debugPrint('❌ Failed to enforce entry limits: $e');
    }
  }

  /// Validate content freshness
  static Future<bool> validateContentFreshness(TodayFeedContent content) async {
    try {
      final now = DateTime.now();
      final contentDate = content.contentDate;

      // Check if content is for today
      final isSameDay =
          now.year == contentDate.year &&
          now.month == contentDate.month &&
          now.day == contentDate.day;

      return isSameDay;
    } catch (e) {
      debugPrint('❌ Failed to validate content freshness: $e');
      return false;
    }
  }

  /// Check content expiration
  static bool checkContentExpiration(TodayFeedContent content) {
    try {
      final now = DateTime.now();
      final contentDate = content.contentDate;

      // Content expires if it's from a different day
      return !(now.year == contentDate.year &&
          now.month == contentDate.month &&
          now.day == contentDate.day);
    } catch (e) {
      debugPrint('❌ Failed to check content expiration: $e');
      return true; // Assume expired on error
    }
  }

  /// Remove expired content
  static Future<void> removeExpiredContent() async {
    if (!_isInitialized) return;

    try {
      final contentJson = _prefs!.getString(_todayContentKey);
      if (contentJson == null) return;

      final content = TodayFeedContent.fromJson(
        jsonDecode(contentJson) as Map<String, dynamic>,
      );

      if (checkContentExpiration(content)) {
        await _prefs!.remove(_todayContentKey);
        debugPrint('🧹 Removed expired today content');
      }
    } catch (e) {
      debugPrint('❌ Failed to remove expired content: $e');
    }
  }

  /// Remove stale content older than specified duration
  static Future<void> removeStaleContentOlderThan(Duration duration) async {
    if (!_isInitialized) return;

    try {
      final cutoffTime = DateTime.now().subtract(duration);

      // Check and remove stale today content
      final contentJson = _prefs!.getString(_todayContentKey);
      if (contentJson != null) {
        final content = TodayFeedContent.fromJson(
          jsonDecode(contentJson) as Map<String, dynamic>,
        );

        if (content.updatedAt?.isBefore(cutoffTime) == true) {
          await _prefs!.remove(_todayContentKey);
          debugPrint('🧹 Removed stale today content');
        }
      }

      // Clean up content history
      await cleanupContentHistory();
    } catch (e) {
      debugPrint('❌ Failed to remove stale content: $e');
    }
  }

  /// Dispose of maintenance service resources
  static Future<void> dispose() async {
    try {
      _automaticCleanupTimer?.cancel();
      _automaticCleanupTimer = null;
      _isInitialized = false;
      debugPrint('✅ TodayFeedCacheMaintenanceService disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose TodayFeedCacheMaintenanceService: $e');
    }
  }

  /// Get maintenance service status
  static Map<String, dynamic> getMaintenanceStatus() {
    return {
      'is_initialized': _isInitialized,
      'has_cleanup_timer': _automaticCleanupTimer != null,
      'cleanup_interval_hours': _automaticCleanupInterval.inHours,
      'max_cache_size_mb': _maxCacheSizeMB,
      'max_history_days': _maxHistoryDays,
    };
  }
}
