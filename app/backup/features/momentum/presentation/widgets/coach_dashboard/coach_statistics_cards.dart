import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';

class CoachStatisticsCards extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool showAnalyticsCards;

  const CoachStatisticsCards({
    super.key,
    required this.data,
    this.showAnalyticsCards = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showAnalyticsCards) {
      return _buildAnalyticsCards(context);
    } else {
      return _buildOverviewCards(context);
    }
  }

  Widget _buildOverviewCards(BuildContext context) {
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: ResponsiveService.getGridColumnCount(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: ResponsiveService.getResponsiveSpacing(context),
      mainAxisSpacing: ResponsiveService.getResponsiveSpacing(context),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Active Interventions',
          '${stats['active'] ?? 0}',
          Icons.psychology,
          AppTheme.momentumRising,
        ),
        _buildStatCard(
          context,
          'Scheduled Today',
          '${stats['scheduled_today'] ?? 0}',
          Icons.schedule,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Completed This Week',
          '${stats['completed_week'] ?? 0}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'High Priority',
          '${stats['high_priority'] ?? 0}',
          Icons.priority_high,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCards(BuildContext context) {
    final stats = data['summary'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: ResponsiveService.getGridColumnCount(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: ResponsiveService.getResponsiveSpacing(context),
      mainAxisSpacing: ResponsiveService.getResponsiveSpacing(context),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Success Rate',
          '${stats['success_rate'] ?? 0}%',
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Avg Response Time',
          '${stats['avg_response_time'] ?? 0}h',
          Icons.timer,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Total Interventions',
          '${stats['total_interventions'] ?? 0}',
          Icons.psychology,
          AppTheme.momentumRising,
        ),
        _buildStatCard(
          context,
          'Patient Satisfaction',
          '${stats['satisfaction_score'] ?? 0}/5',
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: ResponsiveService.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: ResponsiveService.getIconSize(context),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveService.getSmallSpacing(context),
                  vertical: ResponsiveService.getTinySpacing(context),
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveService.getBorderRadius(context),
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize:
                        18 * ResponsiveService.getFontSizeMultiplier(context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          Text(
            title,
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
