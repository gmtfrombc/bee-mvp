import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/models/momentum_data.dart';

/// Chart data processor for WeeklyTrendChart
/// Handles data transformation and chart configuration calculations
class ChartDataProcessor {
  /// Convert daily momentum data to chart-ready format
  static ChartData processWeeklyTrend(
    List<DailyMomentum> weeklyTrend,
    BuildContext context,
  ) {
    return ChartData.fromWeeklyTrend(weeklyTrend, context);
  }

  /// Convert momentum state to Y-axis value for chart plotting
  static double stateToY(MomentumState state) {
    switch (state) {
      case MomentumState.needsCare:
        return 0.5;
      case MomentumState.steady:
        return 1.0;
      case MomentumState.rising:
        return 1.5;
    }
  }

  /// Get display text for momentum state
  static String getStateDisplayText(MomentumState state) {
    switch (state) {
      case MomentumState.rising:
        return 'Rising';
      case MomentumState.steady:
        return 'Steady';
      case MomentumState.needsCare:
        return 'Growing';
    }
  }

  /// Convert date to short day label (M, T, W, etc.)
  static String getDayLabel(DateTime date) {
    final weekday = date.weekday;
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[weekday - 1];
  }
}

/// Optimized data helper class to pre-calculate chart data
class ChartData {
  final List<DailyMomentum> weeklyTrend;
  final List<double> weeklyData;
  final String dateRange;

  const ChartData({
    required this.weeklyTrend,
    required this.weeklyData,
    required this.dateRange,
  });

  factory ChartData.fromWeeklyTrend(
    List<DailyMomentum> weeklyTrend,
    BuildContext context,
  ) {
    final weeklyData = weeklyTrend.map((d) => d.percentage).toList();
    final startDate = weeklyTrend.first.date;
    final endDate = weeklyTrend.last.date;
    final dateRange =
        '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}';

    return ChartData(
      weeklyTrend: weeklyTrend,
      weeklyData: weeklyData,
      dateRange: dateRange,
    );
  }
}
