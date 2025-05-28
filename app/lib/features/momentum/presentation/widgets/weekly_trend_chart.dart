import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';
import '../../domain/models/momentum_data.dart';

/// Weekly trend chart widget showing 7-day momentum journey
/// Uses fl_chart with emoji markers and smooth line connections
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
    with TickerProviderStateMixin {
  late AnimationController _lineController;
  late AnimationController _emojiController;
  late Animation<double> _lineAnimation;
  late List<Animation<double>> _emojiAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Line drawing animation
    _lineController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeInOut),
    );

    // Emoji stagger animations
    _emojiController = AnimationController(
      duration: Duration(
        milliseconds: widget.animationDuration.inMilliseconds + 500,
      ),
      vsync: this,
    );

    _emojiAnimations = List.generate(7, (index) {
      final start = (index / 7) * 0.5 + 0.3; // Start after line begins
      final end = (start + 0.1).clamp(
        0.0,
        1.0,
      ); // Ensure end doesn't exceed 1.0

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _emojiController,
          curve: Interval(start, end, curve: Curves.elasticOut),
        ),
      );
    });
  }

  void _startAnimations() {
    // Use WidgetsBinding to ensure proper test handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _lineController.forward();
            _emojiController.forward();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weeklyTrend.isEmpty) {
      return _buildEmptyState();
    }

    final weeklyData = widget.weeklyTrend.map((d) => d.percentage).toList();

    return Semantics(
      label: AccessibilityService.getWeeklyTrendLabel(weeklyData),
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
              _buildHeader(),
              SizedBox(
                height: ResponsiveService.getResponsiveSpacing(context) * 0.8,
              ),
              Expanded(child: _buildChart()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final startDate = widget.weeklyTrend.first.date;
    final endDate = widget.weeklyTrend.last.date;
    final dateRange =
        '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}';

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
        const SizedBox(width: 8),
        Flexible(
          flex: 1,
          child: Text(
            dateRange,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return AnimatedBuilder(
      animation: Listenable.merge([_lineAnimation, ..._emojiAnimations]),
      builder: (context, child) {
        return LineChart(
          _createLineChartData(),
          duration: const Duration(milliseconds: 150),
        );
      },
    );
  }

  LineChartData _createLineChartData() {
    final spots =
        widget.weeklyTrend.asMap().entries.map((entry) {
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
          barWidth: 3,
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
              _lineAnimation.value < 1.0
                  ? [(_lineAnimation.value * 1000).round(), 1000]
                  : null,
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchCallback: _handleTouch,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppTheme.surfacePrimary,
          tooltipRoundedRadius: 8,
          getTooltipItems: _createTooltipItems,
        ),
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(color: _getTrendColor(), strokeWidth: 2),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 8,
                    color: _getTrendColor(),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
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
        index >= _emojiAnimations.length) {
      return FlDotCirclePainter(radius: 0, color: Colors.transparent);
    }

    final animation = _emojiAnimations[index];
    final scale = animation.value;

    return FlDotCirclePainter(
      radius: 16 * scale,
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
          reservedSize: 32,
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
    final animation =
        index < _emojiAnimations.length
            ? _emojiAnimations[index]
            : AlwaysStoppedAnimation(1.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: SizedBox(
            height: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                Text(
                  dayLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 8,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          color: AppTheme.textPrimary,
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
              color: AppTheme.textSecondary,
            ),
            SizedBox(
              height: ResponsiveService.getResponsiveSpacing(context) * 0.4,
            ),
            Text(
              'Your momentum journey will appear here',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
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
    if (widget.weeklyTrend.isEmpty) return AppTheme.textSecondary;

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

  @override
  void dispose() {
    _lineController.dispose();
    _emojiController.dispose();
    super.dispose();
  }
}
