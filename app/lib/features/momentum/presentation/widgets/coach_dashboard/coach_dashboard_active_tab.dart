import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/services/coach_intervention_service.dart';
import '../../../../../core/services/responsive_service.dart';
import 'coach_dashboard_filter_bar.dart';

/// Coach Dashboard Active Interventions Tab
///
/// Displays active interventions with filtering capabilities and
/// intervention management actions (complete, reschedule, cancel).
/// Uses responsive design patterns from ResponsiveService.
class CoachDashboardActiveTab extends ConsumerWidget {
  const CoachDashboardActiveTab({
    super.key,
    required this.selectedPriority,
    required this.selectedStatus,
    required this.onPriorityChanged,
    required this.onStatusChanged,
    this.onInterventionUpdated,
  });

  final String selectedPriority;
  final String selectedStatus;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback? onInterventionUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interventionService = ref.watch(coachInterventionServiceProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: interventionService.getActiveInterventions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: ResponsiveService.getResponsivePadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: ResponsiveService.getCustomSpacing(context, 3.0),
                    color: Colors.red,
                  ),
                  SizedBox(height: ResponsiveService.getMediumSpacing(context)),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      fontSize:
                          16 * ResponsiveService.getFontSizeMultiplier(context),
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final interventions = snapshot.data ?? [];

        return Column(
          children: [
            CoachDashboardFilterBar(
              selectedPriority: selectedPriority,
              selectedStatus: selectedStatus,
              onPriorityChanged: onPriorityChanged,
              onStatusChanged: onStatusChanged,
            ),
            Expanded(
              child:
                  interventions.isEmpty
                      ? _buildEmptyState(context)
                      : _buildInterventionsList(
                        context,
                        interventions,
                        interventionService,
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: ResponsiveService.getCustomSpacing(context, 3.0),
              color: Colors.grey,
            ),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            Text(
              'No active interventions',
              style: TextStyle(
                fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.grey,
              ),
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            Text(
              'Active interventions will appear here',
              style: TextStyle(
                fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterventionsList(
    BuildContext context,
    List<Map<String, dynamic>> interventions,
    CoachInterventionService service,
  ) {
    return ListView.builder(
      padding: ResponsiveService.getResponsivePadding(context),
      itemCount: interventions.length,
      itemBuilder: (context, index) {
        return _buildInterventionCard(context, interventions[index], service);
      },
    );
  }

  Widget _buildInterventionCard(
    BuildContext context,
    Map<String, dynamic> intervention,
    CoachInterventionService service,
  ) {
    final priority = intervention['priority'] as String? ?? 'medium';
    final status = intervention['status'] as String? ?? 'pending';
    final patientName = intervention['patient_name'] as String? ?? 'Unknown';
    final type = intervention['type'] as String? ?? 'general';
    final scheduledAt = DateTime.tryParse(
      intervention['scheduled_at'] as String? ?? '',
    );
    final notes = intervention['notes'] as String? ?? '';

    final priorityColor = _getPriorityColor(priority);
    final deviceType = ResponsiveService.getDeviceType(context);
    final fontSizeMultiplier = ResponsiveService.getFontSizeMultiplier(context);

    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveService.getMediumSpacing(context),
      ),
      elevation: deviceType == DeviceType.desktop ? 4 : 2,
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              context,
              priority,
              status,
              priorityColor,
              intervention,
              service,
            ),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            _buildPatientInfo(context, patientName, type, fontSizeMultiplier),
            if (scheduledAt != null)
              _buildScheduleInfo(context, scheduledAt, fontSizeMultiplier),
            if (notes.isNotEmpty)
              _buildNotesSection(context, notes, fontSizeMultiplier),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    String priority,
    String status,
    Color priorityColor,
    Map<String, dynamic> intervention,
    CoachInterventionService service,
  ) {
    return Row(
      children: [
        _buildPriorityBadge(context, priority, priorityColor),
        SizedBox(width: ResponsiveService.getSmallSpacing(context)),
        _buildStatusBadge(context, status),
        const Spacer(),
        _buildActionMenu(context, intervention, service),
      ],
    );
  }

  Widget _buildPriorityBadge(
    BuildContext context,
    String priority,
    Color priorityColor,
  ) {
    final fontSizeMultiplier = ResponsiveService.getFontSizeMultiplier(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveService.getSmallSpacing(context),
        vertical: ResponsiveService.getTinySpacing(context),
      ),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: priorityColor,
          fontWeight: FontWeight.bold,
          fontSize: 12 * fontSizeMultiplier,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final fontSizeMultiplier = ResponsiveService.getFontSizeMultiplier(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveService.getSmallSpacing(context),
        vertical: ResponsiveService.getTinySpacing(context),
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12 * fontSizeMultiplier,
        ),
      ),
    );
  }

  Widget _buildActionMenu(
    BuildContext context,
    Map<String, dynamic> intervention,
    CoachInterventionService service,
  ) {
    return PopupMenuButton<String>(
      onSelected:
          (value) =>
              _handleInterventionAction(context, value, intervention, service),
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'complete',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Mark Complete'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reschedule',
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Reschedule'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Cancel'),
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildPatientInfo(
    BuildContext context,
    String patientName,
    String type,
    double fontSizeMultiplier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patientName,
          style: TextStyle(
            fontSize: 18 * fontSizeMultiplier,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveService.getTinySpacing(context)),
        Text(
          'Type: ${type.replaceAll('_', ' ').toUpperCase()}',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 14 * fontSizeMultiplier,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleInfo(
    BuildContext context,
    DateTime scheduledAt,
    double fontSizeMultiplier,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: ResponsiveService.getTinySpacing(context)),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 16 * fontSizeMultiplier,
            color: Colors.grey[600],
          ),
          SizedBox(width: ResponsiveService.getTinySpacing(context)),
          Text(
            'Scheduled: ${DateFormat('MMM d, h:mm a').format(scheduledAt)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14 * fontSizeMultiplier,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(
    BuildContext context,
    String notes,
    double fontSizeMultiplier,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: ResponsiveService.getSmallSpacing(context)),
      child: Text(notes, style: TextStyle(fontSize: 14 * fontSizeMultiplier)),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleInterventionAction(
    BuildContext context,
    String action,
    Map<String, dynamic> intervention,
    CoachInterventionService service,
  ) async {
    switch (action) {
      case 'complete':
        await service.completeIntervention(intervention['id']);
        onInterventionUpdated?.call();
        break;
      case 'reschedule':
        _showRescheduleDialog(context, intervention, service);
        break;
      case 'cancel':
        await service.cancelIntervention(intervention['id']);
        onInterventionUpdated?.call();
        break;
    }
  }

  void _showRescheduleDialog(
    BuildContext context,
    Map<String, dynamic> intervention,
    CoachInterventionService service,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Reschedule Intervention',
              style: TextStyle(
                fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
              ),
            ),
            content: Text(
              'Reschedule functionality would be implemented here',
              style: TextStyle(
                fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onInterventionUpdated?.call();
                  // Implement reschedule logic
                },
                child: const Text('Reschedule'),
              ),
            ],
          ),
    );
  }
}
