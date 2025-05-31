import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/services/coach_intervention_service.dart';

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
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: priorityColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              patientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Type: ${type.replaceAll('_', ' ').toUpperCase()}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (scheduledAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ${DateFormat('MMM d, h:mm a').format(scheduledAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes, style: const TextStyle(fontSize: 14)),
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
            title: const Text('Reschedule Intervention'),
            content: const Text(
              'Reschedule functionality would be implemented here',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Implement reschedule logic
                },
                child: const Text('Reschedule'),
              ),
            ],
          ),
    );
  }
}
