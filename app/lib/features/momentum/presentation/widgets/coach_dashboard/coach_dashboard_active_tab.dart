import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/coach_intervention_service.dart';
import '../../../../../core/services/responsive_service.dart';
import 'coach_dashboard_filter_bar.dart';
import 'coach_dashboard_intervention_card.dart';

/// A responsive active interventions tab widget for the Coach Dashboard.
///
/// This widget displays active interventions with filtering capabilities and
/// comprehensive error and loading states. It uses ResponsiveService for
/// consistent spacing and sizing across devices.
///
/// Example usage:
/// ```dart
/// CoachDashboardActiveTab(
///   selectedPriority: 'high',
///   selectedStatus: 'pending',
///   onPriorityChanged: (value) => setState(() => priority = value),
///   onStatusChanged: (value) => setState(() => status = value),
///   onInterventionUpdated: () => refreshData(),
/// )
/// ```
class CoachDashboardActiveTab extends ConsumerWidget {
  const CoachDashboardActiveTab({
    super.key,
    required this.selectedPriority,
    required this.selectedStatus,
    required this.onPriorityChanged,
    required this.onStatusChanged,
    this.onInterventionUpdated,
  });

  /// Currently selected priority filter
  final String selectedPriority;

  /// Currently selected status filter
  final String selectedStatus;

  /// Callback function called when priority filter changes
  final ValueChanged<String> onPriorityChanged;

  /// Callback function called when status filter changes
  final ValueChanged<String> onStatusChanged;

  /// Callback function called when any intervention is updated
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
                      : _buildInterventionsList(context, interventions),
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
  ) {
    return ListView.builder(
      padding: ResponsiveService.getResponsivePadding(context),
      itemCount: interventions.length,
      itemBuilder: (context, index) {
        return CoachDashboardInterventionCard(
          intervention: interventions[index],
          onComplete:
              () => _handleInterventionAction(
                context,
                'completed',
                interventions[index]['patient_name'] as String? ?? 'Unknown',
              ),
          onReschedule:
              () => _showRescheduleDialog(context, interventions[index]),
          onCancel:
              () => _handleInterventionAction(
                context,
                'cancelled',
                interventions[index]['patient_name'] as String? ?? 'Unknown',
              ),
          onUpdate: onInterventionUpdated,
        );
      },
    );
  }

  /// Handles intervention action feedback
  void _handleInterventionAction(
    BuildContext context,
    String action,
    String patientName,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Intervention for $patientName $action successfully',
          style: TextStyle(
            fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
          ),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: action == 'completed' ? Colors.green : Colors.orange,
      ),
    );
  }

  /// Shows the reschedule dialog with responsive design
  void _showRescheduleDialog(
    BuildContext context,
    Map<String, dynamic> intervention,
  ) {
    final patientName = intervention['patient_name'] as String? ?? 'Unknown';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveService.getBorderRadius(context),
              ),
            ),
            title: Text(
              'Reschedule Intervention',
              style: TextStyle(
                fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient: $patientName',
                  style: TextStyle(
                    fontSize:
                        16 * ResponsiveService.getFontSizeMultiplier(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: ResponsiveService.getSmallSpacing(context)),
                Text(
                  'Reschedule functionality would be implemented here with date/time picker.',
                  style: TextStyle(
                    fontSize:
                        14 * ResponsiveService.getFontSizeMultiplier(context),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize:
                        14 * ResponsiveService.getFontSizeMultiplier(context),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleInterventionAction(
                    context,
                    'rescheduled',
                    patientName,
                  );
                  onInterventionUpdated?.call();
                },
                child: Text(
                  'Reschedule',
                  style: TextStyle(
                    fontSize:
                        14 * ResponsiveService.getFontSizeMultiplier(context),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
