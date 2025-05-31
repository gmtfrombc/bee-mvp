import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

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
      return _buildAnalyticsCards();
    } else {
      return _buildOverviewCards();
    }
  }

  Widget _buildOverviewCards() {
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Active Interventions',
          '${stats['active'] ?? 0}',
          Icons.psychology,
          AppTheme.momentumRising,
        ),
        _buildStatCard(
          'Scheduled Today',
          '${stats['scheduled_today'] ?? 0}',
          Icons.schedule,
          Colors.orange,
        ),
        _buildStatCard(
          'Completed This Week',
          '${stats['completed_week'] ?? 0}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'High Priority',
          '${stats['high_priority'] ?? 0}',
          Icons.priority_high,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCards() {
    final stats = data['summary'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Success Rate',
          '${stats['success_rate'] ?? 0}%',
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          'Avg Response Time',
          '${stats['avg_response_time'] ?? 0}h',
          Icons.timer,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Interventions',
          '${stats['total_interventions'] ?? 0}',
          Icons.psychology,
          AppTheme.momentumRising,
        ),
        _buildStatCard(
          'Patient Satisfaction',
          '${stats['satisfaction_score'] ?? 0}/5',
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
