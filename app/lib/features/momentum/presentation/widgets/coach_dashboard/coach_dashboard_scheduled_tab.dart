import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/coach_intervention_service.dart';
import '../../../../../core/services/responsive_service.dart';
import 'coach_dashboard_intervention_card.dart';

/// A responsive scheduled interventions tab widget for the Coach Dashboard.
///
/// This widget displays scheduled interventions with comprehensive error and
/// loading states. It uses ResponsiveService for consistent spacing and sizing
/// across devices, and includes intervention management functionality.
///
/// Example usage:
/// ```dart
/// CoachDashboardScheduledTab(
///   onInterventionUpdated: () {
///     // Handle intervention update
///   },
/// )
/// ```
class CoachDashboardScheduledTab extends ConsumerWidget {
  const CoachDashboardScheduledTab({super.key, this.onInterventionUpdated});

  /// Callback function called when any intervention is updated
  final VoidCallback? onInterventionUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interventionService = ref.watch(coachInterventionServiceProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: interventionService.getScheduledInterventions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }

        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error.toString());
        }

        final interventions = snapshot.data ?? [];
        return _buildScheduledContent(context, interventions);
      },
    );
  }

  /// Builds the loading state with responsive design
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: ResponsiveService.getIconSize(context, baseSize: 48),
              height: ResponsiveService.getIconSize(context, baseSize: 48),
              child: const CircularProgressIndicator(),
            ),
            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
            Text(
              'Loading scheduled interventions...',
              style: TextStyle(
                fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
              'Error loading scheduled interventions',
              style: TextStyle(
                fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            Text(
              error,
              style: TextStyle(
                fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
            ElevatedButton.icon(
              onPressed: () {
                // Trigger rebuild by calling onInterventionUpdated
                onInterventionUpdated?.call();
              },
              icon: Icon(
                Icons.refresh,
                size: ResponsiveService.getIconSize(context, baseSize: 20),
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize:
                      14 * ResponsiveService.getFontSizeMultiplier(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main scheduled interventions content
  Widget _buildScheduledContent(
    BuildContext context,
    List<Map<String, dynamic>> interventions,
  ) {
    if (interventions.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildInterventionsList(context, interventions);
  }

  /// Builds the empty state when no scheduled interventions exist
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: ResponsiveService.getIconSize(context, baseSize: 64),
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
            Text(
              'No scheduled interventions',
              style: TextStyle(
                fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            Text(
              'Scheduled interventions will appear here when created.',
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

  /// Builds the list of scheduled interventions with responsive design
  Widget _buildInterventionsList(
    BuildContext context,
    List<Map<String, dynamic>> interventions,
  ) {
    return ResponsiveLayout(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveService.getResponsiveSpacing(context),
        ),
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
      ),
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
