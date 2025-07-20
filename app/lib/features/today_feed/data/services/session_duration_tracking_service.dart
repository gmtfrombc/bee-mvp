// @size-exempt Temporary: exceeds hard ceiling – scheduled for refactor

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/today_feed_content.dart';
import '../../../../core/services/connectivity_service.dart';
import '../datasources/today_feed_analytics_remote_datasource.dart';
import '../../domain/models/reading_session_models.dart';

/// Configuration constants for session duration tracking
class SessionTrackingConfig {
  // Minimum session thresholds (using ResponsiveService for non-hardcoded values)
  static const Duration minValidSession = Duration(seconds: 3);
  static const Duration maxValidSession = Duration(hours: 2);
  static const Duration sessionTimeout = Duration(minutes: 15);

  // Analytics thresholds
  static const Duration shortReadThreshold = Duration(seconds: 30);
  static const Duration mediumReadThreshold = Duration(minutes: 2);
  static const Duration longReadThreshold = Duration(minutes: 5);

  // Sample rates and batching
  static const Duration samplingInterval = Duration(seconds: 5);
  static const int maxPendingSessions = 50;
  static const Duration syncRetryDelay = Duration(minutes: 2);

  // Quality metrics
  static const double minEngagementRate = 0.3; // 30% of estimated reading time
  static const double highEngagementRate = 0.8; // 80% of estimated reading time
}

/// Active session tracker for real-time duration monitoring
class _ActiveSessionTracker {
  final String sessionId;
  final String userId;
  final int contentId;
  final DateTime startTime;
  final TodayFeedContent content;

  DateTime lastActivity;
  final List<DateTime> activitySamples = [];
  Timer? _samplingTimer;
  Timer? _timeoutTimer;

  _ActiveSessionTracker({
    required this.sessionId,
    required this.userId,
    required this.contentId,
    required this.startTime,
    required this.content,
  }) : lastActivity = startTime;

  void startSampling() {
    _samplingTimer?.cancel();
    _samplingTimer = Timer.periodic(
      SessionTrackingConfig.samplingInterval,
      (_) => _recordActivitySample(),
    );
    _resetTimeoutTimer();
  }

  void _recordActivitySample() {
    final now = DateTime.now();
    activitySamples.add(now);
    lastActivity = now;
    _resetTimeoutTimer();
  }

  void _resetTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(
      SessionTrackingConfig.sessionTimeout,
      _onSessionTimeout,
    );
  }

  void _onSessionTimeout() {
    debugPrint('⏰ Session timeout for session $sessionId');
  }

  void recordInteraction() {
    final now = DateTime.now();
    lastActivity = now;
    activitySamples.add(now);
    _resetTimeoutTimer();
  }

  ReadingSession finalize({Map<String, dynamic>? additionalMetadata}) {
    _samplingTimer?.cancel();
    _timeoutTimer?.cancel();

    final endTime = lastActivity;
    return ReadingSession.fromTrackingData(
      sessionId: sessionId,
      userId: userId,
      contentId: contentId,
      startTime: startTime,
      endTime: endTime,
      activitySamples: activitySamples,
      content: content,
      additionalMetadata: additionalMetadata,
    );
  }

  void dispose() {
    _samplingTimer?.cancel();
    _timeoutTimer?.cancel();
  }
}

/// Comprehensive session duration tracking service for Today Feed content
///
/// Implements T1.3.4.8: Session duration tracking for content engagement
/// Features:
/// - Real-time session tracking with activity sampling
/// - Engagement quality analysis and scoring
/// - Offline session caching and sync
/// - Comprehensive analytics and reporting
/// - Integration with existing interaction tracking services
class SessionDurationTrackingService {
  static final SessionDurationTrackingService _instance =
      SessionDurationTrackingService._internal();
  factory SessionDurationTrackingService() => _instance;
  SessionDurationTrackingService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  late final TodayFeedAnalyticsRemoteDataSource _remote;
  bool _isInitialized = false;

  // Active session management
  final Map<String, _ActiveSessionTracker> _activeSessions = {};
  final List<Map<String, dynamic>> _pendingSessions = [];
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _syncTimer;

  /// Initialize the service with Supabase client
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;
      _remote = TodayFeedAnalyticsRemoteDataSource();

      // Set up connectivity monitoring for offline sync
      _connectivitySubscription = ConnectivityService.statusStream.listen(
        _onConnectivityChanged,
      );

      // Set up periodic sync timer
      _syncTimer = Timer.periodic(
        SessionTrackingConfig.syncRetryDelay,
        (_) => _syncPendingSessions(),
      );

      _isInitialized = true;
      debugPrint('✅ SessionDurationTrackingService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize SessionDurationTrackingService: $e');
      rethrow;
    }
  }

  /// Start tracking session for content engagement
  ///
  /// Creates a new session tracker and begins activity monitoring
  Future<String> startSessionTracking({
    required String userId,
    required TodayFeedContent content,
    Map<String, dynamic>? sessionMetadata,
  }) async {
    await initialize();

    try {
      final sessionId = _generateSessionId();
      final contentId = content.id ?? 0;

      // Create active session tracker
      final tracker = _ActiveSessionTracker(
        sessionId: sessionId,
        userId: userId,
        contentId: contentId,
        startTime: DateTime.now(),
        content: content,
      );

      // Start activity sampling
      tracker.startSampling();
      _activeSessions[sessionId] = tracker;

      debugPrint(
        '🚀 Started session tracking: $sessionId for content ${content.title}',
      );

      return sessionId;
    } catch (e) {
      debugPrint('❌ Failed to start session tracking: $e');
      rethrow;
    }
  }

  /// Record user interaction during active session
  ///
  /// Updates activity tracking for engagement analysis
  void recordSessionInteraction(String sessionId) {
    final tracker = _activeSessions[sessionId];
    if (tracker != null) {
      tracker.recordInteraction();
      debugPrint('📱 Interaction recorded for session $sessionId');
    }
  }

  /// Finalize session tracking and save data
  ///
  /// Completes session tracking, calculates metrics, and stores data
  Future<ReadingSession?> finalizeSessionTracking({
    required String sessionId,
    Map<String, dynamic>? finalizationMetadata,
  }) async {
    await initialize();

    try {
      final tracker = _activeSessions.remove(sessionId);
      if (tracker == null) {
        debugPrint('⚠️ No active session found for ID: $sessionId');
        return null;
      }

      // Finalize session and calculate metrics
      final session = tracker.finalize(
        additionalMetadata: finalizationMetadata,
      );
      tracker.dispose();

      // Validate session duration
      if (!_isValidSession(session)) {
        debugPrint(
          '⚠️ Session discarded (invalid duration): ${session.duration.inSeconds}s',
        );
        return null;
      }

      // Store session data
      await _storeSessionData(session);

      debugPrint(
        '✅ Session finalized: ${session.sessionId} (${session.duration.inSeconds}s, ${session.quality.value})',
      );

      return session;
    } catch (e) {
      debugPrint('❌ Failed to finalize session tracking: $e');
      return null;
    }
  }

  /// Get session analytics for user
  ///
  /// Provides comprehensive analytics on reading behavior and engagement
  Future<SessionAnalytics> getSessionAnalytics({
    required String userId,
    int daysToAnalyze = 30,
  }) async {
    await initialize();

    try {
      final startDate = DateTime.now().subtract(Duration(days: daysToAnalyze));

      // Get session data from database
      final sessionData = await _getSessionsFromDatabase(
        userId: userId,
        startDate: startDate,
      );

      if (sessionData.isEmpty) {
        return SessionAnalytics.empty();
      }

      // Calculate aggregated analytics
      return _calculateSessionAnalytics(sessionData, daysToAnalyze);
    } catch (e) {
      debugPrint('❌ Failed to get session analytics: $e');
      return SessionAnalytics.empty();
    }
  }

  /// Get real-time session information
  ///
  /// Returns current session status and metrics
  Map<String, dynamic> getActiveSessionInfo(String sessionId) {
    final tracker = _activeSessions[sessionId];
    if (tracker == null) {
      return {'active': false};
    }

    final now = DateTime.now();
    final currentDuration = now.difference(tracker.startTime);

    return {
      'active': true,
      'session_id': sessionId,
      'start_time': tracker.startTime.toIso8601String(),
      'current_duration': currentDuration.inSeconds,
      'samples_count': tracker.activitySamples.length,
      'last_activity': tracker.lastActivity.toIso8601String(),
      'content_title': tracker.content.title,
    };
  }

  /// Get all active sessions for monitoring
  List<Map<String, dynamic>> getAllActiveSessions() {
    return _activeSessions.keys
        .map((sessionId) => getActiveSessionInfo(sessionId))
        .toList();
  }

  /// Clean up expired sessions
  ///
  /// Removes sessions that have exceeded timeout limits
  Future<void> cleanupExpiredSessions() async {
    final now = DateTime.now();
    final expiredSessions = <String>[];

    for (final entry in _activeSessions.entries) {
      final timeSinceLastActivity = now.difference(entry.value.lastActivity);
      if (timeSinceLastActivity > SessionTrackingConfig.sessionTimeout) {
        expiredSessions.add(entry.key);
      }
    }

    for (final sessionId in expiredSessions) {
      await finalizeSessionTracking(
        sessionId: sessionId,
        finalizationMetadata: {'termination_reason': 'timeout'},
      );
    }

    if (expiredSessions.isNotEmpty) {
      debugPrint('🧹 Cleaned up ${expiredSessions.length} expired sessions');
    }
  }

  /// Dispose service and clean up resources
  void dispose() {
    // Finalize all active sessions
    for (final sessionId in _activeSessions.keys.toList()) {
      finalizeSessionTracking(sessionId: sessionId);
    }

    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _activeSessions.clear();
    _isInitialized = false;

    debugPrint('🛑 SessionDurationTrackingService disposed');
  }

  // Private helper methods

  /// Generate unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(10000);
    return 'session_${timestamp}_$random';
  }

  /// Validate session duration and quality
  bool _isValidSession(ReadingSession session) {
    return session.duration >= SessionTrackingConfig.minValidSession &&
        session.duration <= SessionTrackingConfig.maxValidSession &&
        session.samplesCount > 0;
  }

  /// Store session data in database or cache
  Future<void> _storeSessionData(ReadingSession session) async {
    final sessionData = session.toJson();

    if (ConnectivityService.isOnline) {
      try {
        await _syncSessionToDatabase(sessionData);
      } catch (e) {
        debugPrint('❌ Failed to sync session immediately: $e');
        _cachePendingSession(sessionData);
      }
    } else {
      _cachePendingSession(sessionData);
    }
  }

  /// Sync session data to database
  Future<void> _syncSessionToDatabase(Map<String, dynamic> sessionData) async {
    try {
      await _remote.insertReadingSession(sessionData);
      debugPrint('✅ Session synced to database: ${sessionData['session_id']}');
    } catch (e) {
      debugPrint('❌ Failed to sync session to database: $e');
      rethrow;
    }
  }

  /// Cache session data for offline sync
  void _cachePendingSession(Map<String, dynamic> sessionData) {
    if (_pendingSessions.length >= SessionTrackingConfig.maxPendingSessions) {
      _pendingSessions.removeAt(0); // Remove oldest session
    }

    _pendingSessions.add({
      ...sessionData,
      'cached_at': DateTime.now().toIso8601String(),
    });

    debugPrint(
      '💾 Session cached for offline sync: ${sessionData['session_id']}',
    );
  }

  /// Handle connectivity changes for sync
  void _onConnectivityChanged(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online) {
      _syncPendingSessions();
    }
  }

  /// Sync pending sessions when online
  Future<void> _syncPendingSessions() async {
    if (_pendingSessions.isEmpty || !ConnectivityService.isOnline) {
      return;
    }

    final sessionsToSync = List<Map<String, dynamic>>.from(_pendingSessions);
    _pendingSessions.clear();

    int syncedCount = 0;
    for (final sessionData in sessionsToSync) {
      try {
        // Remove cache metadata before syncing
        final cleanData = Map<String, dynamic>.from(sessionData);
        cleanData.remove('cached_at');

        await _syncSessionToDatabase(cleanData);
        syncedCount++;
      } catch (e) {
        debugPrint('❌ Failed to sync cached session: $e');
        // Re-add to pending if sync fails
        _cachePendingSession(sessionData);
      }
    }

    if (syncedCount > 0) {
      debugPrint('📤 Synced $syncedCount cached sessions to database');
    }
  }

  /// Get sessions from database
  Future<List<Map<String, dynamic>>> _getSessionsFromDatabase({
    required String userId,
    required DateTime startDate,
  }) async {
    try {
      final sessions = await _supabase
          .from('today_feed_reading_sessions')
          .select('*')
          .eq('user_id', userId)
          .gte('start_time', startDate.toIso8601String())
          .order('start_time', ascending: false);

      return List<Map<String, dynamic>>.from(sessions);
    } catch (e) {
      debugPrint('❌ Failed to get sessions from database: $e');
      return [];
    }
  }

  /// Calculate comprehensive session analytics
  SessionAnalytics _calculateSessionAnalytics(
    List<Map<String, dynamic>> sessionData,
    int analysisPeriodDays,
  ) {
    if (sessionData.isEmpty) {
      return SessionAnalytics.empty();
    }

    final sessions = sessionData.map(ReadingSession.fromJson).toList();

    // Basic metrics
    final totalSessions = sessions.length;
    final totalReadingTime = sessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.duration,
    );
    final averageSessionDuration = Duration(
      milliseconds: totalReadingTime.inMilliseconds ~/ totalSessions,
    );
    final averageEngagementScore =
        sessions.fold<double>(
          0.0,
          (sum, session) => sum + session.engagementScore,
        ) /
        totalSessions;

    // Quality distribution
    final qualityDistribution = <SessionQuality, int>{};
    for (final session in sessions) {
      qualityDistribution[session.quality] =
          (qualityDistribution[session.quality] ?? 0) + 1;
    }

    // Topic engagement analysis
    final topicEngagement = <String, double>{};
    final topicCounts = <String, int>{};
    for (final session in sessions) {
      final topic =
          session.metadata['content_category'] as String? ?? 'unknown';
      topicEngagement[topic] =
          (topicEngagement[topic] ?? 0.0) + session.engagementScore;
      topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
    }
    // Calculate average engagement per topic
    for (final topic in topicEngagement.keys) {
      topicEngagement[topic] = topicEngagement[topic]! / topicCounts[topic]!;
    }

    // Consecutive days calculation
    final consecutiveDays = _calculateConsecutiveDays(sessions);

    return SessionAnalytics(
      totalSessions: totalSessions,
      totalReadingTime: totalReadingTime,
      averageSessionDuration: averageSessionDuration,
      averageEngagementScore: averageEngagementScore,
      qualityDistribution: qualityDistribution,
      topicEngagement: topicEngagement,
      lastSessionTime: sessions.isNotEmpty ? sessions.first.startTime : null,
      consecutiveDaysWithSessions: consecutiveDays,
    );
  }

  /// Calculate consecutive days with reading sessions
  int _calculateConsecutiveDays(List<ReadingSession> sessions) {
    if (sessions.isEmpty) return 0;

    final sessionDays =
        sessions
            .map((s) => s.startTime.toIso8601String().split('T')[0])
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a)); // Most recent first

    int consecutiveDays = 0;
    String? expectedDay = DateTime.now().toIso8601String().split('T')[0];

    for (final day in sessionDays) {
      if (day == expectedDay) {
        consecutiveDays++;
        final date = DateTime.parse('${day}T00:00:00Z');
        expectedDay =
            date
                .subtract(const Duration(days: 1))
                .toIso8601String()
                .split('T')[0];
      } else {
        break;
      }
    }

    return consecutiveDays;
  }
}
