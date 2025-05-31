import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../domain/models/momentum_data.dart';
import 'momentum_gauge.dart';

/// Content widget for the momentum detail modal
/// Contains all the main content sections: overview, factors, activity, and insights
class MomentumDetailContent extends StatelessWidget {
  final MomentumData momentumData;

  const MomentumDetailContent({super.key, required this.momentumData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveService.getLargePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMomentumOverview(context),
          SizedBox(height: ResponsiveService.getExtraLargeSpacing(context)),
          _buildMomentumFactors(context),
          SizedBox(height: ResponsiveService.getExtraLargeSpacing(context)),
          _buildRecentActivity(context),
          SizedBox(height: ResponsiveService.getExtraLargeSpacing(context)),
          _buildProgressInsights(context),
        ],
      ),
    );
  }

  Widget _buildMomentumOverview(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current State',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
            Row(
              children: [
                SizedBox(
                  width: ResponsiveService.getMomentumGaugeSize(context) * 0.8,
                  height: ResponsiveService.getMomentumGaugeSize(context) * 0.8,
                  child: MomentumGauge(
                    state: momentumData.state,
                    percentage: momentumData.percentage,
                    showGlow: false,
                    size: ResponsiveService.getMomentumGaugeSize(context) * 0.8,
                  ),
                ),
                SizedBox(
                  width: ResponsiveService.getResponsiveSpacing(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStateDisplayText(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.getMomentumColor(momentumData.state),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveService.getSmallSpacing(context),
                      ),
                      Text(
                        '${momentumData.percentage.toInt()}% momentum',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(
                        height: ResponsiveService.getSmallSpacing(context),
                      ),
                      Text(
                        momentumData.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentumFactors(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Momentum Factors',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
        Card(
          child: Padding(
            padding: ResponsiveService.getResponsivePadding(context),
            child: Column(
              children: [
                _buildFactorItem(
                  context,
                  'Learning Progress',
                  momentumData.stats.lessonsRatio,
                  Icons.school_rounded,
                  momentumData.stats.lessonsCompleted /
                      momentumData.stats.totalLessons,
                ),
                SizedBox(
                  height: ResponsiveService.getResponsiveSpacing(context),
                ),
                _buildFactorItem(
                  context,
                  'Consistency Streak',
                  momentumData.stats.streakText,
                  Icons.local_fire_department_rounded,
                  momentumData.stats.streakDays / 30.0, // Assume 30 days max
                ),
                SizedBox(
                  height: ResponsiveService.getResponsiveSpacing(context),
                ),
                _buildFactorItem(
                  context,
                  'Daily Engagement',
                  momentumData.stats.todayText,
                  Icons.timer_rounded,
                  momentumData.stats.todayMinutes / 60.0, // Assume 60 min max
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFactorItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    double progress,
  ) {
    return Row(
      children: [
        Container(
          width: ResponsiveService.getIconSize(context, baseSize: 40),
          height: ResponsiveService.getIconSize(context, baseSize: 40),
          decoration: BoxDecoration(
            color: AppTheme.getMomentumColor(
              momentumData.state,
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context),
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.getMomentumColor(momentumData.state),
            size: ResponsiveService.getIconSize(context, baseSize: 20),
          ),
        ),
        SizedBox(width: ResponsiveService.getResponsiveSpacing(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveService.getSmallSpacing(context)),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppTheme.surfaceSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.getMomentumColor(momentumData.state),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
        Card(
          child: Padding(
            padding: ResponsiveService.getResponsivePadding(context),
            child: Column(
              children:
                  momentumData.weeklyTrend
                      .take(3) // Show last 3 days
                      .map((daily) => _buildActivityItem(context, daily))
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, DailyMomentum daily) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveService.getSmallSpacing(context),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveService.getIconSize(context, baseSize: 32),
            height: ResponsiveService.getIconSize(context, baseSize: 32),
            decoration: BoxDecoration(
              color: AppTheme.getMomentumColor(
                daily.state,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveService.getBorderRadius(context),
              ),
            ),
            child: Icon(
              _getStateIcon(daily.state),
              color: AppTheme.getMomentumColor(daily.state),
              size: ResponsiveService.getIconSize(context, baseSize: 16),
            ),
          ),
          SizedBox(width: ResponsiveService.getResponsiveSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(daily.date),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${daily.percentage.toInt()}% momentum',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            daily.state.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.getMomentumColor(daily.state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInsights(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Insights',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
        Card(
          child: Padding(
            padding: ResponsiveService.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInsightItem(
                  context,
                  'Weekly Trend',
                  _getWeeklyTrendInsight(),
                  Icons.trending_up_rounded,
                ),
                SizedBox(
                  height: ResponsiveService.getResponsiveSpacing(context),
                ),
                _buildInsightItem(
                  context,
                  'Next Goal',
                  _getNextGoalInsight(),
                  Icons.flag_rounded,
                ),
                SizedBox(
                  height: ResponsiveService.getResponsiveSpacing(context),
                ),
                _buildInsightItem(
                  context,
                  'Recommendation',
                  _getRecommendationInsight(),
                  Icons.lightbulb_rounded,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ResponsiveService.getIconSize(context, baseSize: 32),
          height: ResponsiveService.getIconSize(context, baseSize: 32),
          decoration: BoxDecoration(
            color: AppTheme.momentumSteady.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context),
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.momentumSteady,
            size: ResponsiveService.getIconSize(context, baseSize: 16),
          ),
        ),
        SizedBox(width: ResponsiveService.getResponsiveSpacing(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: ResponsiveService.getTinySpacing(context)),
              Text(content, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _getStateDisplayText() {
    switch (momentumData.state) {
      case MomentumState.rising:
        return 'Rising 🚀';
      case MomentumState.steady:
        return 'Steady 🙂';
      case MomentumState.needsCare:
        return 'Needs Care 🌱';
    }
  }

  IconData _getStateIcon(MomentumState state) {
    switch (state) {
      case MomentumState.rising:
        return Icons.trending_up_rounded;
      case MomentumState.steady:
        return Icons.trending_flat_rounded;
      case MomentumState.needsCare:
        return Icons.trending_down_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    }
  }

  String _getWeeklyTrendInsight() {
    final recent = momentumData.weeklyTrend.take(3).toList();
    final average =
        recent.map((d) => d.percentage).reduce((a, b) => a + b) / recent.length;

    if (average >= 80) {
      return 'Excellent momentum this week! You\'re consistently performing well.';
    } else if (average >= 60) {
      return 'Good momentum this week. Keep building on your progress.';
    } else {
      return 'Your momentum is building. Focus on small, consistent actions.';
    }
  }

  String _getNextGoalInsight() {
    final stats = momentumData.stats;

    if (stats.lessonsCompleted < stats.totalLessons) {
      final remaining = stats.totalLessons - stats.lessonsCompleted;
      return 'Complete $remaining more lesson${remaining != 1 ? 's' : ''} to finish your current module.';
    } else {
      return 'Great job! You\'ve completed all lessons. Ready for the next challenge?';
    }
  }

  String _getRecommendationInsight() {
    switch (momentumData.state) {
      case MomentumState.rising:
        return 'You\'re doing great! Consider sharing your progress to inspire others.';
      case MomentumState.steady:
        return 'Maintain your consistency. Try adding one new learning activity today.';
      case MomentumState.needsCare:
        return 'Start small today. Even 5 minutes of engagement can rebuild momentum.';
    }
  }
}
