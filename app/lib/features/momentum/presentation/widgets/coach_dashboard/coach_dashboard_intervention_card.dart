import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/services/coach_intervention_service.dart';
import '../../../../../core/services/responsive_service.dart';

/// A responsive intervention card widget for the Coach Dashboard.
///
/// This widget displays intervention information with priority and status indicators,
/// action menu, and responsive design. It uses ResponsiveService for consistent
/// spacing and sizing across devices.
///
/// Example usage:
/// ```dart
/// CoachDashboardInterventionCard(
///   intervention: interventionData,
///   onComplete: () => handleComplete(),
///   onReschedule: () => handleReschedule(),
///   onCancel: () => handleCancel(),
/// )
/// ```
class CoachDashboardInterventionCard extends ConsumerWidget {
  const CoachDashboardInterventionCard({
    super.key,
    required this.intervention,
    this.onComplete,
    this.onReschedule,
    this.onCancel,
    this.onUpdate,
  });

  /// The intervention data map containing all intervention details
  final Map<String, dynamic> intervention;

  /// Callback function called when the intervention is completed
  final VoidCallback? onComplete;

  /// Callback function called when the intervention is rescheduled
  final VoidCallback? onReschedule;

  /// Callback function called when the intervention is cancelled
  final VoidCallback? onCancel;

  /// Callback function called when any update operation is performed
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(coachInterventionServiceProvider);

    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveService.getResponsiveSpacing(context),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
      ),
      elevation: ResponsiveService.shouldUseCompactLayout(context) ? 2 : 4,
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, service),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  /// Builds the header with priority, status, and action menu
  Widget _buildHeader(BuildContext context, CoachInterventionService service) {
    final priority = intervention['priority'] as String? ?? 'medium';
    final status = intervention['status'] as String? ?? 'pending';

    return Row(
      children: [
        _buildPriorityBadge(context, priority),
        SizedBox(width: ResponsiveService.getSmallSpacing(context)),
        _buildStatusBadge(context, status),
        const Spacer(),
        _buildActionMenu(context, service),
      ],
    );
  }

  /// Builds the priority badge with responsive design
  Widget _buildPriorityBadge(BuildContext context, String priority) {
    final priorityColor = _getPriorityColor(priority);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveService.getSmallSpacing(context),
        vertical: ResponsiveService.getTinySpacing(context),
      ),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) * 0.75,
        ),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: priorityColor,
          fontWeight: FontWeight.bold,
          fontSize: 12 * ResponsiveService.getFontSizeMultiplier(context),
        ),
      ),
    );
  }

  /// Builds the status badge with responsive design
  Widget _buildStatusBadge(BuildContext context, String status) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveService.getSmallSpacing(context),
        vertical: ResponsiveService.getTinySpacing(context),
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) * 0.75,
        ),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12 * ResponsiveService.getFontSizeMultiplier(context),
        ),
      ),
    );
  }

  /// Builds the action menu with responsive design
  Widget _buildActionMenu(
    BuildContext context,
    CoachInterventionService service,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: ResponsiveService.getIconSize(context, baseSize: 24),
      ),
      onSelected: (value) => _handleAction(value, service),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'complete',
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: ResponsiveService.getIconSize(context, baseSize: 20),
                  ),
                  SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                  Text(
                    'Mark Complete',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reschedule',
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Colors.orange,
                    size: ResponsiveService.getIconSize(context, baseSize: 20),
                  ),
                  SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                  Text(
                    'Reschedule',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: ResponsiveService.getIconSize(context, baseSize: 20),
                  ),
                  SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                  Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
    );
  }

  /// Builds the main content with patient info and details
  Widget _buildContent(BuildContext context) {
    final patientName = intervention['patient_name'] as String? ?? 'Unknown';
    final type = intervention['type'] as String? ?? 'general';
    final scheduledAt = DateTime.tryParse(
      intervention['scheduled_at'] as String? ?? '',
    );
    final notes = intervention['notes'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patientName,
          style: TextStyle(
            fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: ResponsiveService.getTinySpacing(context)),
        Text(
          'Type: ${type.replaceAll('_', ' ').toUpperCase()}',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (scheduledAt != null) ...[
          SizedBox(height: ResponsiveService.getTinySpacing(context)),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: ResponsiveService.getIconSize(context, baseSize: 16),
                color: Colors.grey[600],
              ),
              SizedBox(width: ResponsiveService.getTinySpacing(context)),
              Expanded(
                child: Text(
                  'Scheduled: ${DateFormat('MMM d, h:mm a').format(scheduledAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize:
                        14 * ResponsiveService.getFontSizeMultiplier(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (notes.isNotEmpty) ...[
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          Text(
            notes,
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
            maxLines: ResponsiveService.shouldUseCompactLayout(context) ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Handles action menu selections
  Future<void> _handleAction(
    String action,
    CoachInterventionService service,
  ) async {
    switch (action) {
      case 'complete':
        await service.completeIntervention(intervention['id']);
        onComplete?.call();
        onUpdate?.call();
        break;
      case 'reschedule':
        onReschedule?.call();
        break;
      case 'cancel':
        await service.cancelIntervention(intervention['id']);
        onCancel?.call();
        onUpdate?.call();
        break;
    }
  }

  /// Gets the appropriate color for intervention priority
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
}
