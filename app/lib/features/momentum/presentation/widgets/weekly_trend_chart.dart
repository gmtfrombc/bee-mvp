import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';
import '../../domain/models/momentum_data.dart';

/// Weekly trend chart widget showing 7-day momentum journey
/// Uses fl_chart with emoji markers and smooth line connections
/// Optimized for performance with reduced animation controllers and memory efficiency
class WeeklyTrendChart extends StatefulWidget {
  final List<DailyMomentum> weeklyTrend;
  final VoidCallback? onTap;
  final Duration animationDuration;

  const WeeklyTrendChart({
    super.key,
    required this.weeklyTrend,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<WeeklyTrendChart> createState() => _WeeklyTrendChartState();
}

class _WeeklyTrendChartState extends State<WeeklyTrendChart>
    with SingleTickerProviderStateMixin {
  // Optimized: Use single animation controller instead of multiple controllers
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  Timer? _animationStartTimer; // Store timer reference for cleanup

  @override
  void initState() {
    super.initState();
    _setupOptimizedAnimations();
    _startAnimations();
  }

  void _setupOptimizedAnimations() {
    // Optimized: Single controller for all animations reduces memory overhead
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Optimized: Simple linear progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _startAnimations() {
    // Use WidgetsBinding to ensure proper test handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Optimized: Reduced delay for faster startup
        _animationStartTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationStartTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weeklyTrend.isEmpty) {
      return _buildEmptyState();
    }

    // Optimized: Pre-calculate data to avoid repeated computations
    final chartData = _ChartData.fromWeeklyTrend(widget.weeklyTrend, context);

    return Semantics(
      label: AccessibilityService.getWeeklyTrendLabel(chartData.weeklyData),
      hint: 'Chart showing your momentum progress over the past week',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveService.getBorderRadius(context),
          ),
        ),
        child: Container(
          height: ResponsiveService.getWeeklyChartHeight(context),
          padding: ResponsiveService.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOptimizedHeader(chartData),
              SizedBox(
                height: ResponsiveService.getResponsiveSpacing(context) * 0.8,
              ),
              Expanded(child: _buildOptimizedChart(chartData)),
            ],
          ),
        ),
      ),
    );
  }

  // Optimized: Pre-built header to reduce rebuilds
  Widget _buildOptimizedHeader(_ChartData chartData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            '📈 This Week\'s Journey',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: ResponsiveService.getSmallSpacing(context)),
        Flexible(
          flex: 1,
          child: Text(
            chartData.dateRange,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.getTextSecondary(context),
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Optimized: Chart with single animation and efficient rendering
  Widget _buildOptimizedChart(_ChartData chartData) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return LineChart(
          _createOptimizedLineChartData(chartData),
          duration: const Duration(milliseconds: 150),
        );
      },
    );
  }

  LineChartData _createOptimizedLineChartData(_ChartData chartData) {
    final spots =
        chartData.weeklyTrend.asMap().entries.map((entry) {
          final index = entry.key;
          final daily = entry.value;
          return FlSpot(index.toDouble(), _stateToY(daily.state));
        }).toList();

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: _createTitlesData(),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: 2,
      clipData: const FlClipData.all(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: _getTrendColor(),
          barWidth: ResponsiveService.shouldUseCompactLayout(context) ? 2 : 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return _createEmojiDot(index);
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: _getTrendColor().withValues(alpha: 0.1),
          ),
          // Animate line drawing
          dashArray:
              _progressAnimation.value < 1.0
                  ? [(_progressAnimation.value * 1000).round(), 1000]
                  : null,
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchCallback: _handleTouch,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppTheme.getSurfacePrimary(context),
          tooltipRoundedRadius: 8,
          getTooltipItems: _createTooltipItems,
        ),
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: _getTrendColor(),
                strokeWidth:
                    ResponsiveService.shouldUseCompactLayout(context) ? 1 : 2,
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 8,
                    color: _getTrendColor(),
                    strokeWidth:
                        ResponsiveService.shouldUseCompactLayout(context)
                            ? 1
                            : 2,
                    strokeColor: AppTheme.getSurfacePrimary(context),
                  );
                },
              ),
            );
          }).toList();
        },
      ),
    );
  }

  FlDotPainter _createEmojiDot(int index) {
    if (index >= widget.weeklyTrend.length ||
        index >= _progressAnimation.value.toInt()) {
      return FlDotCirclePainter(radius: 0, color: Colors.transparent);
    }

    return FlDotCirclePainter(
      radius: 16 * _progressAnimation.value,
      color: Colors.transparent,
      strokeWidth: 0,
    );
  }

  FlTitlesData _createTitlesData() {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize:
              ResponsiveService.shouldUseCompactLayout(context) ? 28 : 32,
          getTitlesWidget: _buildBottomTitle,
        ),
      ),
    );
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= widget.weeklyTrend.length) {
      return const SizedBox.shrink();
    }

    final daily = widget.weeklyTrend[index];
    final dayLabel = _getDayLabel(daily.date);
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

  List<LineTooltipItem> _createTooltipItems(List<LineBarSpot> touchedSpots) {
    return touchedSpots.map((spot) {
      final index = spot.x.toInt();
      if (index >= widget.weeklyTrend.length) {
        return LineTooltipItem('', const TextStyle());
      }

      final daily = widget.weeklyTrend[index];
      final date = DateFormat('MMM d').format(daily.date);
      final stateText = _getStateDisplayText(daily.state);
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

  void _handleTouch(FlTouchEvent event, LineTouchResponse? touchResponse) {
    // Touch handling is managed by the tooltip system
    // No additional state tracking needed
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
      ),
      child: Container(
        height: ResponsiveService.getWeeklyChartHeight(context),
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: ResponsiveService.getIconSize(context, baseSize: 32),
              color: AppTheme.getTextSecondary(context),
            ),
            SizedBox(
              height: ResponsiveService.getResponsiveSpacing(context) * 0.4,
            ),
            Text(
              'Your momentum journey will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  double _stateToY(MomentumState state) {
    switch (state) {
      case MomentumState.needsCare:
        return 0.5;
      case MomentumState.steady:
        return 1.0;
      case MomentumState.rising:
        return 1.5;
    }
  }

  Color _getTrendColor() {
    if (widget.weeklyTrend.isEmpty) return AppTheme.getTextSecondary(context);

    // Calculate overall trend
    final recentStates =
        widget.weeklyTrend.take(3).map((d) => d.state).toList();
    final risingCount =
        recentStates.where((s) => s == MomentumState.rising).length;
    final needsCareCount =
        recentStates.where((s) => s == MomentumState.needsCare).length;

    if (risingCount >= 2) return AppTheme.momentumRising;
    if (needsCareCount >= 2) return AppTheme.momentumCare;
    return AppTheme.momentumSteady;
  }

  String _getDayLabel(DateTime date) {
    final weekday = date.weekday;
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[weekday - 1];
  }

  String _getStateDisplayText(MomentumState state) {
    switch (state) {
      case MomentumState.rising:
        return 'Rising';
      case MomentumState.steady:
        return 'Steady';
      case MomentumState.needsCare:
        return 'Growing';
    }
  }
}

/// Optimized data helper class to pre-calculate chart data
class _ChartData {
  final List<DailyMomentum> weeklyTrend;
  final List<double> weeklyData;
  final String dateRange;

  const _ChartData({
    required this.weeklyTrend,
    required this.weeklyData,
    required this.dateRange,
  });

  factory _ChartData.fromWeeklyTrend(
    List<DailyMomentum> weeklyTrend,
    BuildContext context,
  ) {
    final weeklyData = weeklyTrend.map((d) => d.percentage).toList();
    final startDate = weeklyTrend.first.date;
    final endDate = weeklyTrend.last.date;
    final dateRange =
        '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}';

    return _ChartData(
      weeklyTrend: weeklyTrend,
      weeklyData: weeklyData,
      dateRange: dateRange,
    );
  }
}
