import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/today_feed_content.dart';
import '../../../../core/services/connectivity_service.dart';
import 'daily_engagement_detection_service.dart';

/// Service for tracking user interactions with Today Feed content
///
/// This service handles:
/// - Recording different types of content interactions
/// - Managing daily engagement tracking for momentum points
/// - Integrating with the engagement events system
/// - Handling offline interaction queuing
/// - Preventing duplicate momentum awards
class UserContentInteractionService {
  static final UserContentInteractionService _instance =
      UserContentInteractionService._internal();
  factory UserContentInteractionService() => _instance;
  UserContentInteractionService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  late final DailyEngagementDetectionService _engagementService;
  bool _isInitialized = false;
  final List<Map<String, dynamic>> _pendingInteractions = [];
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _syncTimer;

  // Configuration constants from PRD specifications
  static const int maxPendingInteractions = 100;
  static const Duration syncRetryDelay = Duration(minutes: 5);
  static const Duration maxSessionDuration = Duration(hours: 1);

  // Event types for engagement events integration (Epic 2.1)
  static const Map<TodayFeedInteractionType, String> _engagementEventTypes = {
    TodayFeedInteractionType.view: 'today_feed_view',
    TodayFeedInteractionType.tap: 'today_feed_tap',
    TodayFeedInteractionType.externalLinkClick: 'today_feed_external_click',
    TodayFeedInteractionType.share: 'today_feed_share',
    TodayFeedInteractionType.bookmark: 'today_feed_bookmark',
  };

  /// Initialize the service with Supabase client
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;
      _engagementService = DailyEngagementDetectionService();

      // Initialize the engagement detection service
      await _engagementService.initialize();

      // Initialize connectivity monitoring
      await ConnectivityService.initialize();
      _connectivitySubscription = ConnectivityService.statusStream.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint(
            '❌ UserContentInteractionService connectivity error: $error',
          );
        },
      );

      // Set up periodic sync for pending interactions
      _setupPeriodicSync();

      _isInitialized = true;
      debugPrint('✅ UserContentInteractionService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize UserContentInteractionService: $e');
      rethrow;
    }
  }

  /// Record user interaction with Today Feed content
  ///
  /// Enhanced for T1.3.4.2 with proper daily engagement detection
  ///
  /// Params:
  /// - [type]: The type of interaction (view, tap, external link click, etc.)
  /// - [content]: The content that was interacted with
  /// - [sessionDuration]: Duration of engagement in seconds (for view interactions)
  /// - [additionalData]: Optional additional metadata
  ///
  /// Returns: Map with interaction result and momentum award status
  Future<Map<String, dynamic>> recordInteraction(
    TodayFeedInteractionType type,
    TodayFeedContent content, {
    int? sessionDuration,
    Map<String, dynamic>? additionalData,
  }) async {
    await initialize();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Validate session duration
      final validatedDuration = _validateSessionDuration(sessionDuration);

      // For view interactions, use the new DailyEngagementDetectionService
      if (type == TodayFeedInteractionType.view) {
        final engagementResult = await _engagementService.recordDailyEngagement(
          userId,
          content,
          sessionDuration: validatedDuration,
          additionalMetadata: additionalData,
        );

        // Also record the detailed interaction data
        await _recordDetailedInteraction(
          userId: userId,
          content: content,
          type: type,
          sessionDuration: validatedDuration,
          additionalData: additionalData,
        );

        debugPrint(
          '✅ View interaction recorded: momentum=${engagementResult.momentumAwarded}',
        );

        return {
          'success': engagementResult.success,
          'momentum_awarded': engagementResult.momentumAwarded,
          'momentum_points': engagementResult.momentumPoints,
          'is_duplicate': engagementResult.isDuplicate,
          'synced_immediately': true,
          'interaction_type': type.value,
          'content_id': content.id?.toString() ?? '',
          'session_duration': validatedDuration,
          'message': engagementResult.message,
          'engagement_time': engagementResult.engagementTime?.toIso8601String(),
          'previous_engagement_time':
              engagementResult.previousEngagementTime?.toIso8601String(),
        };
      }

      // For non-view interactions, use the existing logic
      final contentId = content.id?.toString() ?? '';
      final isDuplicate = await _checkDuplicateInteraction(
        userId,
        contentId,
        type,
      );

      // Record the detailed interaction
      await _recordDetailedInteraction(
        userId: userId,
        content: content,
        type: type,
        sessionDuration: validatedDuration,
        additionalData: additionalData,
      );

      // Log engagement event for Epic 2.1 integration
      await _logEngagementEvent(
        userId: userId,
        type: type,
        content: content,
        sessionDuration: validatedDuration,
        additionalData: additionalData,
      );

      debugPrint('✅ Interaction recorded: ${type.value}');

      return {
        'success': true,
        'momentum_awarded': false, // Non-view interactions don't award momentum
        'momentum_points': 0,
        'is_duplicate': isDuplicate,
        'synced_immediately': true,
        'interaction_type': type.value,
        'content_id': contentId,
        'session_duration': validatedDuration,
      };
    } catch (e) {
      debugPrint('❌ Failed to record interaction: $e');
      return {
        'success': false,
        'error': e.toString(),
        'momentum_awarded': false,
        'momentum_points': 0,
      };
    }
  }

  /// Check if user has already engaged with content today for momentum
  ///
  /// Enhanced for T1.3.4.2 to use DailyEngagementDetectionService
  Future<bool> hasUserEngagedToday(String userId) async {
    await initialize();

    try {
      final status = await _engagementService.checkDailyEngagementStatus(
        userId,
      );
      return status.hasEngagedToday;
    } catch (e) {
      debugPrint('❌ Failed to check daily engagement: $e');
      return false; // Default to false to allow interaction
    }
  }

  /// Get daily engagement statistics
  ///
  /// New method for T1.3.4.2 - provides engagement analytics
  Future<EngagementStatistics> getDailyEngagementStatistics(
    String userId, {
    int daysToAnalyze = 30,
  }) async {
    await initialize();

    try {
      return await _engagementService.getEngagementStatistics(
        userId,
        daysToAnalyze: daysToAnalyze,
      );
    } catch (e) {
      debugPrint('❌ Failed to get engagement statistics: $e');
      return EngagementStatistics.empty();
    }
  }

  /// Record detailed interaction data
  Future<void> _recordDetailedInteraction({
    required String userId,
    required TodayFeedContent content,
    required TodayFeedInteractionType type,
    int? sessionDuration,
    Map<String, dynamic>? additionalData,
  }) async {
    final contentId = content.id?.toString() ?? '';

    // Prepare interaction data
    final interactionData = _buildInteractionData(
      userId: userId,
      contentId: contentId,
      contentDate: content.contentDate,
      type: type,
      sessionDuration: sessionDuration,
      content: content,
      additionalData: additionalData,
    );

    // Record the interaction
    if (ConnectivityService.isOnline) {
      try {
        await _syncInteractionToDatabase(interactionData);
      } catch (e) {
        debugPrint('❌ Failed to sync interaction immediately: $e');
        _queuePendingInteraction(interactionData);
      }
    } else {
      _queuePendingInteraction(interactionData);
    }
  }

  /// Get user's interaction history for analytics
  Future<List<Map<String, dynamic>>> getUserInteractionHistory(
    String userId, {
    int? limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await initialize();

    try {
      // Build query using the same pattern as momentum service
      dynamic query = _supabase
          .from('user_content_interactions')
          .select('*')
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('interaction_timestamp', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('interaction_timestamp', endDate.toIso8601String());
      }

      query = query.order('interaction_timestamp', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final results = await query;
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('❌ Failed to get interaction history: $e');
      return [];
    }
  }

  /// Get pending interactions count for diagnostics
  int getPendingInteractionsCount() => _pendingInteractions.length;

  /// Force sync pending interactions
  Future<Map<String, dynamic>> syncPendingInteractions() async {
    await initialize();

    if (_pendingInteractions.isEmpty) {
      return {'synced': 0, 'failed': 0, 'pending': 0};
    }

    if (!ConnectivityService.isOnline) {
      return {
        'synced': 0,
        'failed': 0,
        'pending': _pendingInteractions.length,
        'error': 'Device offline',
      };
    }

    int synced = 0;
    int failed = 0;
    final toSync = List<Map<String, dynamic>>.from(_pendingInteractions);
    _pendingInteractions.clear();

    for (final interaction in toSync) {
      try {
        await _syncInteractionToDatabase(interaction);
        synced++;
      } catch (e) {
        debugPrint('❌ Failed to sync pending interaction: $e');
        _pendingInteractions.add(interaction); // Re-queue for retry
        failed++;
      }
    }

    debugPrint(
      '🔄 Sync completed: $synced synced, $failed failed, ${_pendingInteractions.length} pending',
    );

    return {
      'synced': synced,
      'failed': failed,
      'pending': _pendingInteractions.length,
    };
  }

  // Private helper methods

  /// Validate session duration according to PRD specs
  int? _validateSessionDuration(int? duration) {
    if (duration == null) return null;

    // Clamp duration to reasonable limits (0 seconds to 1 hour)
    return duration.clamp(0, maxSessionDuration.inSeconds);
  }

  /// Check if this interaction is a duplicate for momentum purposes
  Future<bool> _checkDuplicateInteraction(
    String userId,
    String contentId,
    TodayFeedInteractionType type,
  ) async {
    // Only check duplicates for momentum-eligible interactions
    if (type != TodayFeedInteractionType.view) {
      return false;
    }

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final existingInteractions = await _supabase
          .from('user_content_interactions')
          .select('id')
          .eq('user_id', userId)
          .eq('content_id', contentId)
          .eq('interaction_type', type.value)
          .gte('interaction_timestamp', '${today}T00:00:00.000Z')
          .lt('interaction_timestamp', '${today}T23:59:59.999Z')
          .limit(1);

      return existingInteractions.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Failed to check duplicate interaction: $e');
      return false; // Default to false to allow interaction
    }
  }

  /// Build interaction data structure
  Map<String, dynamic> _buildInteractionData({
    required String userId,
    required String contentId,
    required DateTime contentDate,
    required TodayFeedInteractionType type,
    int? sessionDuration,
    required TodayFeedContent content,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'user_id': userId,
      'content_id': contentId,
      'interaction_type': type.value,
      'interaction_timestamp': DateTime.now().toIso8601String(),
      'session_duration': sessionDuration,
      'content_date': contentDate.toIso8601String().split('T')[0],
      'content_title': content.title,
      'content_category': content.topicCategory.value,
      'metadata': {
        'app_version': '1.0.0', // TODO: Get from package info
        'platform': defaultTargetPlatform.name,
        'content_confidence_score': content.aiConfidenceScore,
        'estimated_reading_minutes': content.estimatedReadingMinutes,
        ...?additionalData,
      },
    };
  }

  /// Sync interaction to database
  Future<void> _syncInteractionToDatabase(
    Map<String, dynamic> interaction,
  ) async {
    try {
      // Insert into user_content_interactions table
      await _supabase.from('user_content_interactions').insert(interaction);

      debugPrint('✅ Interaction synced to database');
    } catch (e) {
      debugPrint('❌ Failed to sync interaction to database: $e');
      rethrow;
    }
  }

  /// Log engagement event for Epic 2.3 integration
  Future<void> _logEngagementEvent({
    required String userId,
    required TodayFeedInteractionType type,
    required TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final eventType = _engagementEventTypes[type] ?? 'today_feed_interaction';

      final eventData = {
        'user_id': userId,
        'event_type': eventType,
        'value': {
          'content_id': content.id,
          'content_date': content.contentDate.toIso8601String().split('T')[0],
          'topic_category': content.topicCategory.value,
          'interaction_type': type.value,
          'content_title': content.title,
          if (sessionDuration != null) 'session_duration': sessionDuration,
          if (sessionDuration != null)
            'duration_minutes': (sessionDuration / 60).round(),
          'ai_confidence_score': content.aiConfidenceScore,
          'estimated_reading_minutes': content.estimatedReadingMinutes,
          ...?additionalData,
        },
      };

      await _supabase.from('engagement_events').insert(eventData);

      debugPrint('✅ Engagement event logged: $eventType');
    } catch (e) {
      debugPrint('❌ Failed to log engagement event: $e');
      // Don't rethrow - engagement event logging is supplementary
    }
  }

  /// Queue interaction for offline sync
  void _queuePendingInteraction(Map<String, dynamic> interaction) {
    if (_pendingInteractions.length >= maxPendingInteractions) {
      // Remove oldest interaction to prevent memory issues
      _pendingInteractions.removeAt(0);
      debugPrint('⚠️ Pending interactions queue full, removed oldest');
    }

    _pendingInteractions.add(interaction);
    debugPrint(
      '📝 Interaction queued for sync (${_pendingInteractions.length} pending)',
    );
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online &&
        _pendingInteractions.isNotEmpty) {
      debugPrint(
        '📡 Device back online, syncing ${_pendingInteractions.length} pending interactions',
      );

      // Delay sync to allow connection to stabilize
      Timer(const Duration(seconds: 2), () {
        syncPendingInteractions();
      });
    }
  }

  /// Set up periodic sync for pending interactions
  void _setupPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(syncRetryDelay, (timer) {
      if (ConnectivityService.isOnline && _pendingInteractions.isNotEmpty) {
        syncPendingInteractions();
      }
    });
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _pendingInteractions.clear();
    _isInitialized = false;
    debugPrint('✅ UserContentInteractionService disposed');
  }
}
