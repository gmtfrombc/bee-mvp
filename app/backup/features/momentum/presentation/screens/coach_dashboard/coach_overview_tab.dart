import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/services/coach_intervention_service.dart';
import '../../widgets/coach_dashboard/coach_dashboard_filters.dart';
import '../../widgets/coach_dashboard/coach_statistics_cards.dart';

class CoachOverviewTab extends ConsumerWidget {
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;

  const CoachOverviewTab({
    super.key,
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interventionService = ref.watch(coachInterventionServiceProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: interventionService.getDashboardOverview(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Error loading dashboard: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => (context as Element).markNeedsBuild(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
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
              CoachStatisticsCards(data: data),
              const SizedBox(height: 24),
              _buildRecentActivity(data),
              const SizedBox(height: 24),
              _buildPriorityBreakdown(data),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(Map<String, dynamic> data) {
    final activities = data['recent_activities'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: activities.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length.clamp(0, 5),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final activity = activities[index] as Map<String, dynamic>;
                    return _buildActivityItem(activity);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['type'] as String? ?? '';
    final timestamp = DateTime.tryParse(activity['timestamp'] as String? ?? '');
    final patientName = activity['patient_name'] as String? ?? 'Unknown';
    final description = activity['description'] as String? ?? '';

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'intervention_created':
        icon = Icons.add_circle;
        iconColor = Colors.blue;
        break;
      case 'intervention_completed':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'intervention_scheduled':
        icon = Icons.schedule;
        iconColor = Colors.orange;
        break;
      case 'intervention_cancelled':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        patientName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          if (timestamp != null)
            Text(
              DateFormat('MMM d, h:mm a').format(timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: () {
        // Navigate to intervention details
      },
    );
  }

  Widget _buildPriorityBreakdown(Map<String, dynamic> data) {
    final priorities =
        data['priority_breakdown'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Breakdown',
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
          child: Column(
            children: [
              _buildPriorityRow('High', priorities['high'] ?? 0, Colors.red),
              const SizedBox(height: 12),
              _buildPriorityRow(
                'Medium',
                priorities['medium'] ?? 0,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildPriorityRow('Low', priorities['low'] ?? 0, Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityRow(String label, int count, Color color) {
    final total = count > 0 ? count : 1; // Avoid division by zero
    final percentage = (count / total * 100).clamp(0, 100);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
