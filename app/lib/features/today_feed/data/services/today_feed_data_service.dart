import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/today_feed_content.dart';
import '../../../../core/services/today_feed_cache_service.dart';
import '../../../../core/services/connectivity_service.dart';

/// Data service for managing Today Feed content with offline caching
class TodayFeedDataService {
  // Initialization flag
  static bool _isInitialized = false;
  static StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  /// Initialize the data service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize dependencies
      await TodayFeedCacheService.initialize();
      await ConnectivityService.initialize();

      // Listen for connectivity changes to trigger background sync
      _connectivitySubscription = ConnectivityService.statusStream.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint('❌ Connectivity monitoring error: $error');
        },
      );

      _isInitialized = true;
      debugPrint('✅ TodayFeedDataService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedDataService: $e');
      rethrow;
    }
  }

  /// Handle connectivity changes
  static void _onConnectivityChanged(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online) {
      debugPrint('📡 Device back online, checking for pending operations');
      // Check for pending interactions to sync when back online
      Timer(const Duration(seconds: 2), () async {
        final pendingInteractions =
            await TodayFeedCacheService.getPendingInteractions();
        if (pendingInteractions.isNotEmpty) {
          debugPrint(
            '🔄 ${pendingInteractions.length} pending interactions found, syncing...',
          );
          // TODO: Implement actual sync with API
        }
      });
    }
  }

  /// Get today's content with smart caching strategy
  static Future<TodayFeedContent?> getTodayContent({
    bool forceRefresh = false,
  }) async {
    await initialize();

    try {
      // Check if we should fetch fresh content
      final needsRefresh =
          forceRefresh || await TodayFeedCacheService.needsRefresh();

      if (needsRefresh && ConnectivityService.isOnline) {
        // Try to fetch fresh content from API
        final freshContent = await _fetchContentFromAPI();
        if (freshContent != null) {
          await TodayFeedCacheService.cacheTodayContent(freshContent);
          debugPrint('✅ Fresh content fetched and cached');
          return freshContent;
        }
      }

      // Try to get cached content
      final cachedContent = await TodayFeedCacheService.getTodayContent(
        allowStale: !ConnectivityService.isOnline,
      );

      if (cachedContent != null) {
        debugPrint('📱 Returning cached content');
        return cachedContent;
      }

      // Fallback to previous day's content if offline
      if (!ConnectivityService.isOnline) {
        final fallbackContent =
            await TodayFeedCacheService.getPreviousDayContent();
        if (fallbackContent != null) {
          debugPrint('📋 Returning previous day content as fallback');
          return fallbackContent;
        }
      }

      // No content available
      debugPrint('📭 No content available');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get today content: $e');

      // Try to return cached content as fallback
      return await TodayFeedCacheService.getTodayContent(allowStale: true);
    }
  }

  /// Fetch content from API (placeholder implementation)
  static Future<TodayFeedContent?> _fetchContentFromAPI() async {
    try {
      debugPrint('🌐 Fetching fresh content from API...');

      // TODO: Replace with actual HTTP client implementation
      // For now, return sample content to demonstrate caching
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay

      final sampleContent = TodayFeedContent.sample().copyWith(
        contentDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('✅ Sample content fetched from API');
      return sampleContent;
    } catch (e) {
      debugPrint('❌ Failed to fetch content from API: $e');
      return null;
    }
  }

  /// Record user interaction with content
  static Future<void> recordInteraction(
    TodayFeedInteractionType type,
    TodayFeedContent content, {
    Map<String, dynamic>? additionalData,
  }) async {
    await initialize();

    try {
      final contentId = content.id?.toString() ?? 'unknown';

      // Queue interaction for offline/online sync
      await TodayFeedCacheService.cachePendingInteraction({
        'type': type.value,
        'content_id': contentId,
        'content_date': content.contentDate.toIso8601String(),
        'topic_category': content.topicCategory.value,
        ...?additionalData,
      });

      debugPrint('✅ Interaction recorded: ${type.value}');

      // If online, try to sync immediately
      if (ConnectivityService.isOnline) {
        await _syncInteractionWithAPI(type, content, additionalData);
      }
    } catch (e) {
      debugPrint('❌ Failed to record interaction: $e');
    }
  }

  /// Sync interaction with API (placeholder implementation)
  static Future<void> _syncInteractionWithAPI(
    TodayFeedInteractionType type,
    TodayFeedContent content,
    Map<String, dynamic>? additionalData,
  ) async {
    try {
      debugPrint('🔄 Syncing interaction with API: ${type.value}');

      // TODO: Replace with actual HTTP client implementation
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Simulate network delay

      debugPrint('✅ Interaction synced with API');
    } catch (e) {
      debugPrint('❌ Failed to sync interaction with API: $e');
    }
  }

  /// Force refresh of today's content
  static Future<TodayFeedContent?> refreshContent() async {
    await initialize();

    if (!ConnectivityService.isOnline) {
      debugPrint('📡 Cannot refresh - device is offline');
      return await getTodayContent();
    }

    return await getTodayContent(forceRefresh: true);
  }

  /// Preload content for better performance
  static Future<void> preloadContent() async {
    await initialize();

    try {
      if (!ConnectivityService.isOnline) {
        debugPrint('📡 Cannot preload - device is offline');
        return;
      }

      // Check if we already have today's content
      final cachedContent = await TodayFeedCacheService.getTodayContent();
      if (cachedContent != null && cachedContent.isFresh) {
        debugPrint('📱 Today content already cached and fresh');
        return;
      }

      // Fetch fresh content in background
      debugPrint('🔄 Preloading fresh content...');
      await getTodayContent(forceRefresh: true);
    } catch (e) {
      debugPrint('❌ Failed to preload content: $e');
    }
  }

  /// Get content history for analytics or fallback
  static Future<List<TodayFeedContent>> getContentHistory({
    int maxDays = 7,
  }) async {
    await initialize();

    try {
      // Note: This would need to be implemented in the cache service
      // For now, return empty list
      debugPrint('📚 Content history requested (not yet implemented)');
      return [];
    } catch (e) {
      debugPrint('❌ Failed to get content history: $e');
      return [];
    }
  }

  /// Get cache statistics and health info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    await initialize();

    try {
      final cacheStats = await TodayFeedCacheService.getCacheMetadata();
      final connectivityStatus = ConnectivityService.currentStatus;

      return {
        ...cacheStats,
        'connectivity_status': connectivityStatus.toString(),
        'is_online': ConnectivityService.isOnline,
        'last_connectivity_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache info: $e');
      return {'error': e.toString()};
    }
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    await initialize();

    try {
      await TodayFeedCacheService.invalidateCache(reason: 'Manual cache clear');
      debugPrint('✅ All Today Feed cache cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear cache: $e');
    }
  }

  /// Enable or disable background sync
  static Future<void> setBackgroundSyncEnabled(bool enabled) async {
    await initialize();

    try {
      await TodayFeedCacheService.setBackgroundSyncEnabled(enabled);
      debugPrint('✅ Background sync ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ Failed to set background sync: $e');
    }
  }

  /// Check if background sync is enabled
  static Future<bool> isBackgroundSyncEnabled() async {
    await initialize();

    try {
      return await TodayFeedCacheService.isBackgroundSyncEnabled();
    } catch (e) {
      debugPrint('❌ Failed to check background sync status: $e');
      return false;
    }
  }

  /// Dispose of the data service
  static Future<void> dispose() async {
    try {
      await _connectivitySubscription?.cancel();
      await TodayFeedCacheService.dispose();
      _isInitialized = false;
      debugPrint('✅ TodayFeedDataService disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose data service: $e');
    }
  }

  // ============================================================================
  // TESTING HELPER METHODS
  // ============================================================================

  /// Set test mode with mock content
  static void setTestMode(bool enabled) {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    debugPrint('🧪 Test mode ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Reset service for testing
  static void resetForTesting() {
    assert(() {
      return true;
    }());

    _connectivitySubscription?.cancel();
    _isInitialized = false;
    // Note: resetForTesting method no longer exists in cache service
    // The cache service can be reset by disposing and re-initializing
    debugPrint('🧪 TodayFeedDataService reset for testing');
  }
}
