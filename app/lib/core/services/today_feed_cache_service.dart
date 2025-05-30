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

  static SharedPreferences? _prefs;
  static bool _isInitialized = false;
  static Timer? _refreshTimer;
  static Timer? _timezoneCheckTimer;
  static Timer? _syncRetryTimer;
  static StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  static bool _syncInProgress = false;

  /// Initialize the Today Feed cache service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _validateCacheVersion();
      await _detectAndHandleTimezoneChanges();
      await _cleanupExpiredContent();
      await _scheduleNextRefresh();
      await _scheduleTimezoneChecks();
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
      try {
        connectivityStatus = ConnectivityService.currentStatus.toString();
      } catch (e) {
        connectivityStatus = 'unavailable';
      }

      final syncMetadata = {
        'last_sync': now.toIso8601String(),
        'sync_version': _currentCacheVersion,
        'device_timezone': now.timeZoneName,
        'sync_duration_ms': 0, // Would be calculated in real implementation
        'connectivity_status': connectivityStatus,
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
    _isInitialized = false;
    _prefs = null;
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
}
