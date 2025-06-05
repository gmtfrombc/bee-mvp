import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../domain/models/momentum_data.dart';
import 'chart_data_processor.dart';

/// Chart title renderer for WeeklyTrendChart
/// Handles bottom title rendering with emoji and day labels with complex responsive design
class ChartTitleRenderer {
  /// Create titles data configuration for the chart
  static FlTitlesData createTitlesData(
    BuildContext context,
    List<DailyMomentum> weeklyTrend,
  ) {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize:
              ResponsiveService.shouldUseCompactLayout(context) ? 28 : 32,
          getTitlesWidget:
              (value, meta) =>
                  _buildBottomTitle(value, meta, context, weeklyTrend),
        ),
      ),
    );
  }

  /// Build bottom title widget with emoji and day label
  static Widget _buildBottomTitle(
    double value,
    TitleMeta meta,
    BuildContext context,
    List<DailyMomentum> weeklyTrend,
  ) {
    final index = value.toInt();
    if (index < 0 || index >= weeklyTrend.length) {
      return const SizedBox.shrink();
    }

    final daily = weeklyTrend[index];
    final dayLabel = ChartDataProcessor.getDayLabel(daily.date);
    final emoji = AppTheme.getMomentumEmoji(daily.state);

    // Use responsive system for all sizing
    final isCompact = ResponsiveService.shouldUseCompactLayout(context);
    final fontMultiplier = ResponsiveService.getFontSizeMultiplier(context);
    final textScaler = MediaQuery.textScalerOf(context);

    // Calculate dynamic sizes that account for text scaling
    final baseEmojiSize = isCompact ? 12.0 : 14.0;
    final baseDaySize = isCompact ? 6.0 : 7.0;

    // Apply responsive multiplier but limit scaling to prevent overflow
    final maxScale = isCompact ? 1.2 : 1.4; // Limit scaling on small devices
    final effectiveScale = math.min(textScaler.scale(1.0), maxScale);

    final emojiSize = baseEmojiSize * fontMultiplier * effectiveScale;
    final daySize = baseDaySize * fontMultiplier * effectiveScale;

    // Use the reserved size to prevent overflow
    final height = isCompact ? 28.0 : 32.0;
    final spacing = ResponsiveService.getTinySpacing(context) * 0.5;

    return SizedBox(
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: emojiSize, height: 1.0)),
            SizedBox(height: spacing),
            Text(
              dayLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.getTextSecondary(context),
                fontSize: daySize,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
