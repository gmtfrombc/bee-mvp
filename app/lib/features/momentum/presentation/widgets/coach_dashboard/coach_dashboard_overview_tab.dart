import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/services/coach_intervention_service.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/theme/app_theme.dart';
import 'coach_dashboard_stat_card.dart';
import 'coach_dashboard_time_selector.dart';

/// A responsive overview tab widget for the Coach Dashboard.
///
/// This widget displays the overview information including statistics,
/// recent activity, and priority breakdown. It uses ResponsiveService
/// for consistent spacing and sizing across devices.
///
/// Example usage:
/// ```dart
/// CoachDashboardOverviewTab(
///   selectedTimeRange: '7d',
///   onTimeRangeChanged: (timeRange) {
///     // Handle time range change
///   },
/// )
/// ```
class CoachDashboardOverviewTab extends ConsumerWidget {
  const CoachDashboardOverviewTab({
    super.key,
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
  });

  /// The currently selected time range ('24h', '7d', or '30d')
  final String selectedTimeRange;

  /// Callback function called when the time range selection changes
  final ValueChanged<String> onTimeRangeChanged;

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
          return _buildErrorState(context, snapshot.error.toString());
        }

        final data = snapshot.data ?? {};
        return _buildOverviewContent(context, data);
      },
    );
  }

  /// Builds the error state with responsive design
  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveService.getIconSize(context, baseSize: 64),
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
            Text(
              'Error loading dashboard: $error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
            ElevatedButton(
              onPressed: () {
                // Trigger rebuild by notifying parent to refresh
                // This would need to be implemented in the parent widget
              },
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize:
                      16 * ResponsiveService.getFontSizeMultiplier(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main overview content with responsive layout
  Widget _buildOverviewContent(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return SingleChildScrollView(
      padding: ResponsiveService.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoachDashboardTimeSelector(
            selectedTimeRange: selectedTimeRange,
            onTimeRangeChanged: onTimeRangeChanged,
          ),
          SizedBox(height: ResponsiveService.getLargeSpacing(context)),
          _buildOverviewCards(context, data),
          SizedBox(height: ResponsiveService.getLargeSpacing(context)),
          _buildRecentActivity(context, data),
          SizedBox(height: ResponsiveService.getLargeSpacing(context)),
          _buildPriorityBreakdown(context, data),
        ],
      ),
    );
  }

  /// Builds the responsive overview statistics cards
  Widget _buildOverviewCards(BuildContext context, Map<String, dynamic> data) {
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: ResponsiveService.getGridColumnCount(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: ResponsiveService.getResponsiveSpacing(context),
      mainAxisSpacing: ResponsiveService.getResponsiveSpacing(context),
      childAspectRatio:
          ResponsiveService.shouldUseCompactLayout(context) ? 1.3 : 1.5,
      children: [
        CoachDashboardStatCard(
          title: 'Active Interventions',
          value: '${stats['active'] ?? 0}',
          icon: Icons.psychology,
          color: AppTheme.momentumRising,
        ),
        CoachDashboardStatCard(
          title: 'Scheduled Today',
          value: '${stats['scheduled_today'] ?? 0}',
          icon: Icons.schedule,
          color: Colors.orange,
        ),
        CoachDashboardStatCard(
          title: 'Completed This Week',
          value: '${stats['completed_week'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        CoachDashboardStatCard(
          title: 'High Priority',
          value: '${stats['high_priority'] ?? 0}',
          icon: Icons.priority_high,
          color: Colors.red,
        ),
      ],
    );
  }

  /// Builds the responsive recent activity section
  Widget _buildRecentActivity(BuildContext context, Map<String, dynamic> data) {
    final activities = data['recent_activities'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context),
            ),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child:
              activities.isEmpty
                  ? _buildEmptyActivityState(context)
                  : _buildActivityList(context, activities),
        ),
      ],
    );
  }

  /// Builds the empty state for recent activity
  Widget _buildEmptyActivityState(BuildContext context) {
    return Padding(
      padding: ResponsiveService.getResponsivePadding(context) * 2,
      child: Center(
        child: Text(
          'No recent activity',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
          ),
        ),
      ),
    );
  }

  /// Builds the activity list with responsive design
  Widget _buildActivityList(BuildContext context, List activities) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length.clamp(0, 5),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final activity = activities[index] as Map<String, dynamic>;
        return _buildActivityItem(context, activity);
      },
    );
  }

  /// Builds an individual activity item with responsive design
  Widget _buildActivityItem(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    final type = activity['type'] as String? ?? '';
    final timestamp = DateTime.tryParse(activity['timestamp'] as String? ?? '');
    final patientName = activity['patient_name'] as String? ?? 'Unknown';
    final description = activity['description'] as String? ?? '';

    final activityInfo = _getActivityInfo(type);

    return ListTile(
      contentPadding: ResponsiveService.getResponsivePadding(context),
      leading: CircleAvatar(
        backgroundColor: activityInfo.color.withValues(alpha: 0.1),
        child: Icon(
          activityInfo.icon,
          color: activityInfo.color,
          size: ResponsiveService.getIconSize(context, baseSize: 20),
        ),
      ),
      title: Text(
        patientName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
          if (timestamp != null)
            Text(
              DateFormat('MMM d, h:mm a').format(timestamp),
              style: TextStyle(
                fontSize: 12 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
        size: ResponsiveService.getIconSize(context, baseSize: 24),
      ),
      onTap: () {
        // Navigate to intervention details
        // This would be implemented by the parent widget
      },
    );
  }

  /// Gets the appropriate icon and color for an activity type
  ({IconData icon, Color color}) _getActivityInfo(String type) {
    switch (type) {
      case 'intervention_created':
        return (icon: Icons.add_circle, color: Colors.blue);
      case 'intervention_completed':
        return (icon: Icons.check_circle, color: Colors.green);
      case 'intervention_scheduled':
        return (icon: Icons.schedule, color: Colors.orange);
      case 'intervention_cancelled':
        return (icon: Icons.cancel, color: Colors.red);
      default:
        return (icon: Icons.info, color: Colors.grey);
    }
  }

  /// Builds the responsive priority breakdown section
  Widget _buildPriorityBreakdown(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final priorities =
        data['priority_breakdown'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Breakdown',
          style: TextStyle(
            fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
        Container(
          padding: ResponsiveService.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context),
            ),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildPriorityRow(
                context,
                'High',
                priorities['high'] ?? 0,
                Colors.red,
              ),
              SizedBox(height: ResponsiveService.getMediumSpacing(context)),
              _buildPriorityRow(
                context,
                'Medium',
                priorities['medium'] ?? 0,
                Colors.orange,
              ),
              SizedBox(height: ResponsiveService.getMediumSpacing(context)),
              _buildPriorityRow(
                context,
                'Low',
                priorities['low'] ?? 0,
                Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a responsive priority row with progress indicator
  Widget _buildPriorityRow(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    final total = count > 0 ? count : 1; // Avoid division by zero
    final percentage = (count / total * 100).clamp(0, 100);

    return Row(
      children: [
        Container(
          width: ResponsiveService.getMediumSpacing(context),
          height: ResponsiveService.getMediumSpacing(context),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: ResponsiveService.getMediumSpacing(context)),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
          ),
        ),
        SizedBox(width: ResponsiveService.getResponsiveSpacing(context)),
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
