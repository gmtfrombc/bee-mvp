import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/today_feed_content.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/version_service.dart';

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

/// Session quality metrics for engagement analysis
enum SessionQuality {
  brief('brief'), // < 30 seconds
  moderate('moderate'), // 30s - 2 minutes
  engaged('engaged'), // 2-5 minutes
  deep('deep'); // > 5 minutes

  const SessionQuality(this.value);
  final String value;

  static SessionQuality fromDuration(Duration duration) {
    if (duration < SessionTrackingConfig.shortReadThreshold) {
      return SessionQuality.brief;
    } else if (duration < SessionTrackingConfig.mediumReadThreshold) {
      return SessionQuality.moderate;
    } else if (duration < SessionTrackingConfig.longReadThreshold) {
      return SessionQuality.engaged;
    } else {
      return SessionQuality.deep;
    }
  }
}

/// Reading session data model for analytics
class ReadingSession {
  final String sessionId;
  final String userId;
  final int contentId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final SessionQuality quality;
  final int samplesCount;
  final double engagementScore;
  final Map<String, dynamic> metadata;

  const ReadingSession({
    required this.sessionId,
    required this.userId,
    required this.contentId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.quality,
    required this.samplesCount,
    required this.engagementScore,
    required this.metadata,
  });

  /// Create reading session from tracking data
  factory ReadingSession.fromTrackingData({
    required String sessionId,
    required String userId,
    required int contentId,
    required DateTime startTime,
    required DateTime endTime,
    required List<DateTime> activitySamples,
    required TodayFeedContent content,
    Map<String, dynamic>? additionalMetadata,
  }) {
    final duration = endTime.difference(startTime);
    final quality = SessionQuality.fromDuration(duration);
    final engagementScore = _calculateEngagementScore(
      duration,
      content.estimatedReadingMinutes,
      activitySamples.length,
    );

    return ReadingSession(
      sessionId: sessionId,
      userId: userId,
      contentId: contentId,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      quality: quality,
      samplesCount: activitySamples.length,
      engagementScore: engagementScore,
      metadata: {
        'content_title': content.title,
        'content_category': content.topicCategory.value,
        'estimated_reading_minutes': content.estimatedReadingMinutes,
        'ai_confidence_score': content.aiConfidenceScore,
        'platform': defaultTargetPlatform.name,
        'app_version': VersionService.appVersion,
        ...?additionalMetadata,
      },
    );
  }

  /// Calculate engagement score based on duration and content
  static double _calculateEngagementScore(
    Duration actualDuration,
    int estimatedMinutes,
    int samplesCount,
  ) {
    if (estimatedMinutes <= 0) return 0.0;

    final estimatedDuration = Duration(minutes: estimatedMinutes);
    final baseScore = math.min(
      actualDuration.inMilliseconds / estimatedDuration.inMilliseconds,
      2.0, // Cap at 2x estimated time
    );

    // Adjust for sampling quality (more samples = higher confidence)
    final samplingQuality = math.min(samplesCount / 10.0, 1.0);

    return (baseScore * samplingQuality).clamp(0.0, 2.0);
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'content_id': contentId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_seconds': duration.inSeconds,
      'session_quality': quality.value,
      'samples_count': samplesCount,
      'engagement_score': engagementScore,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      contentId: json['content_id'] as int,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      duration: Duration(seconds: json['duration_seconds'] as int),
      quality: SessionQuality.values.firstWhere(
        (q) => q.value == json['session_quality'],
        orElse: () => SessionQuality.brief,
      ),
      samplesCount: json['samples_count'] as int,
      engagementScore: (json['engagement_score'] as num).toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingSession &&
        other.sessionId == sessionId &&
        other.userId == userId &&
        other.contentId == contentId;
  }

  @override
  int get hashCode => Object.hash(sessionId, userId, contentId);

  @override
  String toString() {
    return 'ReadingSession(id: $sessionId, duration: ${duration.inSeconds}s, quality: ${quality.value})';
  }
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

  /// Start periodic activity sampling
  void startSampling() {
    _samplingTimer?.cancel();
    _samplingTimer = Timer.periodic(
      SessionTrackingConfig.samplingInterval,
      (_) => _recordActivitySample(),
    );

    _resetTimeoutTimer();
  }

  /// Record user activity sample
  void _recordActivitySample() {
    final now = DateTime.now();
    activitySamples.add(now);
    lastActivity = now;
    _resetTimeoutTimer();
  }

  /// Reset session timeout timer
  void _resetTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(
      SessionTrackingConfig.sessionTimeout,
      () => _onSessionTimeout(),
    );
  }

  /// Handle session timeout
  void _onSessionTimeout() {
    debugPrint('⏰ Session timeout for session $sessionId');
    // Session will be finalized by the service
  }

  /// Record user interaction (tap, scroll, etc.)
  void recordInteraction() {
    final now = DateTime.now();
    lastActivity = now;
    activitySamples.add(now);
    _resetTimeoutTimer();
  }

  /// Finalize session and create ReadingSession
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

  /// Dispose resources
  void dispose() {
    _samplingTimer?.cancel();
    _timeoutTimer?.cancel();
  }
}

/// Session analytics aggregation data
class SessionAnalytics {
  final int totalSessions;
  final Duration totalReadingTime;
  final Duration averageSessionDuration;
  final double averageEngagementScore;
  final Map<SessionQuality, int> qualityDistribution;
  final Map<String, double> topicEngagement;
  final DateTime? lastSessionTime;
  final int consecutiveDaysWithSessions;

  const SessionAnalytics({
    required this.totalSessions,
    required this.totalReadingTime,
    required this.averageSessionDuration,
    required this.averageEngagementScore,
    required this.qualityDistribution,
    required this.topicEngagement,
    this.lastSessionTime,
    required this.consecutiveDaysWithSessions,
  });

  factory SessionAnalytics.empty() {
    return const SessionAnalytics(
      totalSessions: 0,
      totalReadingTime: Duration.zero,
      averageSessionDuration: Duration.zero,
      averageEngagementScore: 0.0,
      qualityDistribution: {},
      topicEngagement: {},
      consecutiveDaysWithSessions: 0,
    );
  }

  /// Calculate reading efficiency score (0.0 - 1.0)
  double get readingEfficiency {
    if (totalSessions == 0) return 0.0;
    return averageEngagementScore.clamp(0.0, 1.0);
  }

  /// Determine engagement level based on metrics
  String get engagementLevel {
    if (averageEngagementScore >= SessionTrackingConfig.highEngagementRate) {
      return 'high';
    } else if (averageEngagementScore >=
        SessionTrackingConfig.minEngagementRate) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  @override
  String toString() {
    return 'SessionAnalytics(sessions: $totalSessions, avgDuration: ${averageSessionDuration.inSeconds}s, engagement: ${(averageEngagementScore * 100).toStringAsFixed(1)}%)';
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
      await _supabase.from('today_feed_reading_sessions').insert(sessionData);
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
