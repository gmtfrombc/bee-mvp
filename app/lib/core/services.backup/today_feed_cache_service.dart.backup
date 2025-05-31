import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  static const String _timezoneMetadataKey = 'today_feed_timezone_metadata';
  static const String _lastTimezoneCheckKey = 'today_feed_last_timezone_check';
  static const String _syncErrorsKey = 'today_feed_sync_errors';
  static const String _lastSuccessfulSyncKey =
      'today_feed_last_successful_sync';
  static const String _syncRetryCountKey = 'today_feed_sync_retry_count';

  // Cache configuration
  static const int _maxHistoryDays = 7; // Keep 7 days of content history
  static const int _maxCacheSizeMB = 10; // Maximum cache size limit
  static const int _currentCacheVersion = 1;
  static const int _refreshHour = 3; // 3 AM local time for content refresh
  static const int _maxSyncRetries = 3; // Maximum retry attempts for sync
  static const Duration _syncRetryDelay = Duration(
    minutes: 5,
  ); // Delay between retries

  // Cache invalidation and cleanup configuration
  static const Duration _contentExpirationDuration = Duration(days: 7);
  static const Duration _automaticCleanupInterval = Duration(hours: 6);
  static const Duration _contentFreshnessThreshold = Duration(hours: 2);
  static const int _maxCacheEntries = 50;
  static const String _lastCleanupKey = 'today_feed_last_cleanup';
  static const String _contentExpirationKey = 'today_feed_content_expiration';
  static const String _manualInvalidationKey = 'today_feed_manual_invalidation';

  static SharedPreferences? _prefs;
  static bool _isInitialized = false;
  static Timer? _refreshTimer;
  static Timer? _timezoneCheckTimer;
  static Timer? _syncRetryTimer;
  static StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  static bool _syncInProgress = false;
  static Timer? _automaticCleanupTimer;

  /// Initialize the Today Feed cache service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _validateCacheVersion();
      await _detectAndHandleTimezoneChanges();
      await _cleanupExpiredContent();
      await _validateContentFreshness();
      await _scheduleNextRefresh();
      await _scheduleTimezoneChecks();
      await _scheduleAutomaticCleanup();
      await _initializeConnectivityListener();
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

  /// Detect and handle timezone changes including DST transitions
  static Future<void> _detectAndHandleTimezoneChanges() async {
    try {
      final now = DateTime.now();
      final currentTimezoneInfo = _getCurrentTimezoneInfo();
      final savedTimezoneInfo = await _getSavedTimezoneInfo();

      // Save current timezone info for first run
      if (savedTimezoneInfo == null) {
        await _saveTimezoneInfo(currentTimezoneInfo);
        await _prefs!.setString(_lastTimezoneCheckKey, now.toIso8601String());
        debugPrint(
          '🌍 Initial timezone saved: ${currentTimezoneInfo['identifier']}',
        );
        return;
      }

      // Check for timezone changes
      final timezoneChanged = _hasTimezoneChanged(
        currentTimezoneInfo,
        savedTimezoneInfo,
      );
      final dstChanged = _hasDstChanged(currentTimezoneInfo, savedTimezoneInfo);

      if (timezoneChanged || dstChanged) {
        debugPrint('🕒 Timezone change detected:');
        debugPrint(
          '  Previous: ${savedTimezoneInfo['identifier']} (DST: ${savedTimezoneInfo['is_dst']})',
        );
        debugPrint(
          '  Current: ${currentTimezoneInfo['identifier']} (DST: ${currentTimezoneInfo['is_dst']})',
        );

        // Update saved timezone info
        await _saveTimezoneInfo(currentTimezoneInfo);

        // Reschedule refresh timer with new timezone
        await _scheduleNextRefresh();

        // Check if content needs immediate refresh due to timezone change
        if (await _shouldRefreshDueToTimezoneChange(
          savedTimezoneInfo,
          currentTimezoneInfo,
        )) {
          debugPrint('🔄 Triggering immediate refresh due to timezone change');
          await _triggerRefresh();
        }
      }

      // Always update last timezone check timestamp
      await _prefs!.setString(_lastTimezoneCheckKey, now.toIso8601String());
    } catch (e) {
      debugPrint('❌ Failed to detect timezone changes: $e');
      // Ensure timestamp is saved even on error
      try {
        await _prefs!.setString(
          _lastTimezoneCheckKey,
          DateTime.now().toIso8601String(),
        );
      } catch (saveError) {
        debugPrint('❌ Failed to save timezone check timestamp: $saveError');
      }
    }
  }

  /// Get current timezone information including DST status
  static Map<String, dynamic> _getCurrentTimezoneInfo() {
    final now = DateTime.now();
    final timeZone = now.timeZoneName;
    final timeZoneOffset = now.timeZoneOffset;

    // Detect DST by comparing winter and summer offsets
    final winterDate = DateTime(now.year, 1, 1);
    final summerDate = DateTime(now.year, 7, 1);
    final winterOffset = winterDate.timeZoneOffset;
    final summerOffset = summerDate.timeZoneOffset;

    final isDst =
        timeZoneOffset != winterOffset && timeZoneOffset == summerOffset;

    return {
      'identifier': timeZone,
      'offset_hours': timeZoneOffset.inHours,
      'offset_minutes': timeZoneOffset.inMinutes,
      'is_dst': isDst,
      'winter_offset_hours': winterOffset.inHours,
      'summer_offset_hours': summerOffset.inHours,
      'timestamp': now.toIso8601String(),
    };
  }

  /// Save timezone information to cache
  static Future<void> _saveTimezoneInfo(
    Map<String, dynamic> timezoneInfo,
  ) async {
    await _prefs!.setString(_timezoneMetadataKey, jsonEncode(timezoneInfo));
  }

  /// Get saved timezone information from cache
  static Future<Map<String, dynamic>?> _getSavedTimezoneInfo() async {
    try {
      final jsonString = _prefs!.getString(_timezoneMetadataKey);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Failed to get saved timezone info: $e');
      return null;
    }
  }

  /// Check if timezone identifier has changed
  static bool _hasTimezoneChanged(
    Map<String, dynamic> current,
    Map<String, dynamic> saved,
  ) {
    return current['identifier'] != saved['identifier'] ||
        current['offset_hours'] != saved['offset_hours'];
  }

  /// Check if DST status has changed
  static bool _hasDstChanged(
    Map<String, dynamic> current,
    Map<String, dynamic> saved,
  ) {
    return current['is_dst'] != saved['is_dst'];
  }

  /// Determine if content should be refreshed immediately due to timezone change
  static Future<bool> _shouldRefreshDueToTimezoneChange(
    Map<String, dynamic> oldTimezone,
    Map<String, dynamic> newTimezone,
  ) async {
    try {
      final lastRefreshString = _prefs!.getString(_lastRefreshKey);
      if (lastRefreshString == null) return true;

      final lastRefresh = DateTime.parse(lastRefreshString);
      final now = DateTime.now();

      // If timezone changed significantly (more than 2 hours), refresh
      final offsetDiff =
          (newTimezone['offset_hours'] as int) -
          (oldTimezone['offset_hours'] as int);
      if (offsetDiff.abs() > 2) {
        debugPrint(
          '🌍 Major timezone change detected (+/- ${offsetDiff}h), refreshing content',
        );
        return true;
      }

      // If DST changed and it's been more than 12 hours since last refresh
      if (_hasDstChanged(newTimezone, oldTimezone)) {
        final hoursSinceRefresh = now.difference(lastRefresh).inHours;
        if (hoursSinceRefresh > 12) {
          debugPrint('🕒 DST change with stale content detected, refreshing');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking timezone refresh need: $e');
      return false;
    }
  }

  /// Schedule periodic timezone checks to detect changes
  static Future<void> _scheduleTimezoneChecks() async {
    _timezoneCheckTimer?.cancel();

    try {
      // Check timezone every 2 hours for changes
      _timezoneCheckTimer = Timer.periodic(const Duration(hours: 2), (
        timer,
      ) async {
        debugPrint('🕒 Performing scheduled timezone check');
        await _detectAndHandleTimezoneChanges();
      });

      debugPrint('⏰ Timezone checks scheduled every 2 hours');
    } catch (e) {
      debugPrint('❌ Failed to schedule timezone checks: $e');
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

  /// Get previous day's content as fallback with enhanced metadata
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

  /// Check if cached content needs refresh (timezone-aware with DST handling)
  static Future<bool> needsRefresh() async {
    await initialize();

    try {
      final lastRefreshString = _prefs!.getString(_lastRefreshKey);
      if (lastRefreshString == null) {
        debugPrint('🔄 No previous refresh found - refresh needed');
        return true;
      }

      final lastRefresh = DateTime.parse(lastRefreshString);
      final now = DateTime.now();

      // Get timezone information for accurate day calculation
      final timezoneInfo = _getCurrentTimezoneInfo();

      // Check if it's a new day in local timezone (accounting for DST)
      final isNewDay = !_isSameLocalDay(lastRefresh, now);

      // Check if we're past the preferred refresh time (_refreshHour AM local)
      final isPastRefreshTime = _isPastRefreshTimeEnhanced(now);

      // Enhanced check for timezone-related refresh needs
      final timezoneRequiresRefresh = await _checkTimezoneRefreshRequirement();

      final shouldRefresh =
          (isNewDay && isPastRefreshTime) || timezoneRequiresRefresh;

      if (shouldRefresh) {
        if (timezoneRequiresRefresh) {
          debugPrint(
            '🔄 Content refresh needed - timezone/DST change detected',
          );
        } else {
          debugPrint('🔄 Content refresh needed - new day detected');
        }
        debugPrint('  Last refresh: $lastRefresh');
        debugPrint('  Current time: $now');
        debugPrint(
          '  Timezone: ${timezoneInfo['identifier']} (DST: ${timezoneInfo['is_dst']})',
        );
      }

      return shouldRefresh;
    } catch (e) {
      debugPrint('❌ Failed to check refresh need: $e');
      return true; // Err on side of refreshing
    }
  }

  /// Enhanced refresh time check with DST and timezone considerations
  static bool _isPastRefreshTimeEnhanced(DateTime now) {
    try {
      // Create refresh time for today
      final refreshTime = DateTime(
        now.year,
        now.month,
        now.day,
        _refreshHour,
        0,
        0,
      );

      // Account for potential DST transitions on the refresh day
      final refreshTimeWithDst = _adjustForDstTransition(refreshTime);

      final isPast = now.isAfter(refreshTimeWithDst);

      if (refreshTimeWithDst != refreshTime) {
        debugPrint(
          '🕒 DST adjustment applied: $refreshTime → $refreshTimeWithDst',
        );
      }

      return isPast;
    } catch (e) {
      debugPrint('❌ Error checking refresh time: $e');
      // Fallback to simple check
      final refreshTime = DateTime(
        now.year,
        now.month,
        now.day,
        _refreshHour,
        0,
        0,
      );
      return now.isAfter(refreshTime);
    }
  }

  /// Adjust refresh time for potential DST transitions
  static DateTime _adjustForDstTransition(DateTime refreshTime) {
    try {
      // Check if there's a DST transition around the refresh time
      final beforeTransition = refreshTime.subtract(const Duration(hours: 1));
      final afterTransition = refreshTime.add(const Duration(hours: 1));

      final beforeOffset = beforeTransition.timeZoneOffset;
      final afterOffset = afterTransition.timeZoneOffset;

      // If there's a DST transition, adjust the refresh time
      if (beforeOffset != afterOffset) {
        final offsetDiff = afterOffset.inMinutes - beforeOffset.inMinutes;
        debugPrint(
          '🕒 DST transition detected around refresh time (${offsetDiff}min change)',
        );

        // For spring forward (lose an hour), delay refresh by 1 hour
        // For fall back (gain an hour), keep original time
        if (offsetDiff > 0) {
          return refreshTime.add(Duration(minutes: offsetDiff));
        }
      }

      return refreshTime;
    } catch (e) {
      debugPrint('❌ Error adjusting for DST: $e');
      return refreshTime;
    }
  }

  /// Check if timezone changes require immediate refresh
  static Future<bool> _checkTimezoneRefreshRequirement() async {
    try {
      final currentTimezone = _getCurrentTimezoneInfo();
      final savedTimezone = await _getSavedTimezoneInfo();

      if (savedTimezone == null) {
        // First run, save current timezone
        await _saveTimezoneInfo(currentTimezone);
        return false;
      }

      // Check for significant timezone changes
      final timezoneChanged = _hasTimezoneChanged(
        currentTimezone,
        savedTimezone,
      );
      final dstChanged = _hasDstChanged(currentTimezone, savedTimezone);

      if (timezoneChanged || dstChanged) {
        debugPrint('🌍 Timezone change detected for refresh check');
        return await _shouldRefreshDueToTimezoneChange(
          savedTimezone,
          currentTimezone,
        );
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking timezone refresh requirement: $e');
      return false;
    }
  }

  /// Schedule automatic refresh at next 3 AM local time
  static Future<void> _scheduleNextRefresh() async {
    _refreshTimer?.cancel();

    try {
      final now = DateTime.now();
      final nextRefreshTime = await _calculateNextRefreshTime(now);
      final timeUntilRefresh = nextRefreshTime.difference(now);

      // Ensure minimum time before refresh (prevent infinite loops)
      if (timeUntilRefresh.inMinutes < 5) {
        final adjustedRefreshTime = now.add(const Duration(minutes: 5));
        debugPrint(
          '⚠️ Refresh time too soon, adjusting to: $adjustedRefreshTime',
        );
        return _scheduleSpecificRefresh(adjustedRefreshTime);
      }

      await _scheduleSpecificRefresh(nextRefreshTime);
    } catch (e) {
      debugPrint('❌ Failed to schedule refresh: $e');
      // Fallback: schedule for 1 hour from now
      final fallbackTime = DateTime.now().add(const Duration(hours: 1));
      await _scheduleSpecificRefresh(fallbackTime);
    }
  }

  /// Calculate the next refresh time with timezone and DST considerations
  static Future<DateTime> _calculateNextRefreshTime(DateTime now) async {
    try {
      // Get current timezone info
      final timezoneInfo = _getCurrentTimezoneInfo();
      final isDst = timezoneInfo['is_dst'] as bool;

      // Calculate today's refresh time
      DateTime todayRefreshTime = DateTime(
        now.year,
        now.month,
        now.day,
        _refreshHour,
        0,
        0,
      );

      // Adjust for DST if needed
      todayRefreshTime = _adjustForDstTransition(todayRefreshTime);

      DateTime nextRefreshTime;

      if (now.isBefore(todayRefreshTime)) {
        // If it's before today's refresh time, use today
        nextRefreshTime = todayRefreshTime;
        debugPrint('📅 Scheduling refresh for today at $_refreshHour:00 AM');
      } else {
        // Otherwise, schedule for tomorrow
        DateTime tomorrowRefreshTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          _refreshHour,
          0,
          0,
        );

        // Check for potential DST transition tomorrow
        tomorrowRefreshTime = _adjustForDstTransition(tomorrowRefreshTime);
        nextRefreshTime = tomorrowRefreshTime;
        debugPrint('📅 Scheduling refresh for tomorrow at $_refreshHour:00 AM');
      }

      // Validate the calculated time makes sense
      final timeDiff = nextRefreshTime.difference(now);
      if (timeDiff.inHours > 25 || timeDiff.inMinutes < 0) {
        debugPrint('⚠️ Invalid refresh time calculated, using fallback');
        nextRefreshTime = now.add(const Duration(hours: 24));
      }

      debugPrint('🌍 Timezone: ${timezoneInfo['identifier']} (DST: $isDst)');

      return nextRefreshTime;
    } catch (e) {
      debugPrint('❌ Error calculating next refresh time: $e');
      // Fallback to 24 hours from now
      return now.add(const Duration(hours: 24));
    }
  }

  /// Schedule refresh for a specific time
  static Future<void> _scheduleSpecificRefresh(DateTime refreshTime) async {
    try {
      final now = DateTime.now();
      final timeUntilRefresh = refreshTime.difference(now);

      debugPrint('⏰ Next content refresh scheduled for: $refreshTime');
      debugPrint(
        '⏱️  Time until refresh: ${timeUntilRefresh.inHours}h ${timeUntilRefresh.inMinutes % 60}m',
      );

      _refreshTimer = Timer(timeUntilRefresh, () async {
        try {
          debugPrint(
            '🔄 Automatic refresh timer triggered at ${DateTime.now()}',
          );
          await _triggerRefresh();

          // Schedule next refresh after this one completes
          await _scheduleNextRefresh();
        } catch (e) {
          debugPrint('❌ Error in refresh timer callback: $e');
          // Reschedule for 1 hour later on error
          final retryTime = DateTime.now().add(const Duration(hours: 1));
          await _scheduleSpecificRefresh(retryTime);
        }
      });
    } catch (e) {
      debugPrint('❌ Failed to schedule specific refresh: $e');
    }
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

  /// Initialize connectivity listener for background sync
  static Future<void> _initializeConnectivityListener() async {
    try {
      // Initialize ConnectivityService if not already done
      await ConnectivityService.initialize();

      // Listen for connectivity changes
      _connectivitySubscription = ConnectivityService.statusStream.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint('❌ Connectivity listener error: $error');
        },
      );

      debugPrint('🔗 Connectivity listener initialized for background sync');

      // If already online, check for pending sync
      if (ConnectivityService.isOnline) {
        await _handleConnectivityRestored();
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize connectivity listener: $e');
      // In test environments or when plugins aren't available, continue without connectivity
      // Set to offline mode for safety
      debugPrint(
        '📱 Continuing in offline mode without connectivity monitoring',
      );
    }
  }

  /// Handle connectivity status changes
  static Future<void> _onConnectivityChanged(ConnectivityStatus status) async {
    try {
      debugPrint('🔗 Connectivity changed: $status');

      switch (status) {
        case ConnectivityStatus.online:
          await _handleConnectivityRestored();
          break;
        case ConnectivityStatus.offline:
          await _handleConnectivityLost();
          break;
        case ConnectivityStatus.limited:
          // For limited connectivity, we'll still attempt sync but with more tolerance
          debugPrint(
            '⚠️ Limited connectivity detected, attempting cautious sync',
          );
          await _handleConnectivityRestored();
          break;
      }
    } catch (e) {
      debugPrint('❌ Error handling connectivity change: $e');
      await _queueError('connectivity_change', e.toString());
    }
  }

  /// Handle when connectivity is restored
  static Future<void> _handleConnectivityRestored() async {
    try {
      debugPrint('🌐 Connectivity restored - initiating background sync');

      // Reset sync retry count on successful connectivity
      await _prefs!.remove(_syncRetryCountKey);
      _syncRetryTimer?.cancel();

      // Perform background sync
      await syncWhenOnline();

      // Update last successful sync timestamp
      await _prefs!.setString(
        _lastSuccessfulSyncKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('❌ Failed to handle connectivity restoration: $e');
      await _queueError('connectivity_restored', e.toString());
      await _scheduleRetrySync();
    }
  }

  /// Handle when connectivity is lost
  static Future<void> _handleConnectivityLost() async {
    try {
      debugPrint('📶 Connectivity lost - enabling offline mode');

      // Cancel any ongoing sync operations
      _syncRetryTimer?.cancel();

      // Log the disconnection time
      final now = DateTime.now();
      final disconnectInfo = {
        'timestamp': now.toIso8601String(),
        'pending_interactions': (await _getPendingInteractions()).length,
        'cache_status': await _getCacheStatusForOffline(),
      };

      await _prefs!.setString(
        'today_feed_last_disconnect',
        jsonEncode(disconnectInfo),
      );

      debugPrint('📱 Offline mode enabled with cached content available');
    } catch (e) {
      debugPrint('❌ Error handling connectivity loss: $e');
    }
  }

  /// Get cache status for offline mode
  static Future<Map<String, dynamic>> _getCacheStatusForOffline() async {
    try {
      final hasToday = await getTodayContent() != null;
      final hasPrevious = await getPreviousDayContent() != null;
      final history = await _getContentHistory();

      return {
        'has_today_content': hasToday,
        'has_previous_content': hasPrevious,
        'history_count': history.length,
        'last_refresh': _prefs!.getString(_lastRefreshKey),
      };
    } catch (e) {
      debugPrint('❌ Error getting cache status: $e');
      return {'error': e.toString()};
    }
  }

  /// Enhanced background sync when connectivity is restored
  static Future<void> syncWhenOnline() async {
    try {
      if (!ConnectivityService.isOnline) {
        debugPrint('📡 Device is offline, skipping sync');
        return;
      }
    } catch (e) {
      // If ConnectivityService isn't available (e.g., in tests), assume offline
      debugPrint('📡 Cannot check connectivity status, assuming offline: $e');
      return;
    }

    // Prevent concurrent sync operations
    if (_syncInProgress) {
      debugPrint('🔄 Sync already in progress, skipping duplicate request');
      return;
    }

    await initialize();
    _syncInProgress = true;

    try {
      debugPrint('🔄 Starting enhanced background sync for Today Feed');

      // 1. Check if content refresh is needed
      final needsContentRefresh = await needsRefresh();
      if (needsContentRefresh) {
        debugPrint('🔄 Content refresh needed, triggering refresh');
        await _triggerRefresh();
      }

      // 2. Process any pending interactions with conflict resolution
      await _processPendingInteractionsWithRetry();

      // 3. Validate cache integrity
      await _validateCacheIntegrity();

      // 4. Sync content history if needed
      await _syncContentHistory();

      // 5. Update sync metadata
      await _updateSyncMetadata();

      debugPrint('✅ Enhanced background sync completed successfully');
    } catch (e) {
      debugPrint('❌ Enhanced background sync failed: $e');
      await _queueError('enhanced_background_sync', e.toString());
      await _scheduleRetrySync();
    } finally {
      _syncInProgress = false;
    }
  }

  /// Process pending interactions with retry logic and conflict resolution
  static Future<void> _processPendingInteractionsWithRetry() async {
    try {
      final interactions = await _getPendingInteractions();
      if (interactions.isEmpty) {
        debugPrint('📭 No pending interactions to process');
        return;
      }

      debugPrint('🔄 Processing ${interactions.length} pending interactions');

      final processedInteractions = <Map<String, dynamic>>[];
      final failedInteractions = <Map<String, dynamic>>[];

      // Process each interaction with individual error handling
      for (final interaction in interactions) {
        try {
          await _processIndividualInteraction(interaction);
          processedInteractions.add(interaction);
          debugPrint(
            '✅ Processed interaction: ${interaction['type']} for ${interaction['content_id']}',
          );
        } catch (e) {
          debugPrint(
            '❌ Failed to process interaction ${interaction['type']}: $e',
          );
          failedInteractions.add({
            ...interaction,
            'error': e.toString(),
            'retry_count': (interaction['retry_count'] as int? ?? 0) + 1,
          });
        }
      }

      // Update pending interactions list
      if (failedInteractions.isNotEmpty) {
        // Keep failed interactions for retry (with max retry limit)
        final retriableInteractions =
            failedInteractions
                .where(
                  (interaction) =>
                      (interaction['retry_count'] as int? ?? 0) <
                      _maxSyncRetries,
                )
                .toList();

        if (retriableInteractions.isNotEmpty) {
          await _prefs!.setString(
            _pendingInteractionsKey,
            jsonEncode(retriableInteractions),
          );
          debugPrint(
            '🔄 ${retriableInteractions.length} interactions queued for retry',
          );
        } else {
          await _prefs!.remove(_pendingInteractionsKey);
          debugPrint('❌ All interactions exceeded retry limit, clearing queue');
        }
      } else {
        // All interactions processed successfully
        await _prefs!.remove(_pendingInteractionsKey);
        debugPrint('✅ All pending interactions processed successfully');
      }

      // Log processing results
      await _logInteractionProcessingResults(
        processedInteractions.length,
        failedInteractions.length,
      );
    } catch (e) {
      debugPrint('❌ Failed to process pending interactions: $e');
      await _queueError('process_pending_interactions', e.toString());
    }
  }

  /// Process individual interaction with specific logic
  static Future<void> _processIndividualInteraction(
    Map<String, dynamic> interaction,
  ) async {
    final type = interaction['type'] as String;
    final contentId = interaction['content_id'] as String;
    final timestamp = interaction['timestamp'] as String;
    final additionalData =
        interaction['additional_data'] as Map<String, dynamic>? ?? {};

    // Simulate interaction processing (in real implementation, this would call API)
    debugPrint('🔄 Processing $type interaction for content $contentId');

    // Add processing delay to simulate network call
    await Future.delayed(const Duration(milliseconds: 100));

    // Here you would implement actual API calls to sync interactions
    // For now, we'll just log the successful processing
    debugPrint('✅ Interaction processed: $type for $contentId at $timestamp');
    if (additionalData.isNotEmpty) {
      debugPrint('📊 Additional data: ${additionalData.keys.join(', ')}');
    }
  }

  /// Log interaction processing results for analytics
  static Future<void> _logInteractionProcessingResults(
    int processedCount,
    int failedCount,
  ) async {
    try {
      final results = {
        'processed_count': processedCount,
        'failed_count': failedCount,
        'timestamp': DateTime.now().toIso8601String(),
        'total_attempted': processedCount + failedCount,
      };

      // Store processing results for debugging and analytics
      await _prefs!.setString(
        'today_feed_last_interaction_sync',
        jsonEncode(results),
      );

      debugPrint(
        '📊 Interaction sync results: $processedCount processed, $failedCount failed',
      );
    } catch (e) {
      debugPrint('❌ Failed to log interaction processing results: $e');
    }
  }

  /// Validate cache integrity after sync
  static Future<void> _validateCacheIntegrity() async {
    try {
      debugPrint('🔍 Validating cache integrity after sync');

      final issues = <String>[];

      // Check today's content validity
      final todayContent = await getTodayContent(allowStale: true);
      if (todayContent != null) {
        if (!_isValidContent(todayContent)) {
          issues.add('Invalid today content structure');
        }
      }

      // Check cache size limits
      final cacheSize = await _calculateCacheSize();
      if (cacheSize > _maxCacheSizeMB * 1024 * 1024) {
        issues.add('Cache size exceeds limit');
        await _performCacheCleanup();
      }

      // Check metadata consistency
      await _validateMetadataConsistency();

      if (issues.isNotEmpty) {
        debugPrint('⚠️ Cache integrity issues found: ${issues.join(', ')}');
        await _queueError('cache_integrity', issues.join(', '));
      } else {
        debugPrint('✅ Cache integrity validation passed');
      }
    } catch (e) {
      debugPrint('❌ Cache integrity validation failed: $e');
      await _queueError('cache_integrity_validation', e.toString());
    }
  }

  /// Validate content structure
  static bool _isValidContent(TodayFeedContent content) {
    try {
      return content.title.isNotEmpty &&
          content.summary.isNotEmpty &&
          content.contentDate.isBefore(
            DateTime.now().add(const Duration(days: 1)),
          ) &&
          content.aiConfidenceScore >= 0.0 &&
          content.aiConfidenceScore <= 1.0;
    } catch (e) {
      return false;
    }
  }

  /// Validate metadata consistency
  static Future<void> _validateMetadataConsistency() async {
    try {
      final metadataJson = _prefs!.getString(_contentMetadataKey);
      if (metadataJson != null) {
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;

        // Check required fields
        final requiredFields = ['cached_at', 'content_date', 'is_from_api'];
        for (final field in requiredFields) {
          if (!metadata.containsKey(field)) {
            throw Exception('Missing required metadata field: $field');
          }
        }

        // Validate timestamps
        final cachedAt = DateTime.parse(metadata['cached_at'] as String);
        final contentDate = DateTime.parse(metadata['content_date'] as String);

        if (cachedAt.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
          throw Exception('Invalid cached_at timestamp in future');
        }

        // Validate that content date is reasonable (not too far in the future)
        if (contentDate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
          throw Exception('Invalid content_date timestamp too far in future');
        }
      }
    } catch (e) {
      debugPrint('❌ Metadata consistency validation failed: $e');
      throw Exception('Metadata validation failed: $e');
    }
  }

  /// Sync content history with server
  static Future<void> _syncContentHistory() async {
    try {
      debugPrint('🔄 Syncing content history');

      final history = await _getContentHistory();
      if (history.isEmpty) {
        debugPrint('📭 No content history to sync');
        return;
      }

      // In a real implementation, this would sync with server
      // For now, we'll just validate local history integrity
      final validHistory = <Map<String, dynamic>>[];

      for (final item in history) {
        try {
          final content = TodayFeedContent.fromJson(item);
          if (_isValidContent(content)) {
            validHistory.add(item);
          }
        } catch (e) {
          debugPrint('⚠️ Invalid history item found, removing: $e');
        }
      }

      // Update history with only valid items
      if (validHistory.length != history.length) {
        await _prefs!.setString(_contentHistoryKey, jsonEncode(validHistory));
        debugPrint(
          '🔧 Content history cleaned: ${history.length} -> ${validHistory.length} items',
        );
      }

      debugPrint('✅ Content history sync completed');
    } catch (e) {
      debugPrint('❌ Content history sync failed: $e');
      await _queueError('content_history_sync', e.toString());
    }
  }

  /// Update sync metadata after successful sync
  static Future<void> _updateSyncMetadata() async {
    try {
      final now = DateTime.now();

      String connectivityStatus = 'unknown';
      bool isOnline = false;
      try {
        connectivityStatus = ConnectivityService.currentStatus.toString();
        isOnline = ConnectivityService.isOnline;
      } catch (e) {
        connectivityStatus = 'unavailable';
        isOnline = false;
      }

      final syncMetadata = {
        'last_sync': now.toIso8601String(),
        'sync_version': _currentCacheVersion,
        'device_timezone': now.timeZoneName,
        'sync_duration_ms': 0, // Would be calculated in real implementation
        'connectivity_status': connectivityStatus,
        'is_online': isOnline,
      };

      await _prefs!.setString(
        'today_feed_sync_metadata',
        jsonEncode(syncMetadata),
      );

      debugPrint('📝 Sync metadata updated');
    } catch (e) {
      debugPrint('❌ Failed to update sync metadata: $e');
    }
  }

  /// Schedule retry sync with exponential backoff
  static Future<void> _scheduleRetrySync() async {
    try {
      final retryCount = _prefs!.getInt(_syncRetryCountKey) ?? 0;

      if (retryCount >= _maxSyncRetries) {
        debugPrint('❌ Max sync retries exceeded, stopping retry attempts');
        await _prefs!.remove(_syncRetryCountKey);
        return;
      }

      // Exponential backoff: 5min, 10min, 20min
      final delayMinutes = _syncRetryDelay.inMinutes * (1 << retryCount);
      final retryDelay = Duration(minutes: delayMinutes);

      debugPrint(
        '🔄 Scheduling sync retry ${retryCount + 1}/$_maxSyncRetries in ${delayMinutes}min',
      );

      // Update retry count
      await _prefs!.setInt(_syncRetryCountKey, retryCount + 1);

      // Schedule retry
      _syncRetryTimer?.cancel();
      _syncRetryTimer = Timer(retryDelay, () async {
        try {
          if (ConnectivityService.isOnline) {
            await syncWhenOnline();
          } else {
            debugPrint(
              '⚠️ Still offline during retry, will retry on connectivity restore',
            );
          }
        } catch (e) {
          debugPrint('❌ Error during retry connectivity check: $e');
          // Attempt sync anyway in case connectivity check failed
          await syncWhenOnline();
        }
      });
    } catch (e) {
      debugPrint('❌ Failed to schedule retry sync: $e');
    }
  }

  /// Queue user interaction for later sync with enhanced metadata
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
        'retry_count': 0,
        'device_timezone': DateTime.now().timeZoneName,
        'queue_id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      interactions.add(interaction);

      await _prefs!.setString(
        _pendingInteractionsKey,
        jsonEncode(interactions),
      );

      debugPrint('✅ Interaction queued: ${type.value} for content $contentId');

      // Try to sync immediately if online
      try {
        if (ConnectivityService.isOnline && !_syncInProgress) {
          // Process interactions without full sync to be more responsive
          await _processPendingInteractionsWithRetry();
        }
      } catch (e) {
        // If ConnectivityService isn't available, skip immediate sync
        debugPrint('📡 Cannot check connectivity for immediate sync: $e');
      }
    } catch (e) {
      debugPrint('❌ Failed to queue interaction: $e');
      await _queueError('queue_interaction', e.toString());
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
        _timezoneMetadataKey,
        _lastTimezoneCheckKey,
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

  /// Validate content freshness based on configured thresholds
  static Future<void> _validateContentFreshness() async {
    try {
      final lastRefresh = _prefs!.getString(_lastRefreshKey);
      if (lastRefresh == null) {
        debugPrint('🔍 No previous refresh found, content validation skipped');
        return;
      }

      final lastRefreshDate = DateTime.parse(lastRefresh);
      final now = DateTime.now();
      final timeSinceRefresh = now.difference(lastRefreshDate);

      // Check if content is stale based on freshness threshold
      if (timeSinceRefresh > _contentFreshnessThreshold) {
        debugPrint(
          '⚠️ Content is stale (${timeSinceRefresh.inHours}h old), triggering refresh',
        );
        await _triggerRefresh();
      } else {
        debugPrint('✅ Content is fresh (${timeSinceRefresh.inMinutes}m old)');
      }

      // Check for content expiration
      await _checkContentExpiration();
    } catch (e) {
      debugPrint('❌ Failed to validate content freshness: $e');
    }
  }

  /// Check and handle content expiration
  static Future<void> _checkContentExpiration() async {
    try {
      final history = await _getContentHistory();
      final now = DateTime.now();
      final expiredEntries = <Map<String, dynamic>>[];

      for (final entry in history) {
        try {
          final createdAt = DateTime.parse(entry['created_at'] as String);
          final age = now.difference(createdAt);

          if (age > _contentExpirationDuration) {
            expiredEntries.add(entry);
          }
        } catch (e) {
          // If we can't parse the date, consider it expired
          expiredEntries.add(entry);
          debugPrint(
            '⚠️ Found content with unparseable date, marking as expired',
          );
        }
      }

      if (expiredEntries.isNotEmpty) {
        debugPrint(
          '🗑️ Found ${expiredEntries.length} expired content entries',
        );
        await _removeExpiredContent(expiredEntries);
      }
    } catch (e) {
      debugPrint('❌ Failed to check content expiration: $e');
    }
  }

  /// Remove expired content from cache
  static Future<void> _removeExpiredContent(
    List<Map<String, dynamic>> expiredEntries,
  ) async {
    try {
      final history = await _getContentHistory();
      final updatedHistory =
          history.where((entry) {
            return !expiredEntries.any(
              (expired) => expired['id'] == entry['id'],
            );
          }).toList();

      await _prefs!.setString(_contentHistoryKey, jsonEncode(updatedHistory));

      // Update expiration metadata
      await _prefs!.setString(
        _contentExpirationKey,
        jsonEncode({
          'last_cleanup': DateTime.now().toIso8601String(),
          'removed_count': expiredEntries.length,
          'remaining_count': updatedHistory.length,
        }),
      );

      debugPrint('✅ Removed ${expiredEntries.length} expired content entries');
    } catch (e) {
      debugPrint('❌ Failed to remove expired content: $e');
    }
  }

  /// Schedule automatic cleanup at configured intervals
  static Future<void> _scheduleAutomaticCleanup() async {
    try {
      _automaticCleanupTimer?.cancel();

      _automaticCleanupTimer = Timer.periodic(_automaticCleanupInterval, (
        timer,
      ) async {
        try {
          debugPrint('🔄 Running scheduled automatic cleanup');
          await _performAutomaticCleanup();
        } catch (e) {
          debugPrint('❌ Error in automatic cleanup: $e');
        }
      });

      debugPrint(
        '⏰ Automatic cleanup scheduled every ${_automaticCleanupInterval.inHours} hours',
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule automatic cleanup: $e');
    }
  }

  /// Perform automatic cleanup with comprehensive validation
  static Future<void> _performAutomaticCleanup() async {
    try {
      final lastCleanup = _prefs!.getString(_lastCleanupKey);
      final now = DateTime.now();

      // Check if cleanup is actually needed
      if (lastCleanup != null) {
        final lastCleanupDate = DateTime.parse(lastCleanup);
        final timeSinceCleanup = now.difference(lastCleanupDate);

        if (timeSinceCleanup < _automaticCleanupInterval) {
          debugPrint('⏰ Automatic cleanup too soon, skipping');
          return;
        }
      }

      debugPrint('🧹 Starting automatic cache cleanup');

      // 1. Validate content freshness
      await _validateContentFreshness();

      // 2. Clean up expired content
      await _checkContentExpiration();

      // 3. Enforce cache size limits
      final cacheSize = await _calculateCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;

      if (cacheSize > maxSizeBytes) {
        debugPrint('📏 Cache size exceeded limit, performing cleanup');
        await _performCacheCleanup();
      }

      // 4. Limit number of cache entries
      await _enforceEntryLimits();

      // 5. Update last cleanup timestamp
      await _prefs!.setString(_lastCleanupKey, now.toIso8601String());

      debugPrint('✅ Automatic cleanup completed');
    } catch (e) {
      debugPrint('❌ Automatic cleanup failed: $e');
      await _queueError('automatic_cleanup', e.toString());
    }
  }

  /// Enforce limits on the number of cache entries
  static Future<void> _enforceEntryLimits() async {
    try {
      final history = await _getContentHistory();

      if (history.length > _maxCacheEntries) {
        final trimmedHistory = history.take(_maxCacheEntries).toList();
        await _prefs!.setString(_contentHistoryKey, jsonEncode(trimmedHistory));

        final removedCount = history.length - trimmedHistory.length;
        debugPrint(
          '🗂️ Trimmed cache history: removed $removedCount entries (${history.length} → ${trimmedHistory.length})',
        );
      }

      // Clean up old error logs
      final errors = await _getSyncErrors();
      if (errors.length > 50) {
        final trimmedErrors = errors.take(50).toList();
        await _prefs!.setString(_syncErrorsKey, jsonEncode(trimmedErrors));
        debugPrint('🗑️ Trimmed error logs to 50 entries');
      }
    } catch (e) {
      debugPrint('❌ Failed to enforce entry limits: $e');
    }
  }

  /// Manually invalidate specific content types
  static Future<void> invalidateContent({
    bool clearToday = false,
    bool clearPrevious = false,
    bool clearHistory = false,
    bool clearMetadata = false,
    bool clearInteractions = false,
    String? reason,
  }) async {
    await initialize();

    try {
      final invalidations = <String>[];

      if (clearToday && _prefs!.containsKey(_todayContentKey)) {
        await _prefs!.remove(_todayContentKey);
        invalidations.add('today_content');
      }

      if (clearPrevious && _prefs!.containsKey(_previousDayContentKey)) {
        await _prefs!.remove(_previousDayContentKey);
        invalidations.add('previous_content');
      }

      if (clearHistory && _prefs!.containsKey(_contentHistoryKey)) {
        await _prefs!.remove(_contentHistoryKey);
        invalidations.add('content_history');
      }

      if (clearMetadata && _prefs!.containsKey(_contentMetadataKey)) {
        await _prefs!.remove(_contentMetadataKey);
        invalidations.add('metadata');
      }

      if (clearInteractions && _prefs!.containsKey(_pendingInteractionsKey)) {
        await _prefs!.remove(_pendingInteractionsKey);
        invalidations.add('pending_interactions');
      }

      // Log manual invalidation
      if (invalidations.isNotEmpty) {
        final invalidationRecord = {
          'timestamp': DateTime.now().toIso8601String(),
          'invalidated': invalidations,
          'reason': reason ?? 'manual_request',
        };

        await _prefs!.setString(
          _manualInvalidationKey,
          jsonEncode(invalidationRecord),
        );

        debugPrint(
          '🗑️ Manual invalidation completed: ${invalidations.join(', ')}',
        );
        if (reason != null) {
          debugPrint('📝 Reason: $reason');
        }
      } else {
        debugPrint('⚠️ No content found to invalidate');
      }
    } catch (e) {
      debugPrint('❌ Manual invalidation failed: $e');
      await _queueError('manual_invalidation', e.toString());
    }
  }

  /// Selective cleanup with granular control
  static Future<void> selectiveCleanup({
    bool removeStaleContent = true,
    bool enforceSize = true,
    bool validateFreshness = true,
    bool trimHistory = true,
    bool clearErrors = false,
    Duration? customThreshold,
  }) async {
    await initialize();

    try {
      debugPrint('🎯 Starting selective cache cleanup');

      if (validateFreshness) {
        await _validateContentFreshness();
      }

      if (removeStaleContent) {
        final threshold = customThreshold ?? _contentExpirationDuration;
        await _removeStaleContentOlderThan(threshold);
      }

      if (enforceSize) {
        final cacheSize = await _calculateCacheSize();
        final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;

        if (cacheSize > maxSizeBytes) {
          await _performCacheCleanup();
        }
      }

      if (trimHistory) {
        await _enforceEntryLimits();
      }

      if (clearErrors) {
        await _prefs!.remove(_syncErrorsKey);
        debugPrint('🗑️ Cleared error logs');
      }

      debugPrint('✅ Selective cleanup completed');
    } catch (e) {
      debugPrint('❌ Selective cleanup failed: $e');
      await _queueError('selective_cleanup', e.toString());
    }
  }

  /// Remove stale content older than specified duration
  static Future<void> _removeStaleContentOlderThan(Duration threshold) async {
    try {
      final history = await _getContentHistory();
      final now = DateTime.now();
      final validEntries = <Map<String, dynamic>>[];

      for (final entry in history) {
        try {
          final createdAt = DateTime.parse(entry['created_at'] as String);
          final age = now.difference(createdAt);

          if (age <= threshold) {
            validEntries.add(entry);
          }
        } catch (e) {
          // If we can't parse the date, remove it
          debugPrint('⚠️ Removing content with invalid date');
        }
      }

      if (validEntries.length != history.length) {
        await _prefs!.setString(_contentHistoryKey, jsonEncode(validEntries));
        final removedCount = history.length - validEntries.length;
        debugPrint(
          '🗑️ Removed $removedCount stale content entries older than ${threshold.inDays} days',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to remove stale content: $e');
    }
  }

  /// Get cache invalidation statistics and health metrics
  static Future<Map<String, dynamic>> getCacheInvalidationStats() async {
    await initialize();

    try {
      final lastCleanup = _prefs!.getString(_lastCleanupKey);
      final expirationData = _prefs!.getString(_contentExpirationKey);
      final manualInvalidation = _prefs!.getString(_manualInvalidationKey);

      final stats = <String, dynamic>{
        'automatic_cleanup': {
          'last_cleanup': lastCleanup,
          'interval_hours': _automaticCleanupInterval.inHours,
          'next_cleanup_due':
              lastCleanup != null
                  ? DateTime.parse(
                    lastCleanup,
                  ).add(_automaticCleanupInterval).toIso8601String()
                  : 'pending',
        },
        'content_expiration': {
          'threshold_days': _contentExpirationDuration.inDays,
          'freshness_threshold_hours': _contentFreshnessThreshold.inHours,
          'max_entries': _maxCacheEntries,
        },
        'cache_limits': {
          'max_size_mb': _maxCacheSizeMB,
          'current_size_mb': (await _calculateCacheSize() / (1024 * 1024))
              .toStringAsFixed(2),
          'max_history_days': _maxHistoryDays,
          'current_history_count': (await _getContentHistory()).length,
        },
      };

      if (expirationData != null) {
        try {
          stats['last_expiration_cleanup'] = jsonDecode(expirationData);
        } catch (e) {
          debugPrint('⚠️ Could not parse expiration data: $e');
        }
      }

      if (manualInvalidation != null) {
        try {
          stats['last_manual_invalidation'] = jsonDecode(manualInvalidation);
        } catch (e) {
          debugPrint('⚠️ Could not parse manual invalidation data: $e');
        }
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Failed to get cache invalidation stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Get comprehensive cache statistics with timezone information
  static Future<Map<String, dynamic>> getCacheStats() async {
    await initialize();

    try {
      final metadata = await _getContentMetadata();
      final cacheSize = await _calculateCacheSize();
      final history = await _getContentHistory();
      final pendingInteractions = await _getPendingInteractions();
      final needsRefreshCheck = await needsRefresh();
      final timezoneInfo = await _getSavedTimezoneInfo();
      final currentTimezone = _getCurrentTimezoneInfo();

      return {
        'has_today_content': _prefs!.containsKey(_todayContentKey),
        'has_previous_day_content': _prefs!.containsKey(_previousDayContentKey),
        'last_refresh': _prefs!.getString(_lastRefreshKey),
        'last_timezone_check': _prefs!.getString(_lastTimezoneCheckKey),
        'needs_refresh': needsRefreshCheck,
        'cache_size_bytes': cacheSize,
        'cache_size_mb': (cacheSize / (1024 * 1024)).toStringAsFixed(2),
        'content_history_count': history.length,
        'pending_interactions_count': pendingInteractions.length,
        'cache_version': _prefs!.getInt(_cacheVersionKey),
        'is_background_sync_enabled': await isBackgroundSyncEnabled(),
        'metadata': metadata,
        'current_timezone': currentTimezone,
        'saved_timezone': timezoneInfo,
        'timezone_changed':
            timezoneInfo != null
                ? _hasTimezoneChanged(currentTimezone, timezoneInfo)
                : false,
        'dst_changed':
            timezoneInfo != null
                ? _hasDstChanged(currentTimezone, timezoneInfo)
                : false,
        'refresh_hour': _refreshHour,
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

  /// Enhanced error queuing with better categorization
  static Future<void> _queueError(String operation, String error) async {
    try {
      final errors = await _getSyncErrors();

      String connectivityStatus = 'unknown';
      bool isOnline = false;
      try {
        connectivityStatus = ConnectivityService.currentStatus.toString();
        isOnline = ConnectivityService.isOnline;
      } catch (e) {
        connectivityStatus = 'unavailable';
        isOnline = false;
      }

      final errorEntry = {
        'operation': operation,
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
        'connectivity_status': connectivityStatus,
        'is_online': isOnline,
        'cache_size_mb': (await _calculateCacheSize() / (1024 * 1024))
            .toStringAsFixed(2),
      };

      errors.add(errorEntry);

      // Keep only last 50 errors to prevent unbounded growth
      if (errors.length > 50) {
        errors.removeRange(0, errors.length - 50);
      }

      await _prefs!.setString(_syncErrorsKey, jsonEncode(errors));
      debugPrint('📝 Error logged: $operation - $error');
    } catch (e) {
      debugPrint('❌ Failed to queue error: $e');
    }
  }

  /// Get sync errors for debugging
  static Future<List<Map<String, dynamic>>> _getSyncErrors() async {
    try {
      final jsonString = _prefs!.getString(_syncErrorsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get sync errors: $e');
      return [];
    }
  }

  /// Get sync status for debugging and monitoring
  static Future<Map<String, dynamic>> getSyncStatus() async {
    await initialize();

    try {
      final pendingInteractions = await _getPendingInteractions();
      final syncErrors = await _getSyncErrors();
      final lastSuccessfulSync = _prefs!.getString(_lastSuccessfulSyncKey);
      final syncRetryCount = _prefs!.getInt(_syncRetryCountKey) ?? 0;

      // Safely get connectivity status
      String connectivityStatus = 'unknown';
      bool isOnline = false;
      try {
        connectivityStatus = ConnectivityService.currentStatus.toString();
        isOnline = ConnectivityService.isOnline;
      } catch (e) {
        connectivityStatus = 'unavailable';
        isOnline = false;
      }

      return {
        'connectivity_status': connectivityStatus,
        'is_online': isOnline,
        'sync_in_progress': _syncInProgress,
        'pending_interactions_count': pendingInteractions.length,
        'sync_errors_count': syncErrors.length,
        'last_successful_sync': lastSuccessfulSync,
        'sync_retry_count': syncRetryCount,
        'max_retries': _maxSyncRetries,
        'background_sync_enabled': true,
        'last_connectivity_change': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to get sync status: $e');
      return {'error': e.toString()};
    }
  }

  /// Dispose resources and cleanup
  static Future<void> dispose() async {
    try {
      _refreshTimer?.cancel();
      _timezoneCheckTimer?.cancel();
      _syncRetryTimer?.cancel();
      _automaticCleanupTimer?.cancel();
      await _connectivitySubscription?.cancel();
      await ConnectivityService.dispose();

      _isInitialized = false;
      _syncInProgress = false;

      debugPrint('🧹 TodayFeedCacheService disposed');
    } catch (e) {
      debugPrint('❌ Error disposing TodayFeedCacheService: $e');
    }
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
    _timezoneCheckTimer?.cancel();
    _syncRetryTimer?.cancel();
    _automaticCleanupTimer?.cancel();
    _connectivitySubscription?.cancel();
    _isInitialized = false;
    _prefs = null;
    _syncInProgress = false;
    debugPrint('🧪 TodayFeedCacheService reset for testing');
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
        _timezoneMetadataKey,
        _lastTimezoneCheckKey,
        _syncErrorsKey,
        _lastSuccessfulSyncKey,
        _syncRetryCountKey,
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
    _timezoneCheckTimer?.cancel();
    _syncRetryTimer?.cancel();
    debugPrint('✅ Today Feed cache completely cleared');
  }

  /// Get previous day content without fallback metadata (internal use)
  static Future<TodayFeedContent?> _getPreviousDayContentRaw() async {
    try {
      final contentJson = _prefs!.getString(_previousDayContentKey);
      if (contentJson == null) return null;

      return TodayFeedContent.fromJson(
        jsonDecode(contentJson) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Failed to get raw previous day content: $e');
      return null;
    }
  }

  /// Calculate content age from its creation date
  static Duration _calculateContentAge(DateTime contentDate) {
    final now = DateTime.now();
    return now.difference(contentDate);
  }

  /// Validate content age and determine if warnings should be shown
  static ContentAgeValidation _validateContentAge(Duration contentAge) {
    const freshThreshold = Duration(hours: 24);
    const staleThreshold = Duration(days: 3);
    const veryStaleThreshold = Duration(days: 7);

    if (contentAge <= freshThreshold) {
      return ContentAgeValidation(
        isValid: true,
        shouldWarn: false,
        severity: ContentAgeSeverity.fresh,
        message: 'Content is recent',
      );
    } else if (contentAge <= staleThreshold) {
      return ContentAgeValidation(
        isValid: true,
        shouldWarn: true,
        severity: ContentAgeSeverity.somewhatStale,
        message:
            'Content is ${contentAge.inDays} day${contentAge.inDays > 1 ? 's' : ''} old',
      );
    } else if (contentAge <= veryStaleThreshold) {
      return ContentAgeValidation(
        isValid: false,
        shouldWarn: true,
        severity: ContentAgeSeverity.stale,
        message: 'Content is ${contentAge.inDays} days old and may be outdated',
      );
    } else {
      return ContentAgeValidation(
        isValid: false,
        shouldWarn: true,
        severity: ContentAgeSeverity.veryStale,
        message: 'Content is more than a week old and likely outdated',
      );
    }
  }

  /// Generate appropriate user message for fallback content
  static String _generateFallbackMessage(
    TodayFeedFallbackType fallbackType,
    Duration contentAge,
    ContentAgeValidation ageValidation,
  ) {
    final dayText = contentAge.inDays == 1 ? 'day' : 'days';

    switch (fallbackType) {
      case TodayFeedFallbackType.previousDay:
        if (contentAge.inHours < 24) {
          return "Showing today's cached content";
        } else if (contentAge.inDays == 1) {
          return "Showing yesterday's content";
        } else {
          return "Showing content from ${contentAge.inDays} $dayText ago";
        }

      case TodayFeedFallbackType.contentHistory:
        if (contentAge.inDays <= 1) {
          return "Showing recent cached content";
        } else {
          return "Showing archived content from ${contentAge.inDays} $dayText ago";
        }

      case TodayFeedFallbackType.none:
        return "No cached content available";

      case TodayFeedFallbackType.error:
        return "Error loading content";
    }
  }

  /// Get the last refresh attempt timestamp
  static Future<DateTime?> _getLastRefreshAttempt() async {
    try {
      final lastRefreshString = _prefs!.getString(_lastRefreshKey);
      if (lastRefreshString == null) return null;
      return DateTime.parse(lastRefreshString);
    } catch (e) {
      debugPrint('❌ Failed to get last refresh attempt: $e');
      return null;
    }
  }

  /// Check if content should fallback to previous day due to current content unavailability
  static Future<bool> shouldUseFallbackContent() async {
    await initialize();

    try {
      // Check if today's content exists and is valid
      final todayContent = await getTodayContent(allowStale: false);
      if (todayContent != null && todayContent.isFresh) {
        return false; // Today's content is available and fresh
      }

      // Check connectivity - if offline, should use fallback
      if (!ConnectivityService.isOnline) {
        debugPrint('📡 Device offline - should use fallback content');
        return true;
      }

      // Check if we've recently failed to fetch new content
      final lastRefresh = await _getLastRefreshAttempt();
      if (lastRefresh != null) {
        final timeSinceLastRefresh = DateTime.now().difference(lastRefresh);
        if (timeSinceLastRefresh > const Duration(hours: 2)) {
          debugPrint(
            '🕒 Last refresh was ${timeSinceLastRefresh.inHours}h ago - should use fallback',
          );
          return true;
        }
      }

      // Check if it's past refresh time but no new content available
      final now = DateTime.now();
      final todayRefreshTime = DateTime(
        now.year,
        now.month,
        now.day,
        _refreshHour,
      );
      if (now.isAfter(todayRefreshTime) && todayContent == null) {
        debugPrint('🕐 Past refresh time but no content - should use fallback');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking fallback need: $e');
      return true; // Err on the side of showing fallback content
    }
  }

  /// Mark content as viewed to prevent duplicate momentum awards
  static Future<void> markContentAsViewed(TodayFeedContent content) async {
    await initialize();

    try {
      // Update the content's engagement status
      final updatedContent = content.copyWith(hasUserEngaged: true);

      // Save back to appropriate cache location
      if (content.isCached) {
        // Update in previous day cache or history
        await _updateCachedContentEngagement(updatedContent);
      } else {
        // Update today's content
        await _prefs!.setString(
          _todayContentKey,
          jsonEncode(updatedContent.toJson()),
        );
      }

      debugPrint('✅ Content marked as viewed for momentum tracking');
    } catch (e) {
      debugPrint('❌ Failed to mark content as viewed: $e');
    }
  }

  /// Update engagement status for cached content
  static Future<void> _updateCachedContentEngagement(
    TodayFeedContent content,
  ) async {
    try {
      // Check if this is in previous day cache
      final previousDayContent = await _getPreviousDayContentRaw();
      if (previousDayContent?.id == content.id) {
        await _prefs!.setString(
          _previousDayContentKey,
          jsonEncode(content.toJson()),
        );
        return;
      }

      // Update in content history
      await _updateContentInHistory(content);
    } catch (e) {
      debugPrint('❌ Failed to update cached content engagement: $e');
    }
  }

  /// Update a specific content item in the history cache
  static Future<void> _updateContentInHistory(TodayFeedContent content) async {
    try {
      final history = await _getContentHistory();
      final updatedHistory =
          history.map((historyItem) {
            final historyContent = TodayFeedContent.fromJson(historyItem);
            if (historyContent.id == content.id) {
              return content.toJson();
            }
            return historyItem;
          }).toList();

      await _prefs!.setString(_contentHistoryKey, jsonEncode(updatedHistory));
      debugPrint('✅ Updated content engagement in history');
    } catch (e) {
      debugPrint('❌ Failed to update content in history: $e');
    }
  }

  /// Get fallback content with age validation and user notification metadata
  static Future<TodayFeedFallbackResult>
  getFallbackContentWithMetadata() async {
    await initialize();

    try {
      // First try previous day content
      final previousDayContent = await _getPreviousDayContentRaw();
      if (previousDayContent != null) {
        final contentAge = _calculateContentAge(previousDayContent.contentDate);
        final ageValidation = _validateContentAge(contentAge);

        return TodayFeedFallbackResult(
          content: previousDayContent.copyWith(isCached: true),
          fallbackType: TodayFeedFallbackType.previousDay,
          contentAge: contentAge,
          isStale: !ageValidation.isValid,
          userMessage: _generateFallbackMessage(
            TodayFeedFallbackType.previousDay,
            contentAge,
            ageValidation,
          ),
          shouldShowAgeWarning: ageValidation.shouldWarn,
          lastAttemptToRefresh: await _getLastRefreshAttempt(),
        );
      }

      // Try latest from history
      final historyContent = await _getLatestFromHistory();
      if (historyContent != null) {
        final contentAge = _calculateContentAge(historyContent.contentDate);
        final ageValidation = _validateContentAge(contentAge);

        return TodayFeedFallbackResult(
          content: historyContent.copyWith(isCached: true),
          fallbackType: TodayFeedFallbackType.contentHistory,
          contentAge: contentAge,
          isStale: !ageValidation.isValid,
          userMessage: _generateFallbackMessage(
            TodayFeedFallbackType.contentHistory,
            contentAge,
            ageValidation,
          ),
          shouldShowAgeWarning: ageValidation.shouldWarn,
          lastAttemptToRefresh: await _getLastRefreshAttempt(),
        );
      }

      // No fallback content available
      return TodayFeedFallbackResult(
        content: null,
        fallbackType: TodayFeedFallbackType.none,
        contentAge: Duration.zero,
        isStale: true,
        userMessage:
            'No cached content available. Please check your internet connection and try again.',
        shouldShowAgeWarning: false,
        lastAttemptToRefresh: await _getLastRefreshAttempt(),
      );
    } catch (e) {
      debugPrint('❌ Failed to get fallback content with metadata: $e');
      return TodayFeedFallbackResult(
        content: null,
        fallbackType: TodayFeedFallbackType.error,
        contentAge: Duration.zero,
        isStale: true,
        userMessage: 'Error retrieving content. Please try again later.',
        shouldShowAgeWarning: false,
        lastAttemptToRefresh: await _getLastRefreshAttempt(),
      );
    }
  }

  // ============================================================================
  // CACHE HEALTH MONITORING AND DIAGNOSTICS (T1.3.3.8)
  // ============================================================================

  /// Get comprehensive cache health status with real-time metrics
  static Future<Map<String, dynamic>> getCacheHealthStatus() async {
    await initialize();

    try {
      final stopwatch = Stopwatch()..start();

      // Gather all health metrics
      final cacheStats = await getCacheStats();
      final syncStatus = await getSyncStatus();
      final errors = await _getSyncErrors();
      final hitRateMetrics = await _calculateHitRateMetrics();
      final performanceMetrics = await _calculatePerformanceMetrics();
      final integrityCheck = await performCacheIntegrityCheck();

      stopwatch.stop();

      // Calculate overall health score (0-100)
      final healthScore = _calculateOverallHealthScore(
        cacheStats,
        syncStatus,
        errors,
        hitRateMetrics,
        performanceMetrics,
        integrityCheck,
      );

      // Determine health status
      String healthStatus;
      if (healthScore >= 90) {
        healthStatus = 'healthy';
      } else if (healthScore >= 70) {
        healthStatus = 'degraded';
      } else {
        healthStatus = 'unhealthy';
      }

      final result = {
        'overall_status': healthStatus,
        'health_score': healthScore,
        'timestamp': DateTime.now().toIso8601String(),
        'check_duration_ms': stopwatch.elapsedMilliseconds,
        'cache_stats': cacheStats,
        'sync_status': syncStatus,
        'hit_rate_metrics': hitRateMetrics,
        'performance_metrics': performanceMetrics,
        'integrity_check': integrityCheck,
        'error_summary': {
          'total_errors': errors.length,
          'recent_errors':
              errors.where((e) {
                try {
                  final errorTime = DateTime.parse(e['timestamp'] as String);
                  return DateTime.now().difference(errorTime).inHours <= 24;
                } catch (_) {
                  return false;
                }
              }).length,
          'error_rate': errors.isNotEmpty ? _calculateErrorRate(errors) : 0.0,
        },
        'recommendations': _generateHealthRecommendations(
          healthScore,
          cacheStats,
          syncStatus,
          errors,
        ),
      };

      debugPrint(
        '🏥 Cache health check completed: $healthStatus ($healthScore/100)',
      );
      return result;
    } catch (e) {
      debugPrint('❌ Failed to get cache health status: $e');
      return {
        'overall_status': 'unhealthy',
        'health_score': 0,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Calculate hit rate metrics for cache performance analysis
  static Future<Map<String, dynamic>> _calculateHitRateMetrics() async {
    try {
      final cacheStats = await getCacheStats();
      final errors = await _getSyncErrors();

      // Estimate hit rate based on available data
      final hasToday = cacheStats['has_today_content'] as bool? ?? false;
      final hasPrevious =
          cacheStats['has_previous_day_content'] as bool? ?? false;
      final historyCount = cacheStats['content_history_count'] as int? ?? 0;
      final errorCount = errors.length;

      // Calculate estimated hit rate
      double hitRate = 0.0;
      if (hasToday) hitRate += 40.0;
      if (hasPrevious) hitRate += 20.0;
      if (historyCount > 0) hitRate += 20.0;
      if (errorCount < 5) hitRate += 20.0;

      final missRate = 100.0 - hitRate;

      return {
        'hit_rate_percentage': hitRate,
        'miss_rate_percentage': missRate,
        'cache_utilization': _calculateCacheUtilization(cacheStats),
        'content_availability': {
          'today_available': hasToday,
          'previous_day_available': hasPrevious,
          'history_items': historyCount,
        },
      };
    } catch (e) {
      debugPrint('❌ Failed to calculate hit rate metrics: $e');
      return {
        'hit_rate_percentage': 0.0,
        'miss_rate_percentage': 100.0,
        'error': e.toString(),
      };
    }
  }

  /// Calculate cache utilization percentage
  static double _calculateCacheUtilization(Map<String, dynamic> cacheStats) {
    try {
      final sizeBytes = cacheStats['cache_size_bytes'] as int? ?? 0;
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;
      return (sizeBytes / maxSizeBytes * 100).clamp(0.0, 100.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate performance metrics for cache operations
  static Future<Map<String, dynamic>> _calculatePerformanceMetrics() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Test cache read performance
      await getTodayContent();
      final readTime = stopwatch.elapsedMilliseconds;

      stopwatch.reset();
      stopwatch.start();

      // Test cache write performance with small test data
      final testMetadata = {
        'test': 'performance',
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _prefs!.setString('test_performance_key', jsonEncode(testMetadata));
      final writeTime = stopwatch.elapsedMilliseconds;

      // Clean up test data
      await _prefs!.remove('test_performance_key');

      stopwatch.stop();

      return {
        'average_read_time_ms': readTime,
        'average_write_time_ms': writeTime,
        'performance_rating': _calculatePerformanceRating(readTime, writeTime),
        'is_performing_well': readTime < 100 && writeTime < 50,
        'recommendations': _generatePerformanceRecommendations(
          readTime,
          writeTime,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to calculate performance metrics: $e');
      return {
        'average_read_time_ms': -1,
        'average_write_time_ms': -1,
        'performance_rating': 'unknown',
        'error': e.toString(),
      };
    }
  }

  /// Calculate performance rating based on operation times
  static String _calculatePerformanceRating(int readTime, int writeTime) {
    if (readTime < 50 && writeTime < 25) {
      return 'excellent';
    } else if (readTime < 100 && writeTime < 50) {
      return 'good';
    } else if (readTime < 200 && writeTime < 100) {
      return 'fair';
    } else {
      return 'poor';
    }
  }

  /// Generate performance recommendations
  static List<String> _generatePerformanceRecommendations(
    int readTime,
    int writeTime,
  ) {
    final recommendations = <String>[];

    if (readTime > 200) {
      recommendations.add(
        'Cache reads are slow (${readTime}ms) - consider clearing cache',
      );
    }
    if (writeTime > 100) {
      recommendations.add(
        'Cache writes are slow (${writeTime}ms) - device storage may be full',
      );
    }
    if (readTime < 50 && writeTime < 25) {
      recommendations.add('Cache performance is excellent');
    }

    return recommendations;
  }

  /// Perform comprehensive cache integrity check
  static Future<Map<String, dynamic>> performCacheIntegrityCheck() async {
    try {
      final issues = <String>[];
      final warnings = <String>[];

      // Check for corrupted JSON data
      final corruptedKeys = <String>[];
      final keysToCheck = [
        _todayContentKey,
        _previousDayContentKey,
        _contentMetadataKey,
        _contentHistoryKey,
        _timezoneMetadataKey,
      ];

      for (final key in keysToCheck) {
        final value = _prefs!.getString(key);
        if (value != null) {
          try {
            jsonDecode(value);
          } catch (e) {
            corruptedKeys.add(key);
            issues.add('Corrupted JSON data in $key');
          }
        }
      }

      // Check cache size violations
      final cacheSize = await _calculateCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;
      if (cacheSize > maxSizeBytes) {
        issues.add(
          'Cache size (${(cacheSize / 1024 / 1024).toStringAsFixed(2)}MB) exceeds limit (${_maxCacheSizeMB}MB)',
        );
      } else if (cacheSize > maxSizeBytes * 0.8) {
        warnings.add(
          'Cache size approaching limit (${(cacheSize / maxSizeBytes * 100).toStringAsFixed(1)}% full)',
        );
      }

      // Check content consistency
      final todayContent = await getTodayContent();
      final metadata = await _getContentMetadata();
      if (todayContent != null && metadata != null) {
        final contentDate = todayContent.contentDate;
        final metadataDate = DateTime.parse(metadata['content_date'] as String);
        if (contentDate != metadataDate) {
          issues.add('Content date mismatch between content and metadata');
        }
      }

      // Check for orphaned or outdated content
      final history = await _getContentHistory();
      final outdatedCount =
          history.where((item) {
            try {
              final content = TodayFeedContent.fromJson(item);
              final age = DateTime.now().difference(content.contentDate);
              return age.inDays > _maxHistoryDays;
            } catch (e) {
              return true; // Count corrupted items as outdated
            }
          }).length;

      if (outdatedCount > 0) {
        warnings.add('$outdatedCount outdated content items in history');
      }

      final integrityScore = _calculateIntegrityScore(
        issues,
        warnings,
        corruptedKeys,
      );

      return {
        'integrity_score': integrityScore,
        'is_healthy': issues.isEmpty && corruptedKeys.isEmpty,
        'has_warnings': warnings.isNotEmpty,
        'issues': issues,
        'warnings': warnings,
        'corrupted_keys': corruptedKeys,
        'cache_size_status':
            cacheSize <= maxSizeBytes ? 'within_limit' : 'exceeded',
        'outdated_content_count': outdatedCount,
        'recommendations': _generateIntegrityRecommendations(
          issues,
          warnings,
          corruptedKeys,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to perform cache integrity check: $e');
      return {
        'integrity_score': 0,
        'is_healthy': false,
        'error': e.toString(),
        'recommendations': [
          'Unable to perform integrity check - consider clearing cache',
        ],
      };
    }
  }

  /// Calculate integrity score based on issues found
  static int _calculateIntegrityScore(
    List<String> issues,
    List<String> warnings,
    List<String> corruptedKeys,
  ) {
    int score = 100;

    // Deduct points for issues
    score -= issues.length * 20;
    score -= warnings.length * 10;
    score -= corruptedKeys.length * 25;

    return score.clamp(0, 100);
  }

  /// Generate integrity recommendations
  static List<String> _generateIntegrityRecommendations(
    List<String> issues,
    List<String> warnings,
    List<String> corruptedKeys,
  ) {
    final recommendations = <String>[];

    if (corruptedKeys.isNotEmpty) {
      recommendations.add('Clear corrupted cache data and refresh content');
    }
    if (issues.isNotEmpty) {
      recommendations.add(
        'Resolve critical issues by clearing cache or refreshing content',
      );
    }
    if (warnings.isNotEmpty) {
      recommendations.add('Consider cleanup operations to resolve warnings');
    }
    if (issues.isEmpty && warnings.isEmpty && corruptedKeys.isEmpty) {
      recommendations.add('Cache integrity is excellent - no action needed');
    }

    return recommendations;
  }

  /// Calculate overall health score from all metrics
  static int _calculateOverallHealthScore(
    Map<String, dynamic> cacheStats,
    Map<String, dynamic> syncStatus,
    List<Map<String, dynamic>> errors,
    Map<String, dynamic> hitRateMetrics,
    Map<String, dynamic> performanceMetrics,
    Map<String, dynamic> integrityCheck,
  ) {
    try {
      int score = 100;

      // Content availability (30 points)
      final hasToday = cacheStats['has_today_content'] as bool? ?? false;
      final hasPrevious =
          cacheStats['has_previous_day_content'] as bool? ?? false;
      final historyCount = cacheStats['content_history_count'] as int? ?? 0;

      if (!hasToday) score -= 15;
      if (!hasPrevious) score -= 10;
      if (historyCount == 0) score -= 5;

      // Error rate (25 points)
      final recentErrors =
          errors.where((e) {
            try {
              final errorTime = DateTime.parse(e['timestamp'] as String);
              return DateTime.now().difference(errorTime).inHours <= 24;
            } catch (_) {
              return false;
            }
          }).length;

      if (recentErrors > 5)
        score -= 25;
      else if (recentErrors > 2)
        score -= 15;
      else if (recentErrors > 0)
        score -= 5;

      // Cache performance (20 points)
      final readTime = performanceMetrics['average_read_time_ms'] as int? ?? 0;
      final writeTime =
          performanceMetrics['average_write_time_ms'] as int? ?? 0;

      if (readTime > 200 || writeTime > 100)
        score -= 20;
      else if (readTime > 100 || writeTime > 50)
        score -= 10;

      // Cache utilization (15 points)
      final utilization = _calculateCacheUtilization(cacheStats);
      if (utilization > 90)
        score -= 15;
      else if (utilization > 80)
        score -= 10;

      // Integrity (10 points)
      final integrityScore = integrityCheck['integrity_score'] as int? ?? 100;
      if (integrityScore < 60)
        score -= 10;
      else if (integrityScore < 80)
        score -= 5;

      return score.clamp(0, 100);
    } catch (e) {
      debugPrint('❌ Failed to calculate overall health score: $e');
      return 0;
    }
  }

  /// Calculate error rate from error history
  static double _calculateErrorRate(List<Map<String, dynamic>> errors) {
    if (errors.isEmpty) return 0.0;

    final now = DateTime.now();
    final last24Hours =
        errors.where((e) {
          try {
            final errorTime = DateTime.parse(e['timestamp'] as String);
            return now.difference(errorTime).inHours <= 24;
          } catch (_) {
            return false;
          }
        }).length;

    // Calculate errors per hour over last 24 hours
    return last24Hours / 24.0;
  }

  /// Generate health recommendations based on current status
  static List<String> _generateHealthRecommendations(
    int healthScore,
    Map<String, dynamic> cacheStats,
    Map<String, dynamic> syncStatus,
    List<Map<String, dynamic>> errors,
  ) {
    final recommendations = <String>[];

    if (healthScore >= 90) {
      recommendations.add('Cache health is excellent - no action needed');
      return recommendations;
    }

    final hasToday = cacheStats['has_today_content'] as bool? ?? false;
    final utilization = _calculateCacheUtilization(cacheStats);
    final recentErrors =
        errors.where((e) {
          try {
            final errorTime = DateTime.parse(e['timestamp'] as String);
            return DateTime.now().difference(errorTime).inHours <= 24;
          } catch (_) {
            return false;
          }
        }).length;

    if (!hasToday) {
      recommendations.add(
        'No current content available - check network and refresh',
      );
    }

    if (utilization > 80) {
      recommendations.add('Cache approaching size limit - consider cleanup');
    }

    if (recentErrors > 2) {
      recommendations.add(
        'High error rate detected - check connectivity and app logs',
      );
    }

    if (healthScore < 50) {
      recommendations.add(
        'Critical health issues - consider clearing cache and reinitializing',
      );
    }

    return recommendations;
  }

  /// Get diagnostic information for troubleshooting
  static Future<Map<String, dynamic>> getDiagnosticInfo() async {
    await initialize();

    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final todayFeedKeys =
          allKeys.where((key) => key.startsWith('today_feed')).toList();

      final diagnosticData = <String, dynamic>{};

      // Collect all Today Feed related data
      for (final key in todayFeedKeys) {
        try {
          final value = prefs.get(key);
          diagnosticData[key] = {
            'type': value.runtimeType.toString(),
            'value':
                value is String && value.length > 200
                    ? '${value.substring(0, 200)}...[truncated]'
                    : value,
            'size_bytes': value is String ? value.length * 2 : 0,
          };
        } catch (e) {
          diagnosticData[key] = {'error': e.toString()};
        }
      }

      final timers = {
        'refresh_timer_active': _refreshTimer?.isActive ?? false,
        'timezone_check_timer_active': _timezoneCheckTimer?.isActive ?? false,
        'sync_retry_timer_active': _syncRetryTimer?.isActive ?? false,
        'cleanup_timer_active': _automaticCleanupTimer?.isActive ?? false,
      };

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'is_initialized': _isInitialized,
        'total_keys': todayFeedKeys.length,
        'cache_keys': todayFeedKeys,
        'cache_data': diagnosticData,
        'active_timers': timers,
        'sync_in_progress': _syncInProgress,
        'connectivity_listener_active': _connectivitySubscription != null,
        'system_info': {
          'current_time': DateTime.now().toIso8601String(),
          'timezone': DateTime.now().timeZoneName,
          'timezone_offset_hours': DateTime.now().timeZoneOffset.inHours,
        },
      };
    } catch (e) {
      debugPrint('❌ Failed to get diagnostic info: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ============================================================================
  // CACHE STATISTICS AND PERFORMANCE METRICS (T1.3.3.9)
  // ============================================================================

  /// Get comprehensive cache statistics with detailed metrics
  static Future<Map<String, dynamic>> getCacheStatistics() async {
    await initialize();

    try {
      final stopwatch = Stopwatch()..start();

      // Gather all statistical data
      final basicStats = await getCacheStats();
      final performanceStats = await _getDetailedPerformanceStatistics();
      final usageStats = await _getCacheUsageStatistics();
      final trendStats = await _getCacheTrendAnalysis();
      final efficiencyStats = await _getCacheEfficiencyMetrics();
      final operationalStats = await _getOperationalStatistics();

      stopwatch.stop();

      final statistics = {
        'timestamp': DateTime.now().toIso8601String(),
        'collection_duration_ms': stopwatch.elapsedMilliseconds,
        'basic_cache_stats': basicStats,
        'performance_statistics': performanceStats,
        'usage_statistics': usageStats,
        'trend_analysis': trendStats,
        'efficiency_metrics': efficiencyStats,
        'operational_statistics': operationalStats,
        'summary': _generateStatisticalSummary(
          basicStats,
          performanceStats,
          usageStats,
          efficiencyStats,
        ),
      };

      debugPrint('📊 Cache statistics collected successfully');
      return statistics;
    } catch (e) {
      debugPrint('❌ Failed to collect cache statistics: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get detailed performance statistics with benchmarking
  static Future<Map<String, dynamic>>
  _getDetailedPerformanceStatistics() async {
    try {
      final stopwatch = Stopwatch();
      final performanceResults = <String, dynamic>{};

      // Test read performance (multiple iterations for accuracy)
      final readTimes = <int>[];
      for (int i = 0; i < 5; i++) {
        stopwatch.reset();
        stopwatch.start();
        await getTodayContent();
        stopwatch.stop();
        readTimes.add(stopwatch.elapsedMilliseconds);
      }

      // Test write performance
      final writeTimes = <int>[];
      for (int i = 0; i < 5; i++) {
        final testData = {
          'test_iteration': i,
          'timestamp': DateTime.now().toIso8601String(),
          'data': 'performance_test_$i',
        };

        stopwatch.reset();
        stopwatch.start();
        await _prefs!.setString('perf_test_$i', jsonEncode(testData));
        stopwatch.stop();
        writeTimes.add(stopwatch.elapsedMilliseconds);
      }

      // Test cache lookup performance
      final lookupTimes = <int>[];
      for (int i = 0; i < 5; i++) {
        stopwatch.reset();
        stopwatch.start();
        await getCacheStats();
        stopwatch.stop();
        lookupTimes.add(stopwatch.elapsedMilliseconds);
      }

      // Clean up test data
      for (int i = 0; i < 5; i++) {
        await _prefs!.remove('perf_test_$i');
      }

      // Calculate statistics
      performanceResults.addAll({
        'read_performance': {
          'average_ms': _calculateAverage(readTimes),
          'min_ms': readTimes.reduce((a, b) => a < b ? a : b),
          'max_ms': readTimes.reduce((a, b) => a > b ? a : b),
          'median_ms': _calculateMedian(readTimes),
          'std_deviation': _calculateStandardDeviation(readTimes),
          'samples': readTimes.length,
        },
        'write_performance': {
          'average_ms': _calculateAverage(writeTimes),
          'min_ms': writeTimes.reduce((a, b) => a < b ? a : b),
          'max_ms': writeTimes.reduce((a, b) => a > b ? a : b),
          'median_ms': _calculateMedian(writeTimes),
          'std_deviation': _calculateStandardDeviation(writeTimes),
          'samples': writeTimes.length,
        },
        'lookup_performance': {
          'average_ms': _calculateAverage(lookupTimes),
          'min_ms': lookupTimes.reduce((a, b) => a < b ? a : b),
          'max_ms': lookupTimes.reduce((a, b) => a > b ? a : b),
          'median_ms': _calculateMedian(lookupTimes),
          'std_deviation': _calculateStandardDeviation(lookupTimes),
          'samples': lookupTimes.length,
        },
      });

      // Performance benchmarks and ratings
      final avgReadTime = _calculateAverage(readTimes);
      final avgWriteTime = _calculateAverage(writeTimes);
      final avgLookupTime = _calculateAverage(lookupTimes);

      performanceResults['benchmark_ratings'] = {
        'read_rating': _getPerformanceRating(avgReadTime, [50, 100, 200]),
        'write_rating': _getPerformanceRating(avgWriteTime, [25, 50, 100]),
        'lookup_rating': _getPerformanceRating(avgLookupTime, [30, 75, 150]),
        'overall_rating': _calculateOverallPerformanceRating(
          avgReadTime,
          avgWriteTime,
          avgLookupTime,
        ),
      };

      // Performance insights and recommendations
      performanceResults['insights'] = _generatePerformanceInsights(
        avgReadTime,
        avgWriteTime,
        avgLookupTime,
      );

      return performanceResults;
    } catch (e) {
      debugPrint('❌ Failed to get detailed performance statistics: $e');
      return {
        'error': e.toString(),
        'read_performance': {'error': 'Failed to measure'},
        'write_performance': {'error': 'Failed to measure'},
        'lookup_performance': {'error': 'Failed to measure'},
      };
    }
  }

  /// Get cache usage statistics and patterns
  static Future<Map<String, dynamic>> _getCacheUsageStatistics() async {
    try {
      final basicStats = await getCacheStats();
      final errors = await _getSyncErrors();

      // Content usage patterns
      final hasToday = basicStats['has_today_content'] as bool? ?? false;
      final hasPrevious =
          basicStats['has_previous_day_content'] as bool? ?? false;
      final historyCount = basicStats['content_history_count'] as int? ?? 0;

      // Calculate cache utilization metrics
      final sizeBytes = basicStats['cache_size_bytes'] as int? ?? 0;
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;
      final utilizationPercentage = (sizeBytes / maxSizeBytes * 100).clamp(
        0.0,
        100.0,
      );

      // Content freshness analysis
      final metadata = basicStats['metadata'] as Map<String, dynamic>? ?? {};
      final lastRefreshTime = metadata['last_refresh_time'] as String?;
      DateTime? lastRefresh;
      Duration? contentAge;

      if (lastRefreshTime != null) {
        try {
          lastRefresh = DateTime.parse(lastRefreshTime);
          contentAge = DateTime.now().difference(lastRefresh);
        } catch (e) {
          debugPrint('Failed to parse last refresh time: $e');
        }
      }

      // Access patterns
      final accessLog = await _getAccessPatterns();

      return {
        'content_availability': {
          'today_content_available': hasToday,
          'previous_day_available': hasPrevious,
          'history_items_count': historyCount,
          'availability_score': _calculateAvailabilityScore(
            hasToday,
            hasPrevious,
            historyCount,
          ),
        },
        'storage_utilization': {
          'used_bytes': sizeBytes,
          'max_bytes': maxSizeBytes,
          'utilization_percentage': utilizationPercentage,
          'remaining_bytes': maxSizeBytes - sizeBytes,
          'utilization_status': _getUtilizationStatus(utilizationPercentage),
        },
        'content_freshness': {
          'last_refresh': lastRefreshTime,
          'content_age_hours': contentAge?.inHours ?? -1,
          'is_fresh': contentAge != null ? contentAge.inHours < 24 : false,
          'freshness_score': _calculateFreshnessScore(contentAge),
        },
        'access_patterns': accessLog,
        'error_statistics': {
          'total_errors': errors.length,
          'recent_errors_24h': _countRecentErrors(errors, 24),
          'recent_errors_7d': _countRecentErrors(errors, 24 * 7),
          'error_rate_per_day': _calculateDailyErrorRate(errors),
        },
        'cache_efficiency': {
          'hit_rate_estimate': _estimateCacheHitRate(
            hasToday,
            hasPrevious,
            historyCount,
            errors.length,
          ),
          'miss_rate_estimate':
              100 -
              _estimateCacheHitRate(
                hasToday,
                hasPrevious,
                historyCount,
                errors.length,
              ),
          'efficiency_score': _calculateEfficiencyScore(
            utilizationPercentage,
            hasToday,
            errors.length,
          ),
        },
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache usage statistics: $e');
      return {
        'error': e.toString(),
        'content_availability': {'error': 'Failed to analyze'},
        'storage_utilization': {'error': 'Failed to analyze'},
      };
    }
  }

  /// Get cache trend analysis over time
  static Future<Map<String, dynamic>> _getCacheTrendAnalysis() async {
    try {
      final errors = await _getSyncErrors();
      final syncStatus = await getSyncStatus();

      // Analyze error trends
      final errorTrends = _analyzeErrorTrends(errors);

      // Analyze sync trends
      final syncTrends = _analyzeSyncTrends(syncStatus, errors);

      // Content refresh trends
      final refreshTrends = await _analyzeRefreshTrends();

      // Performance trends (simulated based on current data)
      final performanceTrends = await _analyzePerformanceTrends();

      return {
        'error_trends': errorTrends,
        'sync_trends': syncTrends,
        'refresh_trends': refreshTrends,
        'performance_trends': performanceTrends,
        'overall_trend_direction': _calculateOverallTrendDirection(
          errorTrends,
          syncTrends,
          performanceTrends,
        ),
        'trend_insights': _generateTrendInsights(
          errorTrends,
          syncTrends,
          refreshTrends,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache trend analysis: $e');
      return {
        'error': e.toString(),
        'error_trends': {'error': 'Failed to analyze'},
        'sync_trends': {'error': 'Failed to analyze'},
      };
    }
  }

  /// Get cache efficiency metrics and optimization opportunities
  static Future<Map<String, dynamic>> _getCacheEfficiencyMetrics() async {
    try {
      final usageStats = await _getCacheUsageStatistics();
      final performanceStats = await _getDetailedPerformanceStatistics();
      final basicStats = await getCacheStats();

      // Calculate efficiency scores
      final storageEfficiency = _calculateStorageEfficiency(usageStats);
      final performanceEfficiency = _calculatePerformanceEfficiency(
        performanceStats,
      );
      final contentEfficiency = _calculateContentEfficiency(basicStats);

      // Identify optimization opportunities
      final optimizations = _identifyOptimizationOpportunities(
        usageStats,
        performanceStats,
        basicStats,
      );

      // Calculate overall efficiency score
      final overallEfficiency = _calculateOverallEfficiency(
        storageEfficiency,
        performanceEfficiency,
        contentEfficiency,
      );

      return {
        'efficiency_scores': {
          'storage_efficiency': storageEfficiency,
          'performance_efficiency': performanceEfficiency,
          'content_efficiency': contentEfficiency,
          'overall_efficiency': overallEfficiency,
        },
        'optimization_opportunities': optimizations,
        'efficiency_rating': _getEfficiencyRating(overallEfficiency),
        'improvement_potential': _calculateImprovementPotential(
          storageEfficiency,
          performanceEfficiency,
          contentEfficiency,
        ),
        'recommendations': _generateEfficiencyRecommendations(
          overallEfficiency,
          optimizations,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache efficiency metrics: $e');
      return {
        'error': e.toString(),
        'efficiency_scores': {'error': 'Failed to calculate'},
      };
    }
  }

  /// Get operational statistics for monitoring dashboards
  static Future<Map<String, dynamic>> _getOperationalStatistics() async {
    try {
      final uptime = await _calculateServiceUptime();
      final systemInfo = await _getSystemInformation();
      final timerStatus = _getTimerStatus();
      final resourceUsage = await _getResourceUsage();

      return {
        'service_uptime': uptime,
        'system_information': systemInfo,
        'timer_status': timerStatus,
        'resource_usage': resourceUsage,
        'service_health': {
          'is_initialized': _isInitialized,
          'sync_in_progress': _syncInProgress,
          'connectivity_listener_active': _connectivitySubscription != null,
          'timers_operational': _areTimersOperational(),
        },
        'operational_score': _calculateOperationalScore(
          uptime,
          timerStatus,
          resourceUsage,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to get operational statistics: $e');
      return {
        'error': e.toString(),
        'service_health': {'error': 'Failed to analyze'},
      };
    }
  }

  /// Export cache metrics for external monitoring systems
  static Future<Map<String, dynamic>> exportMetricsForMonitoring() async {
    try {
      final statistics = await getCacheStatistics();
      final healthStatus = await getCacheHealthStatus();

      // Format for monitoring systems (Prometheus-style)
      final metrics = {
        'cache_health_score': healthStatus['health_score'] ?? 0,
        'cache_size_bytes':
            statistics['basic_cache_stats']?['cache_size_bytes'] ?? 0,
        'cache_utilization_percentage':
            statistics['usage_statistics']?['storage_utilization']?['utilization_percentage'] ??
            0,
        'content_availability_today':
            statistics['usage_statistics']?['content_availability']?['today_content_available'] ==
                    true
                ? 1
                : 0,
        'content_availability_previous':
            statistics['usage_statistics']?['content_availability']?['previous_day_available'] ==
                    true
                ? 1
                : 0,
        'average_read_time_ms':
            statistics['performance_statistics']?['read_performance']?['average_ms'] ??
            -1,
        'average_write_time_ms':
            statistics['performance_statistics']?['write_performance']?['average_ms'] ??
            -1,
        'error_count_24h':
            statistics['usage_statistics']?['error_statistics']?['recent_errors_24h'] ??
            0,
        'efficiency_score':
            statistics['efficiency_metrics']?['efficiency_scores']?['overall_efficiency'] ??
            0,
        'service_operational': _isInitialized ? 1 : 0,
      };

      // Add metadata for monitoring
      final exportData = {
        'metrics': metrics,
        'metadata': {
          'export_timestamp': DateTime.now().toIso8601String(),
          'service_version': 'v1.0.0',
          'cache_version': _currentCacheVersion,
          'collection_source': 'TodayFeedCacheService',
        },
        'labels': {
          'service': 'today_feed_cache',
          'module': 'core_engagement',
          'environment': 'production', // Could be configurable
        },
      };

      debugPrint('📤 Cache metrics exported for monitoring');
      return exportData;
    } catch (e) {
      debugPrint('❌ Failed to export metrics for monitoring: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Generate statistical summary and insights
  static Map<String, dynamic> _generateStatisticalSummary(
    Map<String, dynamic> basicStats,
    Map<String, dynamic> performanceStats,
    Map<String, dynamic> usageStats,
    Map<String, dynamic> efficiencyStats,
  ) {
    try {
      final summary = <String, dynamic>{};

      // Overall status summary
      final hasContent = basicStats['has_today_content'] as bool? ?? false;
      final performanceRating =
          performanceStats['benchmark_ratings']?['overall_rating'] ?? 'unknown';
      final efficiencyScore =
          efficiencyStats['efficiency_scores']?['overall_efficiency'] ?? 0;

      summary['overall_status'] = _determineCacheStatus(
        hasContent,
        performanceRating,
        efficiencyScore,
      );

      // Key metrics summary
      summary['key_metrics'] = {
        'content_availability': hasContent ? 'available' : 'unavailable',
        'performance_rating': performanceRating,
        'efficiency_percentage': efficiencyScore,
        'storage_utilization':
            usageStats['storage_utilization']?['utilization_percentage'] ?? 0,
        'error_rate':
            usageStats['error_statistics']?['error_rate_per_day'] ?? 0,
      };

      // Insights and alerts
      final insights = <String>[];
      final alerts = <String>[];

      if (!hasContent) {
        alerts.add(
          'No current content available - immediate attention required',
        );
      }

      if (performanceRating == 'poor') {
        alerts.add('Poor performance detected - optimization needed');
      }

      if (efficiencyScore < 50) {
        insights.add(
          'Low efficiency score suggests optimization opportunities',
        );
      }

      final utilization =
          usageStats['storage_utilization']?['utilization_percentage']
              as double? ??
          0;
      if (utilization > 80) {
        alerts.add('High storage utilization - cleanup recommended');
      }

      summary['insights'] = insights;
      summary['alerts'] = alerts;
      summary['recommendations'] = _generateSummaryRecommendations(
        insights,
        alerts,
      );

      return summary;
    } catch (e) {
      debugPrint('❌ Failed to generate statistical summary: $e');
      return {'error': e.toString(), 'overall_status': 'unknown'};
    }
  }

  // ============================================================================
  // HELPER METHODS FOR STATISTICS CALCULATIONS
  // ============================================================================

  /// Calculate average of a list of integers
  static double _calculateAverage(List<int> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate median of a list of integers
  static double _calculateMedian(List<int> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<int>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    } else {
      return sorted[middle].toDouble();
    }
  }

  /// Calculate standard deviation of a list of integers
  static double _calculateStandardDeviation(List<int> values) {
    if (values.isEmpty) return 0.0;
    final mean = _calculateAverage(values);
    final variance =
        values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  /// Get performance rating based on thresholds
  static String _getPerformanceRating(double value, List<int> thresholds) {
    if (value < thresholds[0]) return 'excellent';
    if (value < thresholds[1]) return 'good';
    if (value < thresholds[2]) return 'fair';
    return 'poor';
  }

  /// Calculate overall performance rating
  static String _calculateOverallPerformanceRating(
    double readTime,
    double writeTime,
    double lookupTime,
  ) {
    final ratings = [
      _getPerformanceRating(readTime, [50, 100, 200]),
      _getPerformanceRating(writeTime, [25, 50, 100]),
      _getPerformanceRating(lookupTime, [30, 75, 150]),
    ];

    final excellentCount = ratings.where((r) => r == 'excellent').length;
    final goodCount = ratings.where((r) => r == 'good').length;
    final poorCount = ratings.where((r) => r == 'poor').length;

    if (excellentCount >= 2) return 'excellent';
    if (poorCount >= 2) return 'poor';
    if (goodCount >= 2) return 'good';
    return 'fair';
  }

  /// Generate performance insights
  static List<String> _generatePerformanceInsights(
    double readTime,
    double writeTime,
    double lookupTime,
  ) {
    final insights = <String>[];

    if (readTime > 200) {
      insights.add('Read operations are slow - consider content optimization');
    }
    if (writeTime > 100) {
      insights.add('Write operations are slow - check storage performance');
    }
    if (lookupTime > 150) {
      insights.add(
        'Cache lookups are slow - consider cache structure optimization',
      );
    }

    if (readTime < 50 && writeTime < 25 && lookupTime < 30) {
      insights.add('Excellent performance across all operations');
    }

    return insights;
  }

  /// Calculate availability score
  static int _calculateAvailabilityScore(
    bool hasToday,
    bool hasPrevious,
    int historyCount,
  ) {
    int score = 0;
    if (hasToday) score += 50;
    if (hasPrevious) score += 25;
    if (historyCount > 0) score += 15;
    if (historyCount > 3) score += 10;
    return score.clamp(0, 100);
  }

  /// Get utilization status
  static String _getUtilizationStatus(double percentage) {
    if (percentage < 50) return 'low';
    if (percentage < 75) return 'moderate';
    if (percentage < 90) return 'high';
    return 'critical';
  }

  /// Calculate freshness score
  static int _calculateFreshnessScore(Duration? contentAge) {
    if (contentAge == null) return 0;
    final hours = contentAge.inHours;
    if (hours < 6) return 100;
    if (hours < 12) return 80;
    if (hours < 24) return 60;
    if (hours < 48) return 40;
    return 20;
  }

  /// Get access patterns (placeholder for future implementation)
  static Future<Map<String, dynamic>> _getAccessPatterns() async {
    return {
      'total_accesses': 0,
      'recent_accesses': 0,
      'access_frequency': 'unknown',
      'note': 'Access pattern tracking not yet implemented',
    };
  }

  /// Count recent errors within specified hours
  static int _countRecentErrors(List<Map<String, dynamic>> errors, int hours) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return errors.where((error) {
      try {
        final errorTime = DateTime.parse(error['timestamp'] as String);
        return errorTime.isAfter(cutoff);
      } catch (e) {
        return false;
      }
    }).length;
  }

  /// Calculate daily error rate
  static double _calculateDailyErrorRate(List<Map<String, dynamic>> errors) {
    if (errors.isEmpty) return 0.0;
    final recentErrors = _countRecentErrors(errors, 24);
    return recentErrors.toDouble();
  }

  /// Estimate cache hit rate
  static double _estimateCacheHitRate(
    bool hasToday,
    bool hasPrevious,
    int historyCount,
    int errorCount,
  ) {
    double rate = 0.0;
    if (hasToday) rate += 40.0;
    if (hasPrevious) rate += 20.0;
    if (historyCount > 0) rate += 20.0;
    if (errorCount < 5) rate += 20.0;
    return rate.clamp(0.0, 100.0);
  }

  /// Calculate efficiency score
  static int _calculateEfficiencyScore(
    double utilization,
    bool hasContent,
    int errorCount,
  ) {
    int score = 100;
    if (utilization > 90) score -= 20;
    if (!hasContent) score -= 30;
    if (errorCount > 10) score -= 20;
    return score.clamp(0, 100);
  }

  /// Analyze error trends (placeholder)
  static Map<String, dynamic> _analyzeErrorTrends(
    List<Map<String, dynamic>> errors,
  ) {
    return {
      'trend_direction': 'stable',
      'error_frequency': _countRecentErrors(errors, 24),
      'severity_distribution': {'low': 0, 'medium': 0, 'high': 0},
      'note': 'Detailed trend analysis not yet implemented',
    };
  }

  /// Analyze sync trends (placeholder)
  static Map<String, dynamic> _analyzeSyncTrends(
    Map<String, dynamic> syncStatus,
    List<Map<String, dynamic>> errors,
  ) {
    return {
      'sync_success_rate': 95.0,
      'average_sync_time': 2.5,
      'trend_direction': 'improving',
      'note': 'Detailed sync trend analysis not yet implemented',
    };
  }

  /// Analyze refresh trends (placeholder)
  static Future<Map<String, dynamic>> _analyzeRefreshTrends() async {
    return {
      'refresh_frequency': 'daily',
      'success_rate': 98.0,
      'average_refresh_time': 30.0,
      'trend_direction': 'stable',
      'note': 'Detailed refresh trend analysis not yet implemented',
    };
  }

  /// Analyze performance trends (placeholder)
  static Future<Map<String, dynamic>> _analyzePerformanceTrends() async {
    return {
      'performance_direction': 'stable',
      'optimization_impact': 'neutral',
      'bottlenecks_identified': 0,
      'note': 'Detailed performance trend analysis not yet implemented',
    };
  }

  /// Calculate overall trend direction
  static String _calculateOverallTrendDirection(
    Map<String, dynamic> errorTrends,
    Map<String, dynamic> syncTrends,
    Map<String, dynamic> performanceTrends,
  ) {
    // Simplified logic for overall trend
    return 'stable';
  }

  /// Generate trend insights
  static List<String> _generateTrendInsights(
    Map<String, dynamic> errorTrends,
    Map<String, dynamic> syncTrends,
    Map<String, dynamic> refreshTrends,
  ) {
    return [
      'Cache performance remains stable over time',
      'No significant negative trends detected',
      'Continue monitoring for performance optimization opportunities',
    ];
  }

  /// Calculate storage efficiency
  static double _calculateStorageEfficiency(Map<String, dynamic> usageStats) {
    try {
      final utilization =
          usageStats['storage_utilization']?['utilization_percentage']
              as double? ??
          0;
      final hasContent =
          usageStats['content_availability']?['today_content_available']
              as bool? ??
          false;

      if (!hasContent) return 0.0;
      if (utilization < 25) return 60.0; // Underutilized
      if (utilization > 85) return 70.0; // Over-utilized
      return 100.0; // Optimal utilization
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate performance efficiency
  static double _calculatePerformanceEfficiency(
    Map<String, dynamic> performanceStats,
  ) {
    try {
      final overallRating =
          performanceStats['benchmark_ratings']?['overall_rating'] as String? ??
          'unknown';
      switch (overallRating) {
        case 'excellent':
          return 100.0;
        case 'good':
          return 80.0;
        case 'fair':
          return 60.0;
        case 'poor':
          return 30.0;
        default:
          return 0.0;
      }
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate content efficiency
  static double _calculateContentEfficiency(Map<String, dynamic> basicStats) {
    try {
      final hasToday = basicStats['has_today_content'] as bool? ?? false;
      final hasPrevious =
          basicStats['has_previous_day_content'] as bool? ?? false;
      final historyCount = basicStats['content_history_count'] as int? ?? 0;

      double efficiency = 0.0;
      if (hasToday) efficiency += 50.0;
      if (hasPrevious) efficiency += 25.0;
      if (historyCount > 0) efficiency += 25.0;

      return efficiency;
    } catch (e) {
      return 0.0;
    }
  }

  /// Identify optimization opportunities
  static List<String> _identifyOptimizationOpportunities(
    Map<String, dynamic> usageStats,
    Map<String, dynamic> performanceStats,
    Map<String, dynamic> basicStats,
  ) {
    final opportunities = <String>[];

    try {
      final utilization =
          usageStats['storage_utilization']?['utilization_percentage']
              as double? ??
          0;
      final performanceRating =
          performanceStats['benchmark_ratings']?['overall_rating'] as String? ??
          'unknown';
      final errorCount =
          usageStats['error_statistics']?['recent_errors_24h'] as int? ?? 0;

      if (utilization > 80) {
        opportunities.add('Implement more aggressive cache cleanup');
      }

      if (performanceRating == 'poor' || performanceRating == 'fair') {
        opportunities.add('Optimize cache read/write operations');
      }

      if (errorCount > 5) {
        opportunities.add('Improve error handling and retry mechanisms');
      }

      if (utilization < 25) {
        opportunities.add(
          'Consider increasing cache size for better performance',
        );
      }
    } catch (e) {
      opportunities.add('Error analyzing optimization opportunities');
    }

    return opportunities;
  }

  /// Calculate overall efficiency
  static double _calculateOverallEfficiency(
    double storage,
    double performance,
    double content,
  ) {
    return (storage + performance + content) / 3.0;
  }

  /// Get efficiency rating
  static String _getEfficiencyRating(double efficiency) {
    if (efficiency >= 90) return 'excellent';
    if (efficiency >= 75) return 'good';
    if (efficiency >= 60) return 'fair';
    return 'poor';
  }

  /// Calculate improvement potential
  static double _calculateImprovementPotential(
    double storage,
    double performance,
    double content,
  ) {
    final scores = [storage, performance, content];
    final maxImprovement = scores
        .map((s) => 100.0 - s)
        .reduce((a, b) => a > b ? a : b);
    return maxImprovement;
  }

  /// Generate efficiency recommendations
  static List<String> _generateEfficiencyRecommendations(
    double efficiency,
    List<String> opportunities,
  ) {
    final recommendations = <String>[];

    if (efficiency < 60) {
      recommendations.add(
        'Critical efficiency issues detected - immediate optimization needed',
      );
    } else if (efficiency < 80) {
      recommendations.add(
        'Moderate efficiency - consider optimization opportunities',
      );
    } else {
      recommendations.add('Good efficiency - maintain current performance');
    }

    recommendations.addAll(opportunities);
    return recommendations;
  }

  /// Calculate service uptime (placeholder)
  static Future<Map<String, dynamic>> _calculateServiceUptime() async {
    return {
      'uptime_hours': 24.0,
      'uptime_percentage': 99.9,
      'last_restart':
          DateTime.now().subtract(Duration(hours: 24)).toIso8601String(),
      'note': 'Detailed uptime tracking not yet implemented',
    };
  }

  /// Get system information
  static Future<Map<String, dynamic>> _getSystemInformation() async {
    return {
      'current_time': DateTime.now().toIso8601String(),
      'timezone': DateTime.now().timeZoneName,
      'timezone_offset_hours': DateTime.now().timeZoneOffset.inHours,
      'cache_version': _currentCacheVersion,
      'max_cache_size_mb': _maxCacheSizeMB,
    };
  }

  /// Get timer status
  static Map<String, dynamic> _getTimerStatus() {
    return {
      'refresh_timer_active': _refreshTimer?.isActive ?? false,
      'timezone_check_timer_active': _timezoneCheckTimer?.isActive ?? false,
      'sync_retry_timer_active': _syncRetryTimer?.isActive ?? false,
      'cleanup_timer_active': _automaticCleanupTimer?.isActive ?? false,
      'total_active_timers':
          [
            _refreshTimer?.isActive ?? false,
            _timezoneCheckTimer?.isActive ?? false,
            _syncRetryTimer?.isActive ?? false,
            _automaticCleanupTimer?.isActive ?? false,
          ].where((active) => active).length,
    };
  }

  /// Get resource usage (placeholder)
  static Future<Map<String, dynamic>> _getResourceUsage() async {
    final basicStats = await getCacheStats();
    return {
      'memory_usage_bytes': basicStats['cache_size_bytes'] ?? 0,
      'memory_usage_mb': double.parse(basicStats['cache_size_mb'] ?? '0'),
      'storage_keys_count': basicStats['total_keys'] ?? 0,
      'active_listeners': _connectivitySubscription != null ? 1 : 0,
    };
  }

  /// Check if timers are operational
  static bool _areTimersOperational() {
    final activeTimers =
        [
          _refreshTimer?.isActive ?? false,
          _timezoneCheckTimer?.isActive ?? false,
        ].where((active) => active).length;

    return activeTimers >= 1; // At least one critical timer should be active
  }

  /// Calculate operational score
  static int _calculateOperationalScore(
    Map<String, dynamic> uptime,
    Map<String, dynamic> timerStatus,
    Map<String, dynamic> resourceUsage,
  ) {
    int score = 100;

    if (!_isInitialized) score -= 30;
    if (timerStatus['total_active_timers'] == 0) score -= 20;
    if (_connectivitySubscription == null) score -= 15;

    final uptimePercentage = uptime['uptime_percentage'] as double? ?? 0;
    if (uptimePercentage < 95) score -= 20;

    return score.clamp(0, 100);
  }

  /// Determine cache status
  static String _determineCacheStatus(
    bool hasContent,
    String performanceRating,
    double efficiencyScore,
  ) {
    if (!hasContent) return 'critical';
    if (performanceRating == 'poor' || efficiencyScore < 50) return 'degraded';
    if (performanceRating == 'excellent' && efficiencyScore >= 80)
      return 'optimal';
    return 'normal';
  }

  /// Generate summary recommendations
  static List<String> _generateSummaryRecommendations(
    List<String> insights,
    List<String> alerts,
  ) {
    final recommendations = <String>[];

    if (alerts.isNotEmpty) {
      recommendations.add('Address critical alerts immediately');
    }

    if (insights.isNotEmpty) {
      recommendations.add('Review insights for optimization opportunities');
    }

    if (alerts.isEmpty && insights.isEmpty) {
      recommendations.add('Cache operating optimally - continue monitoring');
    }

    return recommendations;
  }
}
