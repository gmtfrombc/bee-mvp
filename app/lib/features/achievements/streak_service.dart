import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/connectivity_service.dart';
import 'package:flutter/foundation.dart';

/// Streak service for tracking consecutive chat engagement days
/// Calculates streak based on conversation_logs with ≥1 assistant reply per day
class StreakService {
  static final _supabase = Supabase.instance.client;

  /// Calculate current streak from conversation logs
  static Future<int> calculateCurrentStreak(String userId) async {
    try {
      // Get daily conversation activity (group by date)
      final response = await _supabase
          .from('conversation_logs')
          .select('timestamp')
          .eq('user_id', userId)
          .eq('role', 'assistant')
          .gte(
            'timestamp',
            DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
          )
          .order('timestamp', ascending: false);

      if (response.isEmpty) return 0;

      // Group conversations by date
      final Map<String, bool> dailyActivity = {};
      for (final log in response) {
        final date = DateTime.parse(log['timestamp'] as String);
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyActivity[dateKey] = true;
      }

      // Calculate consecutive days from today backwards
      int streak = 0;
      DateTime currentDate = DateTime.now();

      while (true) {
        final dateKey =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

        if (dailyActivity.containsKey(dateKey)) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('Error calculating streak: $e');
      return 0;
    }
  }

  /// Get streak metadata from user_meta table
  static Future<StreakMetadata> getStreakMetadata(String userId) async {
    try {
      final response =
          await _supabase
              .from('user_meta')
              .select('streak_start, current_streak')
              .eq('user_id', userId)
              .maybeSingle();

      if (response == null) {
        return StreakMetadata(
          startDate: null,
          currentStreak: 0,
          lastUpdated: DateTime.now(),
        );
      }

      return StreakMetadata(
        startDate:
            response['streak_start'] != null
                ? DateTime.parse(response['streak_start'] as String)
                : null,
        currentStreak: response['current_streak'] ?? 0,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error getting streak metadata: $e');
      return StreakMetadata(
        startDate: null,
        currentStreak: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Update streak in user_meta table
  static Future<void> updateStreakMetadata(
    String userId,
    int newStreak,
    DateTime? startDate,
  ) async {
    try {
      await _supabase.from('user_meta').upsert({
        'user_id': userId,
        'current_streak': newStreak,
        'streak_start': startDate?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating streak metadata: $e');
    }
  }

  /// Check if streak should be reset (no activity yesterday)
  static Future<bool> shouldResetStreak(String userId) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      final response = await _supabase
          .from('conversation_logs')
          .select('timestamp')
          .eq('user_id', userId)
          .eq('role', 'assistant')
          .gte('timestamp', yesterday.toIso8601String())
          .lt('timestamp', DateTime.now().toIso8601String())
          .limit(1);

      return response.isEmpty;
    } catch (e) {
      debugPrint('Error checking streak reset: $e');
      return false;
    }
  }
}

/// Streak metadata model
class StreakMetadata {
  final DateTime? startDate;
  final int currentStreak;
  final DateTime lastUpdated;

  StreakMetadata({
    required this.startDate,
    required this.currentStreak,
    required this.lastUpdated,
  });

  bool get hasSevenDayBadge => currentStreak >= 7;
}

/// Riverpod provider for current streak count
final streakProvider = FutureProvider<int>((ref) async {
  if (ConnectivityService.isOffline) return 0;

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 0;

  return await StreakService.calculateCurrentStreak(user.id);
});

/// Riverpod provider for streak metadata
final streakMetadataProvider = FutureProvider<StreakMetadata>((ref) async {
  if (ConnectivityService.isOffline) {
    return StreakMetadata(
      startDate: null,
      currentStreak: 0,
      lastUpdated: DateTime.now(),
    );
  }

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return StreakMetadata(
      startDate: null,
      currentStreak: 0,
      lastUpdated: DateTime.now(),
    );
  }

  return await StreakService.getStreakMetadata(user.id);
});
