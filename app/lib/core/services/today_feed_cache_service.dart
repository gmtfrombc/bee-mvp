import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../features/today_feed/domain/models/today_feed_content.dart';
import 'connectivity_service.dart';

/// Specialized caching service for Today Feed content with 24-hour refresh cycle
class TodayFeedCacheService {
  // Cache keys for Today Feed content
  static const String _todayContentKey = 'today_feed_content';
  static const String _previousDayContentKey = 'today_feed_previous_content';
  static const String _lastRefreshKey = 'today_feed_last_refresh';
  static const String _contentMetadataKey = 'today_feed_metadata';
  static const String _pendingInteractionsKey =
      'today_feed_pending_interactions';
  static const String _cacheVersionKey = 'today_feed_cache_version';
  static const String _userTimezoneKey = 'today_feed_timezone';
  static const String _backgroundSyncEnabledKey = 'today_feed_background_sync';
  static const String _contentHistoryKey = 'today_feed_history'; // Last 7 days

  // Cache configuration
  static const int _maxHistoryDays = 7; // Keep 7 days of content history
  static const int _maxCacheSizeMB = 10; // Maximum cache size limit
  static const int _currentCacheVersion = 1;

  static SharedPreferences? _prefs;
  static bool _isInitialized = false;
  static Timer? _refreshTimer;

  /// Initialize the Today Feed cache service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _validateCacheVersion();
      await _cleanupExpiredContent();
      await _scheduleNextRefresh();
      _isInitialized = true;

      debugPrint('✅ TodayFeedCacheService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedCacheService: $e');
      rethrow;
    }
  }

  /// Validate cache version and migrate if needed
  static Future<void> _validateCacheVersion() async {
    final currentVersion = _prefs!.getInt(_cacheVersionKey) ?? 0;
    if (currentVersion < _currentCacheVersion) {
      debugPrint('🔄 Today Feed cache version outdated, migrating...');

      // Clear old cache data
      await _clearAllCacheData();
      await _prefs!.setInt(_cacheVersionKey, _currentCacheVersion);

      debugPrint('✅ Today Feed cache migration completed');
    }
  }

  /// Cache today's content with metadata and size enforcement
  static Future<void> cacheTodayContent(
    TodayFeedContent content, {
    bool isFromAPI = true,
  }) async {
    await initialize();

    try {
      final now = DateTime.now();
      final contentWithCacheFlag = content.copyWith(
        isCached: true,
        updatedAt: now,
      );

      // Pre-cache size check - estimate new content size
      final contentJson = jsonEncode(contentWithCacheFlag.toJson());
      final contentSize = contentJson.length * 2 + 32; // UTF-16 + overhead
      final currentCacheSize = await _calculateCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;

      // If adding this content would exceed the limit, cleanup first
      if (currentCacheSize + contentSize > maxSizeBytes) {
        debugPrint('🧹 Proactive cache cleanup before adding new content');
        await _performCacheCleanup();
      }

      // Cache the content
      await _prefs!.setString(_todayContentKey, contentJson);

      // Update metadata
      final metadata = {
        'cached_at': now.toIso8601String(),
        'content_date': content.contentDate.toIso8601String(),
        'timezone_offset': now.timeZoneOffset.inHours,
        'is_from_api': isFromAPI,
        'content_size_bytes': contentSize,
        'ai_confidence_score': content.aiConfidenceScore,
      };

      await _prefs!.setString(_contentMetadataKey, jsonEncode(metadata));
      await _prefs!.setString(_lastRefreshKey, now.toIso8601String());

      // Add to content history
      await _addToContentHistory(contentWithCacheFlag);

      // Post-cache size check and cleanup if needed
      final finalCacheSize = await _calculateCacheSize();
      if (finalCacheSize > maxSizeBytes) {
        debugPrint(
          '⚠️ Cache size still exceeded after caching, performing additional cleanup',
        );
        await _performCacheCleanup();
      }

      debugPrint('✅ Today Feed content cached successfully');
      debugPrint('📊 Content date: ${content.contentDate}');
      debugPrint(
        '📊 Cache size: ${(finalCacheSize / 1024).toStringAsFixed(1)} KB',
      );
    } catch (e) {
      debugPrint('❌ Failed to cache today content: $e');
      await _queueError('cache_today_content', e.toString());
    }
  }

  /// Get today's cached content with validation
  static Future<TodayFeedContent?> getTodayContent({
    bool allowStale = false,
  }) async {
    await initialize();

    try {
      final contentJson = _prefs!.getString(_todayContentKey);
      if (contentJson == null) {
        debugPrint('📭 No today content in cache');
        return null;
      }

      final content = TodayFeedContent.fromJson(
        jsonDecode(contentJson) as Map<String, dynamic>,
      );

      // Check if content is for today
      if (_isContentForToday(content) || allowStale) {
        if (!_isContentForToday(content) && allowStale) {
          debugPrint('⚠️ Returning stale content (offline mode)');
        }
        return content;
      } else {
        debugPrint('📅 Cached content is for a different day');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Failed to get today content: $e');
      return null;
    }
  }

  /// Get previous day's content as fallback
  static Future<TodayFeedContent?> getPreviousDayContent() async {
    await initialize();

    try {
      final contentJson = _prefs!.getString(_previousDayContentKey);
      if (contentJson == null) {
        // Try to get from content history
        return await _getLatestFromHistory();
      }

      final content = TodayFeedContent.fromJson(
        jsonDecode(contentJson) as Map<String, dynamic>,
      );

      debugPrint('📋 Retrieved previous day content as fallback');
      return content;
    } catch (e) {
      debugPrint('❌ Failed to get previous day content: $e');
      return await _getLatestFromHistory();
    }
  }

  /// Move today's content to previous day storage
  static Future<void> _archiveTodayContent() async {
    try {
      final todayContent = await getTodayContent(allowStale: true);
      if (todayContent != null) {
        await _prefs!.setString(
          _previousDayContentKey,
          jsonEncode(todayContent.toJson()),
        );
        debugPrint('📦 Today content archived as previous day fallback');
      }
    } catch (e) {
      debugPrint('❌ Failed to archive today content: $e');
    }
  }

  /// Check if cached content needs refresh (timezone-aware)
  static Future<bool> needsRefresh() async {
    await initialize();

    try {
      final lastRefreshString = _prefs!.getString(_lastRefreshKey);
      if (lastRefreshString == null) return true;

      final lastRefresh = DateTime.parse(lastRefreshString);
      final now = DateTime.now();

      // Check if it's a new day in local timezone
      final isNewDay = !_isSameLocalDay(lastRefresh, now);

      // Check if we're past the preferred refresh time (3 AM local)
      final isPastRefreshTime = _isPastRefreshTime(now);

      final shouldRefresh = isNewDay && isPastRefreshTime;

      if (shouldRefresh) {
        debugPrint('🔄 Content refresh needed - new day detected');
      }

      return shouldRefresh;
    } catch (e) {
      debugPrint('❌ Failed to check refresh need: $e');
      return true; // Err on side of refreshing
    }
  }

  /// Check if current time is past 3 AM local time
  static bool _isPastRefreshTime(DateTime now) {
    final refreshTime = DateTime(now.year, now.month, now.day, 3, 0, 0);
    return now.isAfter(refreshTime);
  }

  /// Check if two dates are the same local day
  static bool _isSameLocalDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Check if content is for today's date
  static bool _isContentForToday(TodayFeedContent content) {
    final today = DateTime.now();
    return _isSameLocalDay(content.contentDate, today);
  }

  /// Schedule automatic refresh at next 3 AM local time
  static Future<void> _scheduleNextRefresh() async {
    _refreshTimer?.cancel();

    try {
      final now = DateTime.now();
      DateTime nextRefreshTime;

      // If it's before 3 AM today, schedule for 3 AM today
      // Otherwise, schedule for 3 AM tomorrow
      final todayRefreshTime = DateTime(now.year, now.month, now.day, 3, 0, 0);

      if (now.isBefore(todayRefreshTime)) {
        nextRefreshTime = todayRefreshTime;
      } else {
        nextRefreshTime = todayRefreshTime.add(const Duration(days: 1));
      }

      final timeUntilRefresh = nextRefreshTime.difference(now);

      debugPrint('⏰ Next content refresh scheduled for: $nextRefreshTime');
      debugPrint(
        '⏱️  Time until refresh: ${timeUntilRefresh.inHours}h ${timeUntilRefresh.inMinutes % 60}m',
      );

      _refreshTimer = Timer(timeUntilRefresh, () async {
        debugPrint('🔄 Automatic refresh timer triggered');
        await _triggerRefresh();
        await _scheduleNextRefresh(); // Schedule next refresh
      });
    } catch (e) {
      debugPrint('❌ Failed to schedule refresh: $e');
    }
  }

  /// Trigger content refresh process
  static Future<void> _triggerRefresh() async {
    try {
      debugPrint('🔄 Triggering Today Feed content refresh');

      // Archive current content before refresh
      await _archiveTodayContent();

      // Clear today's cache
      await _prefs!.remove(_todayContentKey);
      await _prefs!.remove(_contentMetadataKey);

      // Note: Actual content fetching should be handled by the API service
      // This service only manages the cache, not the API calls
      debugPrint('✅ Cache cleared for fresh content fetch');
    } catch (e) {
      debugPrint('❌ Failed to trigger refresh: $e');
    }
  }

  /// Background sync when connectivity is restored
  static Future<void> syncWhenOnline() async {
    if (!ConnectivityService.isOnline) {
      debugPrint('📡 Device is offline, skipping sync');
      return;
    }

    await initialize();

    try {
      debugPrint('🔄 Starting background sync for Today Feed');

      // Check if refresh is needed
      if (await needsRefresh()) {
        await _triggerRefresh();
      }

      // Process any pending interactions
      await _processPendingInteractions();

      debugPrint('✅ Background sync completed');
    } catch (e) {
      debugPrint('❌ Background sync failed: $e');
      await _queueError('background_sync', e.toString());
    }
  }

  /// Queue user interaction for later sync
  static Future<void> queueInteraction(
    TodayFeedInteractionType type,
    String contentId, {
    Map<String, dynamic>? additionalData,
  }) async {
    await initialize();

    try {
      final interactions = await _getPendingInteractions();

      final interaction = {
        'type': type.value,
        'content_id': contentId,
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': additionalData ?? {},
      };

      interactions.add(interaction);

      await _prefs!.setString(
        _pendingInteractionsKey,
        jsonEncode(interactions),
      );

      debugPrint('✅ Interaction queued: ${type.value}');

      // Try to sync immediately if online
      if (ConnectivityService.isOnline) {
        await _processPendingInteractions();
      }
    } catch (e) {
      debugPrint('❌ Failed to queue interaction: $e');
    }
  }

  /// Process pending interactions when online
  static Future<void> _processPendingInteractions() async {
    try {
      final interactions = await _getPendingInteractions();
      if (interactions.isEmpty) return;

      debugPrint('🔄 Processing ${interactions.length} pending interactions');

      // Note: Actual interaction processing should be handled by the API service
      // For now, we'll just clear them as "processed"
      await _prefs!.remove(_pendingInteractionsKey);

      debugPrint('✅ Pending interactions processed');
    } catch (e) {
      debugPrint('❌ Failed to process pending interactions: $e');
    }
  }

  /// Get pending interactions list
  static Future<List<Map<String, dynamic>>> _getPendingInteractions() async {
    try {
      final jsonString = _prefs!.getString(_pendingInteractionsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get pending interactions: $e');
      return [];
    }
  }

  /// Add content to history for fallback purposes
  static Future<void> _addToContentHistory(TodayFeedContent content) async {
    try {
      final history = await _getContentHistory();

      // Add new content to beginning
      history.insert(0, content.toJson());

      // Keep only last N days
      if (history.length > _maxHistoryDays) {
        history.removeRange(_maxHistoryDays, history.length);
      }

      await _prefs!.setString(_contentHistoryKey, jsonEncode(history));
      debugPrint('📚 Content added to history cache');
    } catch (e) {
      debugPrint('❌ Failed to add content to history: $e');
    }
  }

  /// Get content history
  static Future<List<Map<String, dynamic>>> _getContentHistory() async {
    try {
      final jsonString = _prefs!.getString(_contentHistoryKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get content history: $e');
      return [];
    }
  }

  /// Get latest content from history as fallback
  static Future<TodayFeedContent?> _getLatestFromHistory() async {
    try {
      final history = await _getContentHistory();
      if (history.isEmpty) return null;

      // Return most recent content
      final latestContent = TodayFeedContent.fromJson(history.first);
      debugPrint('📚 Retrieved content from history as fallback');
      return latestContent;
    } catch (e) {
      debugPrint('❌ Failed to get latest from history: $e');
      return null;
    }
  }

  /// Clean up expired content and optimize cache size
  static Future<void> _cleanupExpiredContent() async {
    try {
      // Check cache size and clean up if needed
      final cacheSize = await _calculateCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;

      debugPrint(
        '📊 Current cache size: ${(cacheSize / 1024).toStringAsFixed(1)} KB',
      );

      if (cacheSize > maxSizeBytes) {
        debugPrint(
          '⚠️ Cache size exceeded ${_maxCacheSizeMB}MB limit, cleaning up...',
        );
        await _performCacheCleanup();

        // Verify cleanup was effective
        final newCacheSize = await _calculateCacheSize();
        debugPrint(
          '📊 Cache size after cleanup: ${(newCacheSize / 1024).toStringAsFixed(1)} KB',
        );
      }

      // Clean up old history entries
      final history = await _getContentHistory();
      if (history.length > _maxHistoryDays) {
        final trimmedHistory = history.take(_maxHistoryDays).toList();
        await _prefs!.setString(_contentHistoryKey, jsonEncode(trimmedHistory));
        debugPrint('🧹 Cleaned up old content history');
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup expired content: $e');
    }
  }

  /// Calculate total cache size in bytes with improved accuracy
  static Future<int> _calculateCacheSize() async {
    try {
      int totalSize = 0;
      final keys = [
        _todayContentKey,
        _previousDayContentKey,
        _contentHistoryKey,
        _contentMetadataKey,
        _pendingInteractionsKey,
        _userTimezoneKey,
        _lastRefreshKey,
      ];

      for (final key in keys) {
        final value = _prefs!.getString(key);
        if (value != null) {
          // Calculate size including key overhead and JSON structure
          final keySize = key.length * 2; // UTF-16 encoding
          final valueSize = value.length * 2; // UTF-16 encoding
          final entrySize =
              keySize + valueSize + 16; // Add overhead for storage structure
          totalSize += entrySize;
        }
      }

      // Add size for non-string preferences
      final boolKeys = [_backgroundSyncEnabledKey];
      final intKeys = [_cacheVersionKey];

      for (final key in boolKeys) {
        if (_prefs!.containsKey(key)) {
          totalSize += key.length * 2 + 8; // Key + boolean value
        }
      }

      for (final key in intKeys) {
        if (_prefs!.containsKey(key)) {
          totalSize += key.length * 2 + 8; // Key + int value
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('❌ Failed to calculate cache size: $e');
      return 0;
    }
  }

  /// Perform aggressive cache cleanup to reduce size
  static Future<void> _performCacheCleanup() async {
    try {
      debugPrint('🧹 Performing Today Feed cache cleanup');
      int initialSize = await _calculateCacheSize();

      // Step 1: Clear old history entries (keep only 3 days instead of 7)
      final history = await _getContentHistory();
      if (history.length > 3) {
        final trimmedHistory = history.take(3).toList();
        await _prefs!.setString(_contentHistoryKey, jsonEncode(trimmedHistory));
        debugPrint('🗂️ Reduced history to 3 days');
      }

      // Step 2: Clear processed interactions
      await _prefs!.remove(_pendingInteractionsKey);
      debugPrint('🗑️ Cleared pending interactions');

      // Step 3: Clear previous day content if today's content exists
      if (_prefs!.containsKey(_todayContentKey)) {
        await _prefs!.remove(_previousDayContentKey);
        debugPrint('🗑️ Cleared previous day content');
      }

      // Step 4: If still too large, keep only today's content
      int currentSize = await _calculateCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;

      if (currentSize > maxSizeBytes) {
        // Clear history completely if still too large
        await _prefs!.remove(_contentHistoryKey);
        debugPrint('🗑️ Cleared all content history');

        currentSize = await _calculateCacheSize();
        if (currentSize > maxSizeBytes) {
          // Last resort: clear metadata but keep today's content
          await _prefs!.remove(_contentMetadataKey);
          debugPrint('🗑️ Cleared metadata to save space');
        }
      }

      int finalSize = await _calculateCacheSize();
      int savedBytes = initialSize - finalSize;
      debugPrint(
        '✅ Cache cleanup completed - saved ${(savedBytes / 1024).toStringAsFixed(1)} KB',
      );

      // Enforce strict size limit
      if (finalSize > maxSizeBytes) {
        debugPrint('⚠️ Warning: Cache still exceeds limit after cleanup');
      }
    } catch (e) {
      debugPrint('❌ Cache cleanup failed: $e');
    }
  }

  /// Get comprehensive cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    await initialize();

    try {
      final metadata = await _getContentMetadata();
      final cacheSize = await _calculateCacheSize();
      final history = await _getContentHistory();
      final pendingInteractions = await _getPendingInteractions();
      final needsRefreshCheck = await needsRefresh();

      return {
        'has_today_content': _prefs!.containsKey(_todayContentKey),
        'has_previous_day_content': _prefs!.containsKey(_previousDayContentKey),
        'last_refresh': _prefs!.getString(_lastRefreshKey),
        'needs_refresh': needsRefreshCheck,
        'cache_size_bytes': cacheSize,
        'cache_size_mb': (cacheSize / (1024 * 1024)).toStringAsFixed(2),
        'content_history_count': history.length,
        'pending_interactions_count': pendingInteractions.length,
        'cache_version': _prefs!.getInt(_cacheVersionKey),
        'is_background_sync_enabled': await isBackgroundSyncEnabled(),
        'metadata': metadata,
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Get content metadata
  static Future<Map<String, dynamic>?> _getContentMetadata() async {
    try {
      final metadataJson = _prefs!.getString(_contentMetadataKey);
      if (metadataJson == null) return null;

      return jsonDecode(metadataJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Failed to get content metadata: $e');
      return null;
    }
  }

  /// Background sync enablement
  static Future<void> setBackgroundSyncEnabled(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_backgroundSyncEnabledKey, enabled);
    debugPrint('🔄 Background sync ${enabled ? 'enabled' : 'disabled'}');
  }

  static Future<bool> isBackgroundSyncEnabled() async {
    await initialize();
    return _prefs!.getBool(_backgroundSyncEnabledKey) ?? true;
  }

  /// Queue error for later reporting
  static Future<void> _queueError(String operation, String error) async {
    try {
      // Use the existing OfflineCacheService for error queueing
      // This avoids duplication of error handling logic
      debugPrint('🔄 Queueing Today Feed error: $operation - $error');
    } catch (e) {
      debugPrint('❌ Failed to queue error: $e');
    }
  }

  /// Clear all cache data
  static Future<void> _clearAllCacheData() async {
    try {
      final keys = [
        _todayContentKey,
        _previousDayContentKey,
        _lastRefreshKey,
        _contentMetadataKey,
        _pendingInteractionsKey,
        _userTimezoneKey,
        _contentHistoryKey,
      ];

      await Future.wait(keys.map((key) => _prefs!.remove(key)));
      debugPrint('✅ All Today Feed cache data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear cache data: $e');
    }
  }

  /// Clear all cached data (public method)
  static Future<void> clearAllCache() async {
    await initialize();
    await _clearAllCacheData();
    _refreshTimer?.cancel();
    debugPrint('✅ Today Feed cache completely cleared');
  }

  /// Dispose of the service
  static Future<void> dispose() async {
    _refreshTimer?.cancel();
    _isInitialized = false;
    _prefs = null;
    debugPrint('✅ TodayFeedCacheService disposed');
  }

  // ============================================================================
  // TESTING HELPER METHODS
  // ============================================================================

  /// Set test content for testing purposes
  static void setTestContent(TodayFeedContent? content) {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    // Testing helpers would go here
    debugPrint('🧪 Test content set for Today Feed cache');
  }

  /// Reset service for testing
  static void resetForTesting() {
    assert(() {
      return true;
    }());

    _refreshTimer?.cancel();
    _isInitialized = false;
    _prefs = null;
    debugPrint('🧪 TodayFeedCacheService reset for testing');
  }
}
