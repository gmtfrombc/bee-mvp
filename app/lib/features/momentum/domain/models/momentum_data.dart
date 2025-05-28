import '../../../../core/theme/app_theme.dart';

/// Momentum data model representing user's current momentum state
class MomentumData {
  final MomentumState state;
  final double percentage;
  final String message;
  final DateTime lastUpdated;
  final List<DailyMomentum> weeklyTrend;
  final MomentumStats stats;

  const MomentumData({
    required this.state,
    required this.percentage,
    required this.message,
    required this.lastUpdated,
    required this.weeklyTrend,
    required this.stats,
  });

  /// Factory constructor for creating sample data
  factory MomentumData.sample() {
    return MomentumData(
      state: MomentumState.rising,
      percentage: 85.0,
      message: "You're on fire! Keep up the great momentum!",
      lastUpdated: DateTime.now(),
      weeklyTrend: _generateSampleWeeklyTrend(),
      stats: const MomentumStats(
        lessonsCompleted: 4,
        totalLessons: 5,
        streakDays: 7,
        todayMinutes: 25,
      ),
    );
  }

  /// Generate sample weekly trend data
  static List<DailyMomentum> _generateSampleWeeklyTrend() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final states = [
        MomentumState.steady,
        MomentumState.steady,
        MomentumState.rising,
        MomentumState.rising,
        MomentumState.steady,
        MomentumState.rising,
        MomentumState.rising,
      ];
      final percentages = [60.0, 65.0, 75.0, 80.0, 70.0, 85.0, 85.0];

      return DailyMomentum(
        date: date,
        state: states[index],
        percentage: percentages[index],
      );
    });
  }

  /// Copy with method for immutable updates
  MomentumData copyWith({
    MomentumState? state,
    double? percentage,
    String? message,
    DateTime? lastUpdated,
    List<DailyMomentum>? weeklyTrend,
    MomentumStats? stats,
  }) {
    return MomentumData(
      state: state ?? this.state,
      percentage: percentage ?? this.percentage,
      message: message ?? this.message,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      weeklyTrend: weeklyTrend ?? this.weeklyTrend,
      stats: stats ?? this.stats,
    );
  }
}

/// Daily momentum data for trend visualization
class DailyMomentum {
  final DateTime date;
  final MomentumState state;
  final double percentage;

  const DailyMomentum({
    required this.date,
    required this.state,
    required this.percentage,
  });
}

/// Momentum statistics for quick stats display
class MomentumStats {
  final int lessonsCompleted;
  final int totalLessons;
  final int streakDays;
  final int todayMinutes;

  const MomentumStats({
    required this.lessonsCompleted,
    required this.totalLessons,
    required this.streakDays,
    required this.todayMinutes,
  });

  /// Get lessons completion ratio as string
  String get lessonsRatio => '$lessonsCompleted/$totalLessons';

  /// Get streak as formatted string
  String get streakText => '$streakDays day${streakDays != 1 ? 's' : ''}';

  /// Get today's activity as formatted string
  String get todayText => '${todayMinutes}m';
}
