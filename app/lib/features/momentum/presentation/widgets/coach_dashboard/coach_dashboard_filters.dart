import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';

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
      padding: ResponsiveService.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildTimeRangeSelector(context),
          if (showPriorityFilter || showStatusFilter) ...[
            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
            _buildFilterRow(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.date_range,
          color: AppTheme.momentumRising,
          size: ResponsiveService.getIconSize(context),
        ),
        SizedBox(width: ResponsiveService.getMediumSpacing(context)),
        Text(
          'Time Range:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
          ),
        ),
        SizedBox(width: ResponsiveService.getResponsiveSpacing(context)),
        Expanded(
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: '24h',
                label: Text(
                  '24h',
                  style: TextStyle(
                    fontSize:
                        14 * ResponsiveService.getFontSizeMultiplier(context),
                  ),
                ),
              ),
              ButtonSegment(
                value: '7d',
                label: Text(
                  '7d',
                  style: TextStyle(
                    fontSize:
                        14 * ResponsiveService.getFontSizeMultiplier(context),
                  ),
                ),
              ),
              ButtonSegment(
                value: '30d',
                label: Text(
                  '30d',
                  style: TextStyle(
                    fontSize:
                        14 * ResponsiveService.getFontSizeMultiplier(context),
                  ),
                ),
              ),
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

  Widget _buildFilterRow(BuildContext context) {
    return Row(
      children: [
        if (showPriorityFilter) ...[
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedPriority,
              decoration: InputDecoration(
                labelText: 'Priority',
                labelStyle: TextStyle(
                  fontSize:
                      14 * ResponsiveService.getFontSizeMultiplier(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveService.getBorderRadius(context),
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveService.getMediumSpacing(context),
                  vertical: ResponsiveService.getSmallSpacing(context),
                ),
              ),
              style: TextStyle(
                fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.black87,
              ),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(
                    'All Priorities',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'high',
                  child: Text(
                    'High',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'medium',
                  child: Text(
                    'Medium',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'low',
                  child: Text(
                    'Low',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ),
              ],
              onChanged: (value) => onPriorityChanged?.call(value!),
            ),
          ),
          if (showStatusFilter)
            SizedBox(width: ResponsiveService.getResponsiveSpacing(context)),
        ],
        if (showStatusFilter) ...[
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: TextStyle(
                  fontSize:
                      14 * ResponsiveService.getFontSizeMultiplier(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveService.getBorderRadius(context),
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveService.getMediumSpacing(context),
                  vertical: ResponsiveService.getSmallSpacing(context),
                ),
              ),
              style: TextStyle(
                fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.black87,
              ),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(
                    'All Statuses',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'pending',
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text(
                    'In Progress',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      fontSize:
                          14 * ResponsiveService.getFontSizeMultiplier(context),
                    ),
                  ),
                ),
              ],
              onChanged: (value) => onStatusChanged?.call(value!),
            ),
          ),
        ],
      ],
    );
  }
}
