import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/services/coach_intervention_service.dart';
import '../../../../../core/services/responsive_service.dart';

class CoachInterventionCard extends StatelessWidget {
  final Map<String, dynamic> intervention;
  final CoachInterventionService service;
  final VoidCallback? onUpdate;

  const CoachInterventionCard({
    super.key,
    required this.intervention,
    required this.service,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final priority = intervention['priority'] as String? ?? 'medium';
    final status = intervention['status'] as String? ?? 'pending';
    final patientName = intervention['patient_name'] as String? ?? 'Unknown';
    final type = intervention['type'] as String? ?? 'general';
    final scheduledAt = DateTime.tryParse(
      intervention['scheduled_at'] as String? ?? '',
    );
    final notes = intervention['notes'] as String? ?? '';

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveService.getResponsiveSpacing(context),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
      ),
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveService.getSmallSpacing(context),
                    vertical: ResponsiveService.getTinySpacing(context),
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveService.getBorderRadius(context),
                    ),
                    border: Border.all(
                      color: priorityColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                      fontSize:
                          12 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveService.getSmallSpacing(context),
                    vertical: ResponsiveService.getTinySpacing(context),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveService.getBorderRadius(context),
                    ),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize:
                          12 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'complete':
                        await service.completeIntervention(intervention['id']);
                        onUpdate?.call();
                        break;
                      case 'reschedule':
                        _showRescheduleDialog(context);
                        break;
                      case 'cancel':
                        await service.cancelIntervention(intervention['id']);
                        onUpdate?.call();
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: ResponsiveService.getIconSize(
                                  context,
                                  baseSize: 20,
                                ),
                              ),
                              SizedBox(
                                width: ResponsiveService.getSmallSpacing(
                                  context,
                                ),
                              ),
                              Text(
                                'Mark Complete',
                                style: TextStyle(
                                  fontSize:
                                      14 *
                                      ResponsiveService.getFontSizeMultiplier(
                                        context,
                                      ),
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
                                size: ResponsiveService.getIconSize(
                                  context,
                                  baseSize: 20,
                                ),
                              ),
                              SizedBox(
                                width: ResponsiveService.getSmallSpacing(
                                  context,
                                ),
                              ),
                              Text(
                                'Reschedule',
                                style: TextStyle(
                                  fontSize:
                                      14 *
                                      ResponsiveService.getFontSizeMultiplier(
                                        context,
                                      ),
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
                                size: ResponsiveService.getIconSize(
                                  context,
                                  baseSize: 20,
                                ),
                              ),
                              SizedBox(
                                width: ResponsiveService.getSmallSpacing(
                                  context,
                                ),
                              ),
                              Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize:
                                      14 *
                                      ResponsiveService.getFontSizeMultiplier(
                                        context,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            Text(
              patientName,
              style: TextStyle(
                fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveService.getTinySpacing(context)),
            Text(
              'Type: ${type.replaceAll('_', ' ').toUpperCase()}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
              ),
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
                  Text(
                    'Scheduled: ${DateFormat('MMM d, h:mm a').format(scheduledAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
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
                  fontSize:
                      14 * ResponsiveService.getFontSizeMultiplier(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context) {
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
              ),
            ),
            content: Text(
              'Reschedule functionality would be implemented here',
              style: TextStyle(
                fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
              ),
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
                  // Implement reschedule logic
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
