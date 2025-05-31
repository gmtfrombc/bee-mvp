import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/coach_intervention_service.dart';
import '../../widgets/coach_dashboard/coach_dashboard_filters.dart';
import '../../widgets/coach_dashboard/coach_statistics_cards.dart';

class CoachAnalyticsTab extends ConsumerWidget {
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;

  const CoachAnalyticsTab({
    super.key,
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
  });

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
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final analytics = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoachDashboardFilters(
                selectedTimeRange: selectedTimeRange,
                onTimeRangeChanged: onTimeRangeChanged,
              ),
              const SizedBox(height: 24),
              CoachStatisticsCards(data: analytics, showAnalyticsCards: true),
              const SizedBox(height: 24),
              _buildEffectivenessChart(analytics),
              const SizedBox(height: 24),
              _buildTrendAnalysis(analytics),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEffectivenessChart(Map<String, dynamic> analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Intervention Effectiveness',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: const Center(
            child: Text(
              'Chart implementation would go here\n(fl_chart integration)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis(Map<String, dynamic> analytics) {
    final trends = analytics['trends'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trend Analysis',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: trends.isEmpty
              ? const Center(
                  child: Text(
                    'No trend data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: trends.map<Widget>((trend) {
                    return _buildTrendItem(trend as Map<String, dynamic>);
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTrendItem(Map<String, dynamic> trend) {
    final metric = trend['metric'] as String? ?? '';
    final change = trend['change'] as double? ?? 0.0;
    final isPositive = change >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              metric,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
