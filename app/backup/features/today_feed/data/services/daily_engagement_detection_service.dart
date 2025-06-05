import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/today_feed_content.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/version_service.dart';

/// Service for detecting and managing daily engagement with Today Feed content
///
/// This service implements T1.3.4.2 requirements:
/// - Daily engagement detection with duplicate prevention
/// - Integration with momentum meter for +1 point awards
/// - Real-time engagement status tracking
/// - Offline support with sync capabilities
class DailyEngagementDetectionService {
  static final DailyEngagementDetectionService _instance =
      DailyEngagementDetectionService._internal();
  factory DailyEngagementDetectionService() => _instance;
  DailyEngagementDetectionService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  bool _isInitialized = false;

  // Cache for engagement status to reduce database queries
  final Map<String, DateTime> _dailyEngagementCache = {};
  Timer? _cacheCleanupTimer;

  // Configuration constants from PRD specifications
  static const Duration cacheExpiryDuration = Duration(hours: 2);
  static const Duration cacheCleanupInterval = Duration(hours: 1);
  static const String momentumEventType = 'today_feed_view';

  /// Initialize the service with Supabase client
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;

      // Initialize connectivity monitoring for cache management
      await ConnectivityService.initialize();

      // Set up periodic cache cleanup
      _setupCacheCleanup();

      _isInitialized = true;
      debugPrint('✅ DailyEngagementDetectionService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize DailyEngagementDetectionService: $e');
      rethrow;
    }
  }

  /// Check if user has already engaged with Today Feed content today
  ///
  /// Returns: EngagementStatus with details about daily engagement
  Future<EngagementStatus> checkDailyEngagementStatus(String userId) async {
    await initialize();

    try {
      // Check cache first for performance
      final cacheKey = '${userId}_${_getTodayDateString()}';
      if (_dailyEngagementCache.containsKey(cacheKey)) {
        final cachedTime = _dailyEngagementCache[cacheKey]!;
        if (DateTime.now().difference(cachedTime) < cacheExpiryDuration) {
          return EngagementStatus(
            hasEngagedToday: true,
            isEligibleForMomentum: false,
            lastEngagementTime: cachedTime,
            source: EngagementSource.cache,
          );
        }
      }

      final today = _getTodayDateString();

      // Check engagement events for today's momentum-eligible interactions
      final engagementEvents = await _supabase
          .from('engagement_events')
          .select('created_at, event_type')
          .eq('user_id', userId)
          .eq('event_type', momentumEventType)
          .gte('created_at', '${today}T00:00:00.000Z')
          .lt('created_at', '${today}T23:59:59.999Z')
          .order('created_at', ascending: false)
          .limit(1);

      final hasEngaged = engagementEvents.isNotEmpty;
      DateTime? lastEngagementTime;

      if (hasEngaged) {
        lastEngagementTime = DateTime.parse(
          engagementEvents.first['created_at'],
        );
        // Update cache
        _dailyEngagementCache[cacheKey] = lastEngagementTime;
      }

      return EngagementStatus(
        hasEngagedToday: hasEngaged,
        isEligibleForMomentum: !hasEngaged,
        lastEngagementTime: lastEngagementTime,
        source: EngagementSource.database,
      );
    } catch (e) {
      debugPrint('❌ Failed to check daily engagement status: $e');

      // Return conservative status on error to prevent duplicate momentum
      return EngagementStatus(
        hasEngagedToday: true, // Conservative - assume already engaged
        isEligibleForMomentum: false,
        lastEngagementTime: null,
        source: EngagementSource.error,
        error: e.toString(),
      );
    }
  }

  /// Record daily engagement and determine momentum eligibility
  ///
  /// This is the primary method for T1.3.4.2 - it prevents duplicate momentum awards
  /// Returns: EngagementResult with momentum award status
  Future<EngagementResult> recordDailyEngagement(
    String userId,
    TodayFeedContent content, {
    int? sessionDuration,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    await initialize();

    try {
      // First check current engagement status
      final currentStatus = await checkDailyEngagementStatus(userId);

      if (!currentStatus.isEligibleForMomentum) {
        debugPrint('ℹ️ User already engaged today - no momentum award');
        return EngagementResult(
          success: true,
          momentumAwarded: false,
          momentumPoints: 0,
          isDuplicate: true,
          engagementRecorded: true,
          message: 'Content engagement recorded (already engaged today)',
          previousEngagementTime: currentStatus.lastEngagementTime,
        );
      }

      // Record engagement event for momentum system
      final engagementEventData = _buildEngagementEventData(
        userId: userId,
        content: content,
        sessionDuration: sessionDuration,
        additionalMetadata: additionalMetadata,
      );

      await _recordEngagementEvent(engagementEventData);

      // Update cache to prevent duplicate checks
      final cacheKey = '${userId}_${_getTodayDateString()}';
      _dailyEngagementCache[cacheKey] = DateTime.now();

      debugPrint('✅ Daily engagement recorded with momentum award');

      return EngagementResult(
        success: true,
        momentumAwarded: true,
        momentumPoints: 1,
        isDuplicate: false,
        engagementRecorded: true,
        message: 'First daily engagement! +1 momentum point earned',
        engagementTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Failed to record daily engagement: $e');
      return EngagementResult(
        success: false,
        momentumAwarded: false,
        momentumPoints: 0,
        isDuplicate: false,
        engagementRecorded: false,
        message: 'Failed to record engagement',
        error: e.toString(),
      );
    }
  }

  /// Get engagement statistics for analytics and debugging
  Future<EngagementStatistics> getEngagementStatistics(
    String userId, {
    int daysToAnalyze = 30,
  }) async {
    await initialize();

    try {
      final startDate = DateTime.now().subtract(Duration(days: daysToAnalyze));
      final startDateString = startDate.toIso8601String().split('T')[0];

      // Get engagement events for the specified period
      final engagementEvents = await _supabase
          .from('engagement_events')
          .select('created_at, event_type, value')
          .eq('user_id', userId)
          .eq('event_type', momentumEventType)
          .gte('created_at', '${startDateString}T00:00:00.000Z')
          .order('created_at', ascending: false);

      // Calculate statistics
      final totalEngagements = engagementEvents.length;
      final uniqueDays = <String>{};
      int totalSessionDuration = 0;
      DateTime? lastEngagement;
      DateTime? firstEngagement;

      for (final event in engagementEvents) {
        final eventDate = DateTime.parse(event['created_at']);
        final dayString = eventDate.toIso8601String().split('T')[0];
        uniqueDays.add(dayString);

        if (lastEngagement == null || eventDate.isAfter(lastEngagement)) {
          lastEngagement = eventDate;
        }
        if (firstEngagement == null || eventDate.isBefore(firstEngagement)) {
          firstEngagement = eventDate;
        }

        // Extract session duration from metadata
        final eventValue = event['value'] as Map<String, dynamic>?;
        if (eventValue != null && eventValue['session_duration'] != null) {
          totalSessionDuration +=
              (eventValue['session_duration'] as num).toInt();
        }
      }

      final engagedDays = uniqueDays.length;
      final averageSessionDuration =
          totalEngagements > 0
              ? (totalSessionDuration / totalEngagements).round()
              : 0;

      // Calculate streak
      final currentStreak = await _calculateCurrentStreak(userId);

      return EngagementStatistics(
        totalEngagements: totalEngagements,
        engagedDays: engagedDays,
        currentStreak: currentStreak,
        averageSessionDuration: averageSessionDuration,
        lastEngagementTime: lastEngagement,
        firstEngagementTime: firstEngagement,
        periodDays: daysToAnalyze,
        engagementRate: daysToAnalyze > 0 ? (engagedDays / daysToAnalyze) : 0.0,
      );
    } catch (e) {
      debugPrint('❌ Failed to get engagement statistics: $e');
      return EngagementStatistics.empty();
    }
  }

  /// Calculate current consecutive engagement streak
  Future<int> _calculateCurrentStreak(String userId) async {
    try {
      // Get recent daily engagement data
      final recentEvents = await _supabase
          .from('engagement_events')
          .select('created_at')
          .eq('user_id', userId)
          .eq('event_type', momentumEventType)
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
          )
          .order('created_at', ascending: false);

      if (recentEvents.isEmpty) return 0;

      // Group by day and count consecutive days
      final uniqueDays = <String>{};
      for (final event in recentEvents) {
        final eventDate = DateTime.parse(event['created_at']);
        final dayString = eventDate.toIso8601String().split('T')[0];
        uniqueDays.add(dayString);
      }

      final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));

      int streak = 0;
      DateTime? expectedDate = DateTime.now();

      for (final dayString in sortedDays) {
        final expectedDateString =
            expectedDate!.toIso8601String().split('T')[0];

        if (dayString == expectedDateString) {
          streak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('❌ Failed to calculate engagement streak: $e');
      return 0;
    }
  }

  /// Build engagement event data for Epic 2.1 integration
  Map<String, dynamic> _buildEngagementEventData({
    required String userId,
    required TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? additionalMetadata,
  }) {
    return {
      'user_id': userId,
      'event_type': momentumEventType,
      'event_date': _getTodayDateString(),
      'value': {
        'content_id': content.id,
        'content_date': content.contentDate.toIso8601String().split('T')[0],
        'topic_category': content.topicCategory.value,
        'content_title': content.title,
        'interaction_type': 'daily_engagement',
        if (sessionDuration != null) 'session_duration': sessionDuration,
        'ai_confidence_score': content.aiConfidenceScore,
        'estimated_reading_minutes': content.estimatedReadingMinutes,
        'momentum_points_awarded': 1,
        'engagement_timestamp': DateTime.now().toIso8601String(),
        ...?additionalMetadata,
      },
      'metadata': {
        'source': 'today_feed_daily_engagement',
        'app_version': VersionService.appVersion,
        'platform': defaultTargetPlatform.name,
        'service_version': 'DailyEngagementDetectionService_v1.0',
      },
    };
  }

  /// Record engagement event in database
  Future<void> _recordEngagementEvent(Map<String, dynamic> eventData) async {
    try {
      await _supabase.from('engagement_events').insert(eventData);
      debugPrint('✅ Engagement event recorded for momentum system');
    } catch (e) {
      debugPrint('❌ Failed to record engagement event: $e');
      rethrow;
    }
  }

  /// Get today's date string in YYYY-MM-DD format
  String _getTodayDateString() {
    return DateTime.now().toIso8601String().split('T')[0];
  }

  /// Set up periodic cache cleanup
  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(cacheCleanupInterval, (timer) {
      _cleanupExpiredCacheEntries();
    });
  }

  /// Clean up expired cache entries
  void _cleanupExpiredCacheEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _dailyEngagementCache.entries) {
      if (now.difference(entry.value) > cacheExpiryDuration) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _dailyEngagementCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('🧹 Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  /// Clear engagement cache (useful for testing)
  void clearCache() {
    _dailyEngagementCache.clear();
    debugPrint('🗑️ Daily engagement cache cleared');
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStatistics() {
    return {
      'cache_size': _dailyEngagementCache.length,
      'cache_entries': _dailyEngagementCache.keys.length,
      'oldest_entry':
          _dailyEngagementCache.values.isNotEmpty
              ? _dailyEngagementCache.values
                  .reduce((a, b) => a.isBefore(b) ? a : b)
                  .toIso8601String()
              : null,
      'newest_entry':
          _dailyEngagementCache.values.isNotEmpty
              ? _dailyEngagementCache.values
                  .reduce((a, b) => a.isAfter(b) ? a : b)
                  .toIso8601String()
              : null,
    };
  }

  /// Dispose of resources
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _dailyEngagementCache.clear();
    _isInitialized = false;
    debugPrint('🔄 DailyEngagementDetectionService disposed');
  }
}

/// Status of user's daily engagement with Today Feed
class EngagementStatus {
  final bool hasEngagedToday;
  final bool isEligibleForMomentum;
  final DateTime? lastEngagementTime;
  final EngagementSource source;
  final String? error;

  const EngagementStatus({
    required this.hasEngagedToday,
    required this.isEligibleForMomentum,
    this.lastEngagementTime,
    required this.source,
    this.error,
  });
}

/// Result of recording daily engagement
class EngagementResult {
  final bool success;
  final bool momentumAwarded;
  final int momentumPoints;
  final bool isDuplicate;
  final bool engagementRecorded;
  final String message;
  final DateTime? engagementTime;
  final DateTime? previousEngagementTime;
  final String? error;

  const EngagementResult({
    required this.success,
    required this.momentumAwarded,
    required this.momentumPoints,
    required this.isDuplicate,
    required this.engagementRecorded,
    required this.message,
    this.engagementTime,
    this.previousEngagementTime,
    this.error,
  });
}

/// Statistics about user engagement patterns
class EngagementStatistics {
  final int totalEngagements;
  final int engagedDays;
  final int currentStreak;
  final int averageSessionDuration;
  final DateTime? lastEngagementTime;
  final DateTime? firstEngagementTime;
  final int periodDays;
  final double engagementRate;

  const EngagementStatistics({
    required this.totalEngagements,
    required this.engagedDays,
    required this.currentStreak,
    required this.averageSessionDuration,
    this.lastEngagementTime,
    this.firstEngagementTime,
    required this.periodDays,
    required this.engagementRate,
  });

  factory EngagementStatistics.empty() {
    return const EngagementStatistics(
      totalEngagements: 0,
      engagedDays: 0,
      currentStreak: 0,
      averageSessionDuration: 0,
      periodDays: 0,
      engagementRate: 0.0,
    );
  }
}

/// Source of engagement status information
enum EngagementSource { cache, database, error }
