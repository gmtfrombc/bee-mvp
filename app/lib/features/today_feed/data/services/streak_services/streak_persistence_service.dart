import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/services/connectivity_service.dart';
import '../../models/today_feed_streak_models.dart';
import '../../../domain/models/today_feed_content.dart';

/// Service responsible for all streak data persistence operations
///
/// Handles:
/// - Database operations (store/retrieve streak data)
/// - Cache management (store/retrieve/clear cached streaks)
/// - Offline sync functionality (queue/sync pending updates)
///
/// Part of the modular streak tracking architecture
class StreakPersistenceService {
  static final StreakPersistenceService _instance =
      StreakPersistenceService._internal();
  factory StreakPersistenceService() => _instance;
  StreakPersistenceService._internal();

  // Dependencies
  late final SupabaseClient _supabase;
  bool _isInitialized = false;

  // Cache and offline support
  final Map<String, EngagementStreak> _streakCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final List<Map<String, dynamic>> _pendingUpdates = [];
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  // Configuration
  static const Map<String, dynamic> _config = {
    'cache_expiry_minutes': 30,
    'sync_retry_max_attempts': 3,
  };

  /// Initialize the persistence service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;

      // Set up connectivity monitoring for offline sync
      _setupConnectivityMonitoring();

      _isInitialized = true;
      debugPrint('✅ StreakPersistenceService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize StreakPersistenceService: $e');
      rethrow;
    }
  }

  // Database Operations

  /// Store streak data to database
  Future<void> storeStreakData(String userId, EngagementStreak streak) async {
    await initialize();

    try {
      await _supabase.from('today_feed_user_streaks').upsert({
        'user_id': userId,
        'current_streak': streak.currentStreak,
        'longest_streak': streak.longestStreak,
        'streak_start_date': streak.streakStartDate?.toIso8601String(),
        'last_engagement_date': streak.lastEngagementDate?.toIso8601String(),
        'is_active_today': streak.isActiveToday,
        'status': streak.status.value,
        'consistency_rate': streak.consistencyRate,
        'total_engagement_days': streak.totalEngagementDays,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Streak data stored successfully');
    } catch (e) {
      debugPrint('❌ Failed to store streak data: $e');
      rethrow;
    }
  }

  /// Get stored streak data from database
  Future<Map<String, dynamic>?> getStoredStreakData(String userId) async {
    await initialize();

    try {
      final response =
          await _supabase
              .from('today_feed_user_streaks')
              .select('*')
              .eq('user_id', userId)
              .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ Failed to get stored streak data: $e');
      return null;
    }
  }

  /// Get achieved milestones from database
  Future<List<StreakMilestone>> getAchievedMilestones(String userId) async {
    await initialize();

    try {
      final response = await _supabase
          .from('today_feed_streak_milestones')
          .select('*')
          .eq('user_id', userId)
          .order('achieved_at', ascending: false);

      return response.map<StreakMilestone>((data) {
        return StreakMilestone(
          streakLength: data['streak_length'],
          title: data['title'],
          description: data['description'],
          achievedAt: DateTime.parse(data['achieved_at']),
          isCelebrated: data['is_celebrated'] ?? false,
          type: MilestoneType.fromValue(data['type']),
          momentumBonusPoints: data['momentum_bonus_points'],
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get achieved milestones: $e');
      return [];
    }
  }

  /// Get pending celebration from database
  Future<StreakCelebration?> getPendingCelebration(String userId) async {
    await initialize();

    try {
      final response =
          await _supabase
              .from('today_feed_streak_celebrations')
              .select('*')
              .eq('user_id', userId)
              .eq('is_shown', false)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) return null;

      // Get milestone data
      final milestoneData =
          await _supabase
              .from('today_feed_streak_milestones')
              .select('*')
              .eq('user_id', userId)
              .eq('streak_length', response['milestone_streak_length'])
              .maybeSingle();

      if (milestoneData == null) return null;

      final milestone = StreakMilestone.fromJson(milestoneData);

      return StreakCelebration.fromJson({
        ...response,
        'milestone': milestone.toJson(),
      });
    } catch (e) {
      debugPrint('❌ Failed to get pending celebration: $e');
      return null;
    }
  }

  /// Store milestone data to database
  Future<void> storeMilestone(String userId, StreakMilestone milestone) async {
    await initialize();

    try {
      await _supabase.from('today_feed_streak_milestones').upsert({
        'user_id': userId,
        'streak_length': milestone.streakLength,
        'title': milestone.title,
        'description': milestone.description,
        'achieved_at': milestone.achievedAt.toIso8601String(),
        'is_celebrated': milestone.isCelebrated,
        'type': milestone.type.value,
        'momentum_bonus_points': milestone.momentumBonusPoints,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Milestone data stored successfully');
    } catch (e) {
      debugPrint('❌ Failed to store milestone data: $e');
      rethrow;
    }
  }

  /// Store celebration data to database
  Future<void> storeCelebration(
    String userId,
    StreakCelebration celebration,
  ) async {
    await initialize();

    try {
      await _supabase.from('today_feed_streak_celebrations').upsert({
        'user_id': userId,
        'celebration_id': celebration.celebrationId,
        'milestone_streak_length': celebration.milestone.streakLength,
        'type': celebration.type.value,
        'message': celebration.message,
        'animation_type': celebration.animationType,
        'duration_ms': celebration.durationMs,
        'is_shown': celebration.isShown,
        'shown_at': celebration.shownAt?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Celebration data stored successfully');
    } catch (e) {
      debugPrint('❌ Failed to store celebration data: $e');
      rethrow;
    }
  }

  // Cache Management

  /// Get cached streak data
  EngagementStreak? getCachedStreak(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return null;

    final expiryMinutes = _config['cache_expiry_minutes'];
    final isExpired =
        DateTime.now().difference(timestamp).inMinutes > expiryMinutes;

    if (isExpired) {
      _streakCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      return null;
    }

    return _streakCache[cacheKey];
  }

  /// Cache streak data
  void cacheStreak(String cacheKey, EngagementStreak streak) {
    _streakCache[cacheKey] = streak;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Clear cache for specific key or all cache
  void clearCache([String? cacheKey]) {
    if (cacheKey != null) {
      _streakCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
    } else {
      _streakCache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Check if cache entry exists and is valid
  bool isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;

    final expiryMinutes = _config['cache_expiry_minutes'];
    return DateTime.now().difference(timestamp).inMinutes <= expiryMinutes;
  }

  // Offline Sync Operations

  /// Queue streak update for offline sync
  void queueStreakUpdate(
    String userId,
    TodayFeedContent content,
    int? sessionDuration,
    Map<String, dynamic>? additionalMetadata,
  ) {
    _pendingUpdates.add({
      'type': 'streak_update',
      'user_id': userId,
      'content': content.toJson(),
      'session_duration': sessionDuration,
      'additional_metadata': additionalMetadata,
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('✅ Streak update queued for offline sync');
  }

  /// Queue milestone creation for offline sync
  void queueMilestoneCreation(String userId, StreakMilestone milestone) {
    _pendingUpdates.add({
      'type': 'milestone_creation',
      'user_id': userId,
      'milestone': milestone.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('✅ Milestone creation queued for offline sync');
  }

  /// Queue celebration creation for offline sync
  void queueCelebrationCreation(String userId, StreakCelebration celebration) {
    _pendingUpdates.add({
      'type': 'celebration_creation',
      'user_id': userId,
      'celebration': celebration.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('✅ Celebration creation queued for offline sync');
  }

  /// Get pending updates
  List<Map<String, dynamic>> getPendingUpdates() {
    return List<Map<String, dynamic>>.from(_pendingUpdates);
  }

  /// Clear pending updates (typically after successful sync)
  void clearPendingUpdates() {
    _pendingUpdates.clear();
  }

  /// Sync pending updates when connectivity restored
  Future<void> syncPendingUpdates() async {
    if (_pendingUpdates.isEmpty) return;

    debugPrint('ℹ️ Syncing ${_pendingUpdates.length} pending streak updates');

    final updates = List<Map<String, dynamic>>.from(_pendingUpdates);
    _pendingUpdates.clear();

    for (final update in updates) {
      try {
        switch (update['type']) {
          case 'milestone_creation':
            final milestone = StreakMilestone.fromJson(update['milestone']);
            await storeMilestone(update['user_id'], milestone);
            break;
          case 'celebration_creation':
            final celebration = StreakCelebration.fromJson(
              update['celebration'],
            );
            await storeCelebration(update['user_id'], celebration);
            break;
          // Note: streak_update type will be handled by the main service
          // as it requires coordination with calculation service
        }
      } catch (e) {
        debugPrint('❌ Failed to sync update: $e');
        // Re-queue failed updates
        _pendingUpdates.add(update);
      }
    }

    debugPrint('✅ Streak updates sync completed');
  }

  // Connectivity Management

  /// Setup connectivity monitoring for offline sync
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = ConnectivityService.statusStream.listen((
      status,
    ) {
      if (status == ConnectivityStatus.online) {
        syncPendingUpdates();
      }
    });
  }

  /// Check if device is currently online
  bool get isOnline => ConnectivityService.isOnline;

  /// Check if device is currently offline
  bool get isOffline => ConnectivityService.isOffline;

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _streakCache.clear();
    _cacheTimestamps.clear();
    _pendingUpdates.clear();
    debugPrint('✅ StreakPersistenceService disposed');
  }
}
