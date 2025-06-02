import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';
import '../../domain/models/momentum_data.dart';
import 'components/chart_data_processor.dart';
import 'components/chart_tooltip_system.dart';
import 'components/chart_title_renderer.dart';

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
    final chartData = ChartDataProcessor.processWeeklyTrend(
      widget.weeklyTrend,
      context,
    );

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
  Widget _buildOptimizedHeader(ChartData chartData) {
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
  Widget _buildOptimizedChart(ChartData chartData) {
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

  LineChartData _createOptimizedLineChartData(ChartData chartData) {
    final spots =
        chartData.weeklyTrend.asMap().entries.map((entry) {
          final index = entry.key;
          final daily = entry.value;
          return FlSpot(
            index.toDouble(),
            ChartDataProcessor.stateToY(daily.state),
          );
        }).toList();

    final trendColor = _getTrendColor();

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: ChartTitleRenderer.createTitlesData(
        context,
        widget.weeklyTrend,
      ),
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
          color: trendColor,
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
            color: trendColor.withValues(alpha: 0.1),
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
        touchCallback: ChartTooltipSystem.handleTouch,
        touchTooltipData: ChartTooltipSystem.createTooltipData(
          context,
          widget.weeklyTrend,
        ),
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return ChartTooltipSystem.createSpotIndicators(
            barData,
            spotIndexes,
            context,
            trendColor,
          );
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

  // Helper method for trend color calculation
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
}
