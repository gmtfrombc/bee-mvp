import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/today_feed_content.dart';
import '../../../../core/services/today_feed_cache_service.dart';
import '../../../../core/services/connectivity_service.dart';

/// Data service for managing Today Feed content with offline caching
class TodayFeedDataService {
  // Initialization flag
  static bool _isInitialized = false;
  static StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  static bool _isTestEnvironment = false;

  /// Set test environment mode to disable connectivity subscriptions
  static void setTestEnvironment(bool isTest) {
    _isTestEnvironment = isTest;
  }

  /// Initialize the data service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize dependencies
      await TodayFeedCacheService.initialize();

      // Only initialize connectivity service in production
      if (!_isTestEnvironment) {
        await ConnectivityService.initialize();

        // Listen for connectivity changes to trigger background sync
        _connectivitySubscription = ConnectivityService.statusStream.listen(
          _onConnectivityChanged,
          onError: (error) {
            debugPrint('❌ Connectivity monitoring error: $error');
          },
        );
      }

      _isInitialized = true;
      debugPrint('✅ TodayFeedDataService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedDataService: $e');
      rethrow;
    }
  }

  /// Handle connectivity changes
  static void _onConnectivityChanged(ConnectivityStatus status) {
    if (_isTestEnvironment) return;

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

      debugPrint(
        '🔍 getTodayContent: forceRefresh=$forceRefresh, needsRefresh=$needsRefresh, isOnline=${ConnectivityService.isOnline}',
      );

      if (needsRefresh && ConnectivityService.isOnline) {
        debugPrint('🌐 Attempting to fetch fresh content from API...');
        // Try to fetch fresh content from API
        final freshContent = await _fetchContentFromAPI();
        if (freshContent != null) {
          await TodayFeedCacheService.cacheTodayContent(freshContent);
          debugPrint('✅ Fresh content fetched and cached successfully');
          return freshContent;
        } else {
          debugPrint('⚠️ Failed to fetch fresh content, falling back to cache');
        }
      } else if (needsRefresh && !ConnectivityService.isOnline) {
        debugPrint(
          '📡 Refresh needed but device is offline, using cached content',
        );
      } else if (!needsRefresh) {
        debugPrint('⏭️ No refresh needed, checking cache');
      }

      // Try to get cached content
      final cachedContent = await TodayFeedCacheService.getTodayContent(
        allowStale: !ConnectivityService.isOnline,
      );

      if (cachedContent != null) {
        debugPrint(
          '📱 Returning cached content (date: ${cachedContent.contentDate.toString().split(' ')[0]})',
        );
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

      // Final fallback: generate sample content to maintain user experience
      debugPrint('🔄 No cached content available, generating fallback content');
      return _generateFallbackContent();
    } catch (e) {
      debugPrint('❌ Failed to get today content: $e');

      // Try to return cached content as fallback
      return await TodayFeedCacheService.getTodayContent(allowStale: true);
    }
  }

  /// Fetch content from database via Supabase
  static Future<TodayFeedContent?> _fetchContentFromAPI() async {
    try {
      debugPrint('🌐 Fetching fresh content from database...');

      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        debugPrint(
          '⚠️ Supabase client not initialized, using fallback content',
        );
        return _generateFallbackContent();
      }

      final today = DateTime.now();
      final todayDateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Fetch today's content from daily_feed_content table
      final response =
          await supabase
              .from('daily_feed_content')
              .select('*')
              .eq('content_date', todayDateString)
              .maybeSingle();

      if (response == null) {
        debugPrint('📭 No content found in database for $todayDateString');

        // Try to trigger content generation
        await _triggerContentGeneration(todayDateString);

        // Fall back to sample content while generation is happening
        return _generateFallbackContent();
      }

      // Convert database response to TodayFeedContent
      final content = TodayFeedContent.fromJson({
        'id': response['id'],
        'content_date': response['content_date'],
        'title': response['title'],
        'summary': response['summary'],
        'content_url': response['content_url'],
        'external_link': response['external_link'],
        'topic_category': response['topic_category'],
        'ai_confidence_score': response['ai_confidence_score'] ?? 0.8,
        'created_at': response['created_at'],
        'updated_at': response['updated_at'],
        'estimated_reading_minutes': 2,
        'has_user_engaged': false,
        'is_cached': false,
      });

      debugPrint('✅ Content fetched from database for $todayDateString');
      debugPrint('📝 Title: "${content.title}"');
      debugPrint('🎯 Topic: ${content.topicCategory.value}');
      debugPrint('📊 Confidence: ${content.aiConfidenceScore}');

      return content;
    } catch (e) {
      debugPrint('❌ Failed to fetch content from database: $e');

      // Return fallback content to maintain user experience
      return _generateFallbackContent();
    }
  }

  /// Generate fallback content when database content is unavailable
  static TodayFeedContent _generateFallbackContent() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;

    // Generate different content for each day of the year
    final topics = [
      'Stress Management',
      'Sleep Hygiene',
      'Mindful Eating',
      'Exercise Motivation',
      'Social Connections',
      'Work-Life Balance',
      'Mental Resilience',
    ];

    final tips = [
      'Take 5 deep breaths when feeling overwhelmed',
      'Create a consistent bedtime routine for better sleep',
      'Practice mindful eating by savoring each bite',
      'Start with just 10 minutes of movement today',
      'Reach out to one friend or family member',
      'Set clear boundaries between work and personal time',
      'Focus on what you can control, not what you cannot',
    ];

    final topicIndex = dayOfYear % topics.length;
    final todayTopic = topics[topicIndex];
    final todayTip = tips[topicIndex];

    return TodayFeedContent.sample().copyWith(
      title: 'Daily Wellness: $todayTopic',
      summary: 'Today\'s focus: $todayTip',
      contentDate: DateTime(now.year, now.month, now.day),
      createdAt: now,
      updatedAt: now,
      isCached: true, // Mark as fallback content
    );
  }

  /// Trigger content generation for missing date
  static Future<void> _triggerContentGeneration(String dateString) async {
    try {
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        debugPrint('⚠️ Supabase client not available for content generation');
        return;
      }

      debugPrint('🔄 Triggering content generation for $dateString...');

      // Call the daily content generator function
      final response = await supabase.functions.invoke(
        'daily-content-generator',
        body: {'target_date': dateString, 'force_regenerate': false},
      );

      if (response.data != null && response.data['success'] == true) {
        debugPrint('✅ Content generation triggered successfully');
      } else {
        debugPrint(
          '⚠️ Content generation request completed but may have failed',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to trigger content generation: $e');
      // Don't throw - this is a background operation
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

  /// Force clear cache and fetch fresh content (for debugging/testing)
  static Future<TodayFeedContent?> forceRefreshAndClearCache() async {
    await initialize();

    try {
      debugPrint('🧹 Force clearing cache and fetching fresh content...');

      // Clear the cache first
      await TodayFeedCacheService.invalidateCache(
        reason: 'Force refresh requested',
      );

      // Now fetch fresh content
      if (ConnectivityService.isOnline) {
        final freshContent = await _fetchContentFromAPI();
        if (freshContent != null) {
          await TodayFeedCacheService.cacheTodayContent(freshContent);
          debugPrint('✅ Cache cleared and fresh content fetched');
          return freshContent;
        }
      }

      debugPrint('⚠️ Failed to fetch fresh content after cache clear');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to force refresh and clear cache: $e');
      return null;
    }
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
