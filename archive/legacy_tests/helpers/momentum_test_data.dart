import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/core/theme/app_theme.dart';

/// Test data helper for Momentum UAT testing
class TestMomentumData {
  /// Create mock momentum data for testing different states
  static MomentumData createMockData({
    MomentumState state = MomentumState.steady,
    double percentage = 65.0,
    String? message,
    bool isFirstTime = false,
    bool triggerIntervention = false,
  }) {
    final defaultMessages = {
      MomentumState.rising: "You're doing great! Keep up the momentum! 🚀",
      MomentumState.steady: "Steady progress, you're on track! 🙂",
      MomentumState.needsCare: "Every small step counts. You've got this! 🌱",
    };

    return MomentumData(
      state: state,
      percentage: percentage,
      message: message ?? defaultMessages[state]!,
      stats: createMockStats(),
      weeklyTrend: createMockWeeklyTrend(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Create mock data with specific weekly trend
  static MomentumData createMockDataWithTrend() {
    return MomentumData(
      state: MomentumState.rising,
      percentage: 78.0,
      message: "Great week! Your momentum is building! 🚀",
      stats: createMockStats(),
      weeklyTrend: [
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 6)),
          state: MomentumState.needsCare,
          percentage: 45.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 5)),
          state: MomentumState.needsCare,
          percentage: 48.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 4)),
          state: MomentumState.steady,
          percentage: 55.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 3)),
          state: MomentumState.steady,
          percentage: 62.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 2)),
          state: MomentumState.steady,
          percentage: 68.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 1)),
          state: MomentumState.rising,
          percentage: 72.0,
        ),
        DailyMomentum(
          date: DateTime.now(),
          state: MomentumState.rising,
          percentage: 78.0,
        ),
      ],
      lastUpdated: DateTime.now(),
    );
  }

  /// Create mock data with streak information
  static MomentumData createMockDataWithStreak({int streak = 5}) {
    return MomentumData(
      state: MomentumState.rising,
      percentage: 82.0,
      message: "Amazing $streak-day streak! 🔥",
      stats: MomentumStats(
        lessonsCompleted: 4,
        totalLessons: 5,
        streakDays: streak,
        todayMinutes: 25,
      ),
      weeklyTrend: createMockWeeklyTrend(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Create mock momentum stats
  static MomentumStats createMockStats() {
    return const MomentumStats(
      lessonsCompleted: 3,
      totalLessons: 5,
      streakDays: 3,
      todayMinutes: 15,
    );
  }

  /// Create mock weekly trend data
  static List<DailyMomentum> createMockWeeklyTrend() {
    return [
      DailyMomentum(
        date: DateTime.now().subtract(const Duration(days: 6)),
        state: MomentumState.steady,
        percentage: 60.0,
      ),
      DailyMomentum(
        date: DateTime.now().subtract(const Duration(days: 5)),
        state: MomentumState.steady,
        percentage: 62.0,
      ),
      DailyMomentum(
        date: DateTime.now().subtract(const Duration(days: 4)),
        state: MomentumState.rising,
        percentage: 68.0,
      ),
      DailyMomentum(
        date: DateTime.now().subtract(const Duration(days: 3)),
        state: MomentumState.rising,
        percentage: 70.0,
      ),
      DailyMomentum(
        date: DateTime.now().subtract(const Duration(days: 2)),
        state: MomentumState.rising,
        percentage: 65.0,
      ),
      DailyMomentum(
        date: DateTime.now().subtract(const Duration(days: 1)),
        state: MomentumState.steady,
        percentage: 63.0,
      ),
      DailyMomentum(
        date: DateTime.now(),
        state: MomentumState.steady,
        percentage: 65.0,
      ),
    ];
  }
}
