import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class CoachDashboardFilters extends StatelessWidget {
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;
  final String? selectedPriority;
  final String? selectedStatus;
  final Function(String)? onPriorityChanged;
  final Function(String)? onStatusChanged;
  final bool showPriorityFilter;
  final bool showStatusFilter;

  const CoachDashboardFilters({
    super.key,
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
    this.selectedPriority,
    this.selectedStatus,
    this.onPriorityChanged,
    this.onStatusChanged,
    this.showPriorityFilter = false,
    this.showStatusFilter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildTimeRangeSelector(),
          if (showPriorityFilter || showStatusFilter) ...[
            const SizedBox(height: 16),
            _buildFilterRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Row(
      children: [
        const Icon(Icons.date_range, color: AppTheme.momentumRising),
        const SizedBox(width: 12),
        const Text(
          'Time Range:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '24h', label: Text('24h')),
              ButtonSegment(value: '7d', label: Text('7d')),
              ButtonSegment(value: '30d', label: Text('30d')),
            ],
            selected: {selectedTimeRange},
            onSelectionChanged: (Set<String> selection) {
              onTimeRangeChanged(selection.first);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        if (showPriorityFilter) ...[
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
              ],
              onChanged: (value) => onPriorityChanged?.call(value!),
            ),
          ),
          if (showStatusFilter) const SizedBox(width: 16),
        ],
        if (showStatusFilter) ...[
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('In Progress'),
                ),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (value) => onStatusChanged?.call(value!),
            ),
          ),
        ],
      ],
    );
  }
}
