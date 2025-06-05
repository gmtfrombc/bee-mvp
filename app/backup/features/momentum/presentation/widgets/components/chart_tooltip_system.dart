import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../domain/models/momentum_data.dart';
import 'chart_data_processor.dart';

/// Chart tooltip system for WeeklyTrendChart
/// Handles touch interactions, tooltip display, and spot indicators
class ChartTooltipSystem {
  /// Create touch tooltip data configuration
  static LineTouchTooltipData createTooltipData(
    BuildContext context,
    List<DailyMomentum> weeklyTrend,
  ) {
    return LineTouchTooltipData(
      getTooltipColor: (touchedSpot) => AppTheme.getSurfacePrimary(context),
      tooltipRoundedRadius: 8,
      getTooltipItems:
          (touchedSpots) =>
              _createTooltipItems(touchedSpots, weeklyTrend, context),
    );
  }

  /// Create spot indicator data for touched spots
  static List<TouchedSpotIndicatorData> createSpotIndicators(
    LineChartBarData barData,
    List<int> spotIndexes,
    BuildContext context,
    Color trendColor,
  ) {
    return spotIndexes.map((index) {
      return TouchedSpotIndicatorData(
        FlLine(
          color: trendColor,
          strokeWidth:
              ResponsiveService.shouldUseCompactLayout(context) ? 1 : 2,
        ),
        FlDotData(
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 8,
              color: trendColor,
              strokeWidth:
                  ResponsiveService.shouldUseCompactLayout(context) ? 1 : 2,
              strokeColor: AppTheme.getSurfacePrimary(context),
            );
          },
        ),
      );
    }).toList();
  }

  /// Handle touch events (managed by tooltip system)
  static void handleTouch(
    FlTouchEvent event,
    LineTouchResponse? touchResponse,
  ) {
    // Touch handling is managed by the tooltip system
    // No additional state tracking needed
  }

  /// Create tooltip items for touched spots
  static List<LineTooltipItem> _createTooltipItems(
    List<LineBarSpot> touchedSpots,
    List<DailyMomentum> weeklyTrend,
    BuildContext context,
  ) {
    return touchedSpots.map((spot) {
      final index = spot.x.toInt();
      if (index >= weeklyTrend.length) {
        return LineTooltipItem('', const TextStyle());
      }

      final daily = weeklyTrend[index];
      final date = DateFormat('MMM d').format(daily.date);
      final stateText = ChartDataProcessor.getStateDisplayText(daily.state);
      final percentage = daily.percentage.round();

      return LineTooltipItem(
        '$date\n$stateText\n$percentage%',
        TextStyle(
          color: AppTheme.getTextPrimary(context),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      );
    }).toList();
  }
}
