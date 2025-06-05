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
        return Column(
          children: [
            CoachDashboardFilterBar(
              selectedPriority: selectedPriority,
              selectedStatus: selectedStatus,
              onPriorityChanged: onPriorityChanged,
              onStatusChanged: onStatusChanged,
            ),
            Expanded(child: _buildContent(context, snapshot)),
          ],
        );
      },
    );
  }

  /// Performance: Separate content building for better optimization
  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingState(context);
    }

    if (snapshot.hasError) {
      return _buildErrorState(context, snapshot.error.toString());
    }

    final interventions = snapshot.data ?? [];

    if (interventions.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildInterventionsList(context, interventions);
  }

  /// Performance: Optimized loading state with const widgets where possible
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
          Text(
            'Loading interventions...',
            style: TextStyle(
              fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Performance: Const error state widget
  Widget _buildErrorState(BuildContext context, String error) {
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
              'Error: $error',
              style: TextStyle(
                fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveService.getLargeSpacing(context)),
            // Performance: Add retry button for better UX
            ElevatedButton.icon(
              onPressed: () {
                // Trigger a rebuild to retry loading
                if (onInterventionUpdated != null) {
                  onInterventionUpdated!();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Performance: Const empty state widget
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

  /// Performance: Optimized list rendering with lazy loading
  Widget _buildInterventionsList(
    BuildContext context,
    List<Map<String, dynamic>> interventions,
  ) {
    return ListView.builder(
      // Performance: Key for better widget recycling
      key: const ValueKey('active_interventions_list'),
      padding: ResponsiveService.getResponsivePadding(context),
      itemCount: interventions.length,
      // Performance: Add cache extent for smoother scrolling
      cacheExtent: 1000,
      itemBuilder: (context, index) {
        final intervention = interventions[index];

        // Performance: Use unique keys for better list performance
        return Padding(
          key: ValueKey('intervention_${intervention['id'] ?? index}'),
          padding: EdgeInsets.only(
            bottom: ResponsiveService.getSmallSpacing(context),
          ),
          child: CoachDashboardInterventionCard(
            intervention: intervention,
            onComplete:
                () => _handleInterventionAction(
                  context,
                  'completed',
                  intervention['patient_name'] as String? ?? 'Unknown',
                ),
            onReschedule: () => _showRescheduleDialog(context, intervention),
            onCancel:
                () => _handleInterventionAction(
                  context,
                  'cancelled',
                  intervention['patient_name'] as String? ?? 'Unknown',
                ),
            onUpdate: onInterventionUpdated,
          ),
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
        behavior: SnackBarBehavior.floating, // Performance: Better UX
      ),
    );

    // Performance: Call update callback to refresh data
    if (onInterventionUpdated != null) {
      onInterventionUpdated!();
    }
  }

  /// Shows the reschedule dialog with responsive design
  void _showRescheduleDialog(
    BuildContext context,
    Map<String, dynamic> intervention,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Reschedule Intervention',
            style: TextStyle(
              fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
          content: Text(
            'Would you like to reschedule this intervention for ${intervention['patient_name'] ?? 'this patient'}?',
            style: TextStyle(
              fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleInterventionAction(
                  context,
                  'rescheduled',
                  intervention['patient_name'] as String? ?? 'Unknown',
                );
              },
              child: const Text('Reschedule'),
            ),
          ],
        );
      },
    );
  }
}
