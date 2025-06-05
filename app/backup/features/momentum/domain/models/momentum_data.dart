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

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'state': state.name,
      'percentage': percentage,
      'message': message,
      'lastUpdated': lastUpdated.toIso8601String(),
      'weeklyTrend': weeklyTrend.map((d) => d.toJson()).toList(),
      'stats': stats.toJson(),
    };
  }

  /// Create from JSON for caching
  factory MomentumData.fromJson(Map<String, dynamic> json) {
    return MomentumData(
      state: MomentumState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => MomentumState.steady,
      ),
      percentage: (json['percentage'] as num).toDouble(),
      message: json['message'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      weeklyTrend:
          (json['weeklyTrend'] as List<dynamic>)
              .map((d) => DailyMomentum.fromJson(d as Map<String, dynamic>))
              .toList(),
      stats: MomentumStats.fromJson(json['stats'] as Map<String, dynamic>),
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

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'state': state.name,
      'percentage': percentage,
    };
  }

  /// Create from JSON for caching
  factory DailyMomentum.fromJson(Map<String, dynamic> json) {
    return DailyMomentum(
      date: DateTime.parse(json['date'] as String),
      state: MomentumState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => MomentumState.steady,
      ),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
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

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'lessonsCompleted': lessonsCompleted,
      'totalLessons': totalLessons,
      'streakDays': streakDays,
      'todayMinutes': todayMinutes,
    };
  }

  /// Create from JSON for caching
  factory MomentumStats.fromJson(Map<String, dynamic> json) {
    return MomentumStats(
      lessonsCompleted: json['lessonsCompleted'] as int,
      totalLessons: json['totalLessons'] as int,
      streakDays: json['streakDays'] as int,
      todayMinutes: json['todayMinutes'] as int,
    );
  }
}
