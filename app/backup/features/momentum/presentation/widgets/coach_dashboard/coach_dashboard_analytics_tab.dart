import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/coach_intervention_service.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/theme/app_theme.dart';
import 'coach_dashboard_stat_card.dart';
import 'coach_dashboard_time_selector.dart';

/// Analytics tab for the Coach Dashboard
///
/// Displays comprehensive analytics including:
/// - Analytics metrics grid (success rate, response time, etc.)
/// - Intervention effectiveness chart placeholder
/// - Trend analysis with directional indicators
///
/// Uses ResponsiveService for cross-device compatibility
class CoachDashboardAnalyticsTab extends ConsumerWidget {
  const CoachDashboardAnalyticsTab({
    super.key,
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
  });

  final String selectedTimeRange;
  final ValueChanged<String> onTimeRangeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interventionService = ref.watch(coachInterventionServiceProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: interventionService.getInterventionAnalytics(selectedTimeRange),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(
                fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.red[600],
              ),
            ),
          );
        }

        final analytics = snapshot.data ?? {};

        return ResponsiveLayout(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CoachDashboardTimeSelector(
                  selectedTimeRange: selectedTimeRange,
                  onTimeRangeChanged: onTimeRangeChanged,
                ),
                SizedBox(height: ResponsiveService.getLargeSpacing(context)),
                _buildAnalyticsCards(context, analytics),
                SizedBox(height: ResponsiveService.getLargeSpacing(context)),
                _buildEffectivenessChart(context, analytics),
                SizedBox(height: ResponsiveService.getLargeSpacing(context)),
                _buildTrendAnalysis(context, analytics),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the analytics metrics grid
  Widget _buildAnalyticsCards(
    BuildContext context,
    Map<String, dynamic> analytics,
  ) {
    final stats = analytics['summary'] as Map<String, dynamic>? ?? {};
    final columnCount = ResponsiveService.getGridColumnCount(context);
    final spacing = ResponsiveService.getMediumSpacing(context);

    // For analytics cards, we want a consistent 2-column layout on most devices
    // but allow more columns on larger screens
    final analyticsColumnCount = columnCount >= 3 ? 3 : 2;

    // Use the responsive service height method for consistent card sizing
    // Using momentum card height as it provides more space for the coach dashboard stat card layout
    final cardHeight = ResponsiveService.getMomentumCardHeight(context);

    // Build the stat cards list
    final statCards = [
      CoachDashboardStatCard(
        title: 'Success Rate',
        value: '${stats['success_rate'] ?? 0}%',
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      CoachDashboardStatCard(
        title: 'Avg Response Time',
        value: '${stats['avg_response_time'] ?? 0}h',
        icon: Icons.timer,
        color: Colors.blue,
      ),
      CoachDashboardStatCard(
        title: 'Total Interventions',
        value: '${stats['total_interventions'] ?? 0}',
        icon: Icons.psychology,
        color: AppTheme.momentumRising,
      ),
      if (analyticsColumnCount >= 3 ||
          !ResponsiveService.shouldUseCompactLayout(context))
        CoachDashboardStatCard(
          title: 'Patient Satisfaction',
          value: '${stats['satisfaction_score'] ?? 0}/5',
          icon: Icons.star,
          color: Colors.amber,
        ),
    ];

    // Create rows with the calculated column count
    List<Widget> rows = [];
    for (int i = 0; i < statCards.length; i += analyticsColumnCount) {
      final rowCards = statCards.skip(i).take(analyticsColumnCount).toList();
      rows.add(
        Row(
          children:
              rowCards.map((card) {
                return Expanded(
                  child: Container(
                    height: cardHeight,
                    margin: EdgeInsets.only(
                      right: rowCards.last != card ? spacing : 0,
                    ),
                    child: card,
                  ),
                );
              }).toList(),
        ),
      );
    }

    return Column(
      children:
          rows.map((row) {
            return Container(
              margin: EdgeInsets.only(bottom: rows.last != row ? spacing : 0),
              child: row,
            );
          }).toList(),
    );
  }

  /// Builds the effectiveness chart section
  Widget _buildEffectivenessChart(
    BuildContext context,
    Map<String, dynamic> analytics,
  ) {
    final fontSize = 18 * ResponsiveService.getFontSizeMultiplier(context);
    final chartHeight =
        ResponsiveService.getWeeklyChartHeight(context) +
        60; // Extra height for chart
    final borderRadius = ResponsiveService.getBorderRadius(context);
    final padding = ResponsiveService.getMediumPadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intervention Effectiveness',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        Container(
          height: chartHeight,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Chart implementation would go here\n(fl_chart integration)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the trend analysis section
  Widget _buildTrendAnalysis(
    BuildContext context,
    Map<String, dynamic> analytics,
  ) {
    final trends = analytics['trends'] as List? ?? [];
    final fontSize = 18 * ResponsiveService.getFontSizeMultiplier(context);
    final borderRadius = ResponsiveService.getBorderRadius(context);
    final padding = ResponsiveService.getMediumPadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trend Analysis',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child:
              trends.isEmpty
                  ? Center(
                    child: Padding(
                      padding: ResponsiveService.getLargePadding(context),
                      child: Text(
                        'No trend data available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize:
                              14 *
                              ResponsiveService.getFontSizeMultiplier(context),
                        ),
                      ),
                    ),
                  )
                  : Column(
                    children:
                        trends.map<Widget>((trend) {
                          return _buildTrendItem(
                            context,
                            trend as Map<String, dynamic>,
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }

  /// Builds individual trend item
  Widget _buildTrendItem(BuildContext context, Map<String, dynamic> trend) {
    final metric = trend['metric'] as String? ?? '';
    final change = trend['change'] as double? ?? 0.0;
    final isPositive = change >= 0;
    final iconSize = ResponsiveService.getIconSize(context);
    final fontSize = 14 * ResponsiveService.getFontSizeMultiplier(context);
    final fontSizeValue = 14 * ResponsiveService.getFontSizeMultiplier(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveService.getSmallSpacing(context),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? Colors.green : Colors.red,
            size: iconSize,
          ),
          SizedBox(width: ResponsiveService.getMediumSpacing(context)),
          Expanded(
            child: Text(
              metric,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize),
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: fontSizeValue,
            ),
          ),
        ],
      ),
    );
  }
}
