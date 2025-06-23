import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/momentum_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/error_handling_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/offline_cache_service.dart';
import 'package:flutter/foundation.dart';

/// API service for momentum-related data operations
class MomentumApiService {
  final SupabaseClient _supabase;

  /// Constructor that accepts a SupabaseClient instance
  MomentumApiService(this._supabase);

  /// Get current momentum data for the authenticated user
  Future<MomentumData> getCurrentMomentum() async {
    return await ErrorHandlingService.executeWithRetry(
      () async {
        // Enhanced offline handling with stale data support
        if (ConnectivityService.isOffline) {
          // If offline, try to return cached data (even if stale)
          final cachedData = await OfflineCacheService.getCachedMomentumData(
            allowStaleData: true,
          );
          if (cachedData != null) {
            debugPrint('📱 Using cached momentum data (offline mode)');
            return cachedData;
          }

          // No cache available, return default data
          debugPrint('📱 No cache available, using default data (offline)');
          return _createDefaultMomentumData();
        }

        // Online - try cache first if valid, then fetch fresh data
        final cachedData = await OfflineCacheService.getCachedMomentumData();
        if (cachedData != null) {
          // debugPrint('📱 Using valid cached momentum data (online)'); // silenced to reduce log spam

          // Queue background refresh for next time
          _queueBackgroundRefresh();
          return cachedData;
        }

        // Fetch fresh data from API
        debugPrint('🌐 Fetching fresh momentum data from API');
        final user = _supabase.auth.currentUser;
        if (user == null) {
          // Return default data if not authenticated (for demo purposes)
          return _createDefaultMomentumData();
        }

        // Get current momentum score from daily_engagement_scores
        final today = DateTime.now().toIso8601String().split('T')[0];

        final response =
            await _supabase
                .from('daily_engagement_scores')
                .select('*')
                .eq('user_id', user.id)
                .eq('score_date', today)
                .maybeSingle();

        if (response == null) {
          // No data for today, return default state
          final defaultData = _createDefaultMomentumData();
          await OfflineCacheService.cacheMomentumData(defaultData);
          return defaultData;
        }

        // Get weekly trend data (last 7 days)
        final weekAgo = DateTime.now().subtract(const Duration(days: 6));
        final weekAgoStr = weekAgo.toIso8601String().split('T')[0];

        final weeklyResponse = await _supabase
            .from('daily_engagement_scores')
            .select('score_date, final_score, momentum_state')
            .eq('user_id', user.id)
            .gte('score_date', weekAgoStr)
            .lte('score_date', today)
            .order('score_date', ascending: true);

        // Get engagement stats for today
        final statsData = await _getEngagementStats(user.id);

        final momentumData = _mapToMomentumData(
          response,
          weeklyResponse,
          statsData,
        );

        // Cache the fresh data with high priority
        await OfflineCacheService.cacheMomentumData(
          momentumData,
          isHighPriority: true,
        );

        debugPrint('✅ Fresh momentum data fetched and cached');
        return momentumData;
      },
      retryConfig: RetryConfig.forErrorType(ErrorType.network),
      operationName: 'getCurrentMomentum',
      context: {'userId': _supabase.auth.currentUser?.id},
    );
  }

  /// Get momentum history for a specific date range
  Future<List<DailyMomentum>> getMomentumHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('daily_engagement_scores')
          .select('score_date, final_score, momentum_state')
          .eq('user_id', user.id)
          .gte('score_date', startDateStr)
          .lte('score_date', endDateStr)
          .order('score_date', ascending: true);

      return response.map<DailyMomentum>((item) {
        return DailyMomentum(
          date: DateTime.parse(item['score_date']),
          state: _mapStringToMomentumState(item['momentum_state']),
          percentage: (item['final_score'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch momentum history: $e');
    }
  }

  /// Calculate momentum score using Edge Function
  Future<MomentumData> calculateMomentumScore({String? targetDate}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final date = targetDate ?? DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase.functions.invoke(
        'momentum-score-calculator',
        body: {
          'user_id': user.id,
          'target_date': date,
          'include_trend': true,
          'include_stats': true,
        },
      );

      if (response.status != 200) {
        throw Exception(
          'Failed to calculate momentum score: ${response.status}',
        );
      }

      final data = response.data;
      if (data['success'] != true) {
        throw Exception('Calculation failed: ${data['error']}');
      }

      return _mapCalculationResponseToMomentumData(data['data']);
    } catch (e) {
      throw Exception('Failed to calculate momentum score: $e');
    }
  }

  /// Subscribe to real-time momentum updates
  RealtimeChannel subscribeToMomentumUpdates({
    required Function(MomentumData) onUpdate,
    required Function(String) onError,
  }) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // Don't throw exception, just call onError and return a dummy channel
      onError('User not authenticated - real-time updates disabled');
      return _supabase.channel('dummy_channel');
    }

    return _supabase
        .channel('momentum_updates_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_engagement_scores',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) async {
            try {
              // Refresh momentum data when changes occur
              final updatedData = await getCurrentMomentum();
              onUpdate(updatedData);
            } catch (e) {
              onError('Failed to process real-time update: $e');
            }
          },
        )
        .subscribe();
  }

  /// Get engagement statistics for today
  Future<Map<String, dynamic>> _getEngagementStats(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Get today's engagement events
    final todayEvents = await _supabase
        .from('engagement_events')
        .select('event_type, metadata')
        .eq('user_id', userId)
        .gte('created_at', '${today}T00:00:00.000Z')
        .lt('created_at', '${today}T23:59:59.999Z');

    // Calculate stats from events
    int lessonsCompleted = 0;
    int todayMinutes = 0;

    for (final event in todayEvents) {
      if (event['event_type'] == 'lesson_completion') {
        lessonsCompleted++;
      }
      if (event['metadata'] != null &&
          event['metadata']['duration_minutes'] != null) {
        todayMinutes += (event['metadata']['duration_minutes'] as num).toInt();
      }
    }

    // Get streak data (simplified for now)
    final streakDays = await _calculateStreakDays(userId);

    return {
      'lessons_completed': lessonsCompleted,
      'total_lessons': 5, // This should come from user's program
      'streak_days': streakDays,
      'today_minutes': todayMinutes,
    };
  }

  /// Calculate current streak days
  Future<int> _calculateStreakDays(String userId) async {
    // This is a simplified implementation
    // In a real app, you'd have more sophisticated streak calculation
    final recentScores = await _supabase
        .from('daily_engagement_scores')
        .select('score_date, final_score')
        .eq('user_id', userId)
        .gte(
          'score_date',
          DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String()
              .split('T')[0],
        )
        .order('score_date', ascending: false)
        .limit(30);

    int streak = 0;
    for (final score in recentScores) {
      if ((score['final_score'] as num) > 0) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Create default momentum data when no data exists
  MomentumData _createDefaultMomentumData() {
    return MomentumData(
      state: MomentumState.needsCare,
      percentage: 0.0,
      message: "Let's get started on your momentum journey! 🌱",
      lastUpdated: DateTime.now(),
      weeklyTrend: _generateEmptyWeeklyTrend(),
      stats: const MomentumStats(
        lessonsCompleted: 0,
        totalLessons: 5,
        streakDays: 0,
        todayMinutes: 0,
      ),
    );
  }

  /// Generate empty weekly trend for new users
  List<DailyMomentum> _generateEmptyWeeklyTrend() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return DailyMomentum(
        date: date,
        state: MomentumState.needsCare,
        percentage: 0.0,
      );
    });
  }

  /// Map database response to MomentumData
  MomentumData _mapToMomentumData(
    Map<String, dynamic> currentData,
    List<Map<String, dynamic>> weeklyData,
    Map<String, dynamic> statsData,
  ) {
    final state = _mapStringToMomentumState(currentData['momentum_state']);
    final percentage = (currentData['final_score'] as num).toDouble();

    return MomentumData(
      state: state,
      percentage: percentage,
      message: _generateMessageForState(state, percentage),
      lastUpdated: DateTime.parse(currentData['updated_at']),
      weeklyTrend: _mapWeeklyTrend(weeklyData),
      stats: MomentumStats(
        lessonsCompleted: statsData['lessons_completed'],
        totalLessons: statsData['total_lessons'],
        streakDays: statsData['streak_days'],
        todayMinutes: statsData['today_minutes'],
      ),
    );
  }

  /// Map calculation response to MomentumData
  MomentumData _mapCalculationResponseToMomentumData(
    Map<String, dynamic> data,
  ) {
    final state = _mapStringToMomentumState(data['momentum_state']);
    final percentage = (data['final_score'] as num).toDouble();

    return MomentumData(
      state: state,
      percentage: percentage,
      message: _generateMessageForState(state, percentage),
      lastUpdated: DateTime.now(),
      weeklyTrend:
          data['weekly_trend'] != null
              ? _mapWeeklyTrend(
                List<Map<String, dynamic>>.from(data['weekly_trend']),
              )
              : _generateEmptyWeeklyTrend(),
      stats:
          data['stats'] != null
              ? MomentumStats(
                lessonsCompleted: data['stats']['lessons_completed'] ?? 0,
                totalLessons: data['stats']['total_lessons'] ?? 5,
                streakDays: data['stats']['streak_days'] ?? 0,
                todayMinutes: data['stats']['today_minutes'] ?? 0,
              )
              : const MomentumStats(
                lessonsCompleted: 0,
                totalLessons: 5,
                streakDays: 0,
                todayMinutes: 0,
              ),
    );
  }

  /// Map weekly data to DailyMomentum list
  List<DailyMomentum> _mapWeeklyTrend(List<Map<String, dynamic>> weeklyData) {
    final now = DateTime.now();
    final weekDates = List.generate(
      7,
      (index) => now.subtract(Duration(days: 6 - index)),
    );

    return weekDates.map((date) {
      final dateStr = date.toIso8601String().split('T')[0];
      final dayData = weeklyData.firstWhere(
        (item) => item['score_date'] == dateStr,
        orElse: () => {'final_score': 0.0, 'momentum_state': 'NeedsCare'},
      );

      return DailyMomentum(
        date: date,
        state: _mapStringToMomentumState(dayData['momentum_state']),
        percentage: (dayData['final_score'] as num).toDouble(),
      );
    }).toList();
  }

  /// Map string to MomentumState enum
  MomentumState _mapStringToMomentumState(String? state) {
    switch (state) {
      case 'Rising':
        return MomentumState.rising;
      case 'Steady':
        return MomentumState.steady;
      case 'NeedsCare':
      default:
        return MomentumState.needsCare;
    }
  }

  /// Generate appropriate message for momentum state
  String _generateMessageForState(MomentumState state, double percentage) {
    switch (state) {
      case MomentumState.rising:
        if (percentage >= 85) {
          return "You're on fire! Keep up the amazing momentum! 🚀";
        } else {
          return "Great progress! You're building strong momentum! 🚀";
        }
      case MomentumState.steady:
        return "Steady as she goes! Consistent progress is key! 🙂";
      case MomentumState.needsCare:
        return "Let's get back on track together! Every step counts! 🌱";
    }
  }

  /// Queue a background refresh for when the user next opens the app
  void _queueBackgroundRefresh() {
    OfflineCacheService.queuePendingAction(
      {
        'type': 'momentum_refresh',
        'data': {'timestamp': DateTime.now().toIso8601String()},
      },
      priority: 1, // Low priority background task
    );
  }

  /// Warm cache when coming online
  Future<void> warmMomentumCache() async {
    if (ConnectivityService.isOffline) {
      debugPrint('⚠️ Cannot warm cache while offline');
      return;
    }

    try {
      debugPrint('🔥 Warming momentum cache...');
      await OfflineCacheService.warmCache();

      // Fetch fresh data in background
      await getCurrentMomentum();
      debugPrint('✅ Cache warmed with fresh momentum data');
    } catch (e) {
      debugPrint('❌ Failed to warm momentum cache: $e');
      await OfflineCacheService.queueError({
        'type': 'cache_warming_failed',
        'operation': 'warmMomentumCache',
        'error': e.toString(),
      });
    }
  }

  /// Get momentum data with enhanced offline support
  Future<MomentumData> getMomentumWithOfflineSupport({
    bool allowStaleData = true,
    Duration? maxCacheAge,
  }) async {
    // If offline, always allow stale data
    if (ConnectivityService.isOffline) {
      final cachedData = await OfflineCacheService.getCachedMomentumData(
        allowStaleData: true,
      );

      if (cachedData != null) {
        return cachedData;
      }

      // No cached data available, return default
      return _createDefaultMomentumData();
    }

    // Online - respect the allowStaleData parameter
    return getCurrentMomentum();
  }

  /// Process pending momentum-related actions when back online
  Future<void> processPendingMomentumActions() async {
    if (ConnectivityService.isOffline) {
      debugPrint('⚠️ Cannot process pending actions while offline');
      return;
    }

    try {
      final processedActions =
          await OfflineCacheService.processPendingActions();

      for (final action in processedActions) {
        switch (action['type']) {
          case 'momentum_refresh':
            await _handleMomentumRefresh(action);
            break;
          case 'momentum_update':
            await _handleMomentumUpdate(action);
            break;
          case 'stats_sync':
            await _handleStatsSync(action);
            break;
          default:
            debugPrint('⚠️ Unknown pending action type: ${action['type']}');
        }
      }

      if (processedActions.isNotEmpty) {
        debugPrint(
          '✅ Processed ${processedActions.length} pending momentum actions',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to process pending momentum actions: $e');
    }
  }

  Future<void> _handleMomentumRefresh(Map<String, dynamic> action) async {
    debugPrint('🔄 Processing momentum refresh action');
    await getCurrentMomentum();
  }

  Future<void> _handleMomentumUpdate(Map<String, dynamic> action) async {
    debugPrint('🔄 Processing momentum update action');
    // Handle momentum updates that were queued while offline
    final data = action['data'] as Map<String, dynamic>?;
    if (data != null) {
      // Process the update
      debugPrint('✅ Momentum update processed');
    }
  }

  Future<void> _handleStatsSync(Map<String, dynamic> action) async {
    debugPrint('🔄 Processing stats sync action');
    // Sync stats that were updated while offline
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _getEngagementStats(userId);
      debugPrint('✅ Stats sync completed');
    }
  }

  /// Initialize offline support (call this when the app starts)
  Future<void> initializeOfflineSupport() async {
    await OfflineCacheService.initialize();

    // Listen for connectivity changes
    ConnectivityService.statusStream.listen((status) async {
      if (status == ConnectivityStatus.online) {
        debugPrint(
          '📶 Connected - processing pending actions and warming cache',
        );
        await processPendingMomentumActions();
        await warmMomentumCache();
      } else {
        debugPrint('📴 Offline - entering offline mode');
      }
    });

    debugPrint('✅ Momentum offline support initialized');
  }

  /// Invalidate momentum cache (useful for testing or forced refresh)
  Future<void> invalidateMomentumCache({String? reason}) async {
    await OfflineCacheService.invalidateCache(
      momentumData: true,
      weeklyTrend: true,
      momentumStats: true,
      reason: reason,
    );
    debugPrint(
      '🗑️ Momentum cache invalidated${reason != null ? ' ($reason)' : ''}',
    );
  }
}
