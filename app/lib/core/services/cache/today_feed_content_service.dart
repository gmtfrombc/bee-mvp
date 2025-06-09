import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../features/today_feed/domain/models/today_feed_content.dart';
import 'today_feed_timezone_service.dart';
import 'today_feed_cache_maintenance_service.dart';

/// Service for managing Today Feed content storage and retrieval
class TodayFeedContentService {
  // Cache keys for Today Feed content
  static const String _todayContentKey = 'today_feed_content';
  static const String _previousDayContentKey = 'today_feed_previous_content';
  static const String _lastRefreshKey = 'today_feed_last_refresh';
  static const String _contentMetadataKey = 'today_feed_metadata';
  static const String _contentHistoryKey = 'today_feed_history'; // Last 7 days

  // Cache configuration
  static const int _maxHistoryDays = 7; // Keep 7 days of content history
  static const int _maxCacheSizeMB = 10; // Maximum cache size limit

  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  // Track when we last showed the stale content warning to avoid spam
  static DateTime? _lastStaleWarningTime;
  static const Duration _staleWarningCooldown = Duration(minutes: 1);

  /// Initialize the content service
  static Future<void> initialize(SharedPreferences prefs) async {
    if (_isInitialized) return;

    try {
      _prefs = prefs;
      _isInitialized = true;
      debugPrint('✅ TodayFeedContentService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedContentService: $e');
      rethrow;
    }
  }

  /// Cache today's content with metadata and size enforcement
  static Future<void> cacheTodayContent(
    TodayFeedContent content, {
    bool isFromAPI = true,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

    try {
      final now = DateTime.now();
      final contentWithCacheFlag = content.copyWith(
        isCached: true,
        updatedAt: now,
      );

      // Pre-cache size check - estimate new content size
      final contentJson = jsonEncode(contentWithCacheFlag.toJson());
      final contentSize = contentJson.length * 2 + 32; // UTF-16 + overhead
      final currentCacheSize =
          await TodayFeedCacheMaintenanceService.calculateCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;

      // If adding this content would exceed the limit, cleanup first
      if (currentCacheSize + contentSize > maxSizeBytes) {
        debugPrint('🧹 Proactive cache cleanup before adding new content');
        await TodayFeedCacheMaintenanceService.performCacheCleanup();
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
      final finalCacheSize =
          await TodayFeedCacheMaintenanceService.calculateCacheSize();
      if (finalCacheSize > maxSizeBytes) {
        debugPrint(
          '⚠️ Cache size still exceeded after caching, performing additional cleanup',
        );
        await TodayFeedCacheMaintenanceService.performCacheCleanup();
      }

      debugPrint('✅ Today Feed content cached successfully');
      debugPrint('📊 Content date: ${content.contentDate}');
      debugPrint(
        '📊 Cache size: ${(finalCacheSize / 1024).toStringAsFixed(1)} KB',
      );
    } catch (e) {
      debugPrint('❌ Failed to cache today content: $e');
      rethrow;
    }
  }

  /// Get today's cached content with validation
  static Future<TodayFeedContent?> getTodayContent({
    bool allowStale = false,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

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
          // Only show stale content warning once per cooldown period to avoid spam
          final now = DateTime.now();
          final shouldShowWarning =
              _lastStaleWarningTime == null ||
              now.difference(_lastStaleWarningTime!) > _staleWarningCooldown;

          if (shouldShowWarning) {
            debugPrint('⚠️ Returning stale content (offline mode)');
            _lastStaleWarningTime = now;
          }
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

  /// Get previous day's content as fallback with enhanced metadata
  static Future<TodayFeedContent?> getPreviousDayContent() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

    try {
      final contentJson = _prefs!.getString(_previousDayContentKey);
      if (contentJson == null) {
        // Try to get from content history
        return await _getLatestFromHistory();
      }

      final content = TodayFeedContent.fromJson(
        jsonDecode(contentJson) as Map<String, dynamic>,
      );

      // Add fallback metadata to indicate this is cached content
      final enhancedContent = content.copyWith(
        isCached: true,
        fullContent: content.fullContent?.copyWith(
          elements:
              content.fullContent?.elements.map((element) {
                if (element.type == RichContentType.paragraph &&
                    element == content.fullContent!.elements.first) {
                  return element.copyWith(
                    text: '[CACHED CONTENT] ${element.text}',
                  );
                }
                return element;
              }).toList(),
        ),
      );

      debugPrint('📋 Retrieved previous day content as fallback (cached)');
      return enhancedContent;
    } catch (e) {
      debugPrint('❌ Failed to get previous day content: $e');
      return await _getLatestFromHistory();
    }
  }

  /// Get fallback content with metadata
  static Future<TodayFeedContent?> getFallbackContentWithMetadata() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

    try {
      // First try previous day content
      final previousContent = await getPreviousDayContent();
      if (previousContent != null) {
        return previousContent.copyWith(isCached: true);
      }

      // If no previous content, return null
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get fallback content with metadata: $e');
      return null;
    }
  }

  /// Move today's content to previous day storage
  static Future<void> archiveTodayContent() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

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

  /// Clear today's content only
  static Future<void> clearTodayContent() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

    try {
      await archiveTodayContent();
      await _prefs!.remove(_todayContentKey);
      await _prefs!.remove(_contentMetadataKey);

      debugPrint('🧹 Today content cleared from cache');
    } catch (e) {
      debugPrint('❌ Failed to clear today content: $e');
    }
  }

  /// Check if content is for today (timezone-aware)
  static bool _isContentForToday(TodayFeedContent content) {
    return TodayFeedTimezoneService.isSameLocalDay(
      content.contentDate,
      DateTime.now(),
    );
  }

  /// Add content to history for fallback purposes
  static Future<void> _addToContentHistory(TodayFeedContent content) async {
    try {
      final historyJson = _prefs!.getString(_contentHistoryKey);
      List<Map<String, dynamic>> history = [];

      if (historyJson != null) {
        final historyData = jsonDecode(historyJson) as List<dynamic>;
        history = historyData.cast<Map<String, dynamic>>();
      }

      // Add new content to history
      history.insert(0, {
        'content': content.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
      });

      // Keep only last _maxHistoryDays entries
      if (history.length > _maxHistoryDays) {
        history = history.take(_maxHistoryDays).toList();
      }

      await _prefs!.setString(_contentHistoryKey, jsonEncode(history));
      debugPrint('📚 Content added to history (${history.length} entries)');
    } catch (e) {
      debugPrint('❌ Failed to add content to history: $e');
    }
  }

  /// Get latest content from history as fallback
  static Future<TodayFeedContent?> _getLatestFromHistory() async {
    try {
      final historyJson = _prefs!.getString(_contentHistoryKey);
      if (historyJson == null) return null;

      final historyData = jsonDecode(historyJson) as List<dynamic>;
      final history = historyData.cast<Map<String, dynamic>>();

      if (history.isEmpty) return null;

      final latestEntry = history.first;
      final content = TodayFeedContent.fromJson(
        latestEntry['content'] as Map<String, dynamic>,
      );

      debugPrint('📚 Retrieved content from history as fallback');
      return content.copyWith(isCached: true);
    } catch (e) {
      debugPrint('❌ Failed to get content from history: $e');
      return null;
    }
  }

  /// Get content history
  static Future<List<Map<String, dynamic>>> getContentHistory() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

    try {
      final historyJson = _prefs!.getString(_contentHistoryKey);
      if (historyJson == null) return [];

      final historyData = jsonDecode(historyJson) as List<dynamic>;
      return historyData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get content history: $e');
      return [];
    }
  }

  /// Clear all content data
  static Future<void> clearAllContentData() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

    try {
      await _prefs!.remove(_todayContentKey);
      await _prefs!.remove(_previousDayContentKey);
      await _prefs!.remove(_lastRefreshKey);
      await _prefs!.remove(_contentMetadataKey);
      await _prefs!.remove(_contentHistoryKey);

      debugPrint('🧹 All content data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear content data: $e');
    }
  }

  /// Check if should use fallback content
  static Future<bool> shouldUseFallbackContent() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

    try {
      final todayContent = await getTodayContent();
      if (todayContent != null) {
        return false; // Have current content, no need for fallback
      }

      final previousContent = await getPreviousDayContent();
      return previousContent != null; // Use fallback if available
    } catch (e) {
      debugPrint('❌ Failed to check fallback content availability: $e');
      return false;
    }
  }

  /// Get content metadata for debugging
  static Future<Map<String, dynamic>> getContentMetadata() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

    try {
      final lastRefresh = _prefs!.getString(_lastRefreshKey);
      final metadataJson = _prefs!.getString(_contentMetadataKey);
      final historyJson = _prefs!.getString(_contentHistoryKey);

      Map<String, dynamic> metadata = {};
      if (metadataJson != null) {
        metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      }

      int historyCount = 0;
      if (historyJson != null) {
        final historyData = jsonDecode(historyJson) as List<dynamic>;
        historyCount = historyData.length;
      }

      return {
        'last_refresh': lastRefresh,
        'metadata': metadata,
        'has_today_content': _prefs!.containsKey(_todayContentKey),
        'has_previous_content': _prefs!.containsKey(_previousDayContentKey),
        'history_count': historyCount,
        'is_initialized': _isInitialized,
      };
    } catch (e) {
      debugPrint('❌ Failed to get content metadata: $e');
      return {'error': e.toString()};
    }
  }

  /// Check if has today's content
  static bool hasTodayContent() {
    if (!_isInitialized) return false;
    return _prefs!.containsKey(_todayContentKey);
  }

  /// Check if has previous day content
  static bool hasPreviousDayContent() {
    if (!_isInitialized) return false;
    return _prefs!.containsKey(_previousDayContentKey);
  }

  /// Get last refresh time
  static DateTime? getLastRefreshTime() {
    if (!_isInitialized) return null;

    try {
      final lastRefreshString = _prefs!.getString(_lastRefreshKey);
      if (lastRefreshString == null) return null;
      return DateTime.parse(lastRefreshString);
    } catch (e) {
      debugPrint('❌ Failed to get last refresh time: $e');
      return null;
    }
  }

  /// Update last refresh time
  static Future<void> updateLastRefreshTime([DateTime? time]) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedContentService not initialized');
    }

    try {
      final refreshTime = time ?? DateTime.now();
      await _prefs!.setString(_lastRefreshKey, refreshTime.toIso8601String());
      debugPrint('✅ Last refresh time updated: $refreshTime');
    } catch (e) {
      debugPrint('❌ Failed to update last refresh time: $e');
    }
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    try {
      _isInitialized = false;
      _prefs = null;
      debugPrint('✅ TodayFeedContentService disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose TodayFeedContentService: $e');
    }
  }
}
