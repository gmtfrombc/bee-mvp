import 'package:flutter/material.dart';
import '../../../../../core/services/responsive_service.dart';

/// A responsive filter bar widget for the Coach Dashboard Active Interventions tab.
///
/// This widget provides dropdown filters for priority and status with responsive
/// design based on device type. It uses ResponsiveService for consistent spacing
/// and sizing across devices.
///
/// Example usage:
/// ```dart
/// CoachDashboardFilterBar(
///   selectedPriority: 'all',
///   selectedStatus: 'all',
///   onPriorityChanged: (priority) {
///     // Handle priority filter change
///   },
///   onStatusChanged: (status) {
///     // Handle status filter change
///   },
/// )
/// ```
class CoachDashboardFilterBar extends StatelessWidget {
  const CoachDashboardFilterBar({
    super.key,
    required this.selectedPriority,
    required this.selectedStatus,
    required this.onPriorityChanged,
    required this.onStatusChanged,
  });

  /// The currently selected priority filter ('all', 'high', 'medium', 'low')
  final String selectedPriority;

  /// The currently selected status filter ('all', 'pending', 'in_progress', 'completed')
  final String selectedStatus;

  /// Callback function called when the priority filter selection changes
  final ValueChanged<String> onPriorityChanged;

  /// Callback function called when the status filter selection changes
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveService.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child:
          ResponsiveService.shouldUseCompactLayout(context)
              ? _buildCompactLayout(context)
              : _buildExpandedLayout(context),
    );
  }

  /// Builds the compact layout for small mobile devices (stacked filters)
  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      children: [
        _buildPriorityDropdown(context),
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        _buildStatusDropdown(context),
      ],
    );
  }

  /// Builds the expanded layout for larger devices (side-by-side filters)
  Widget _buildExpandedLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildPriorityDropdown(context)),
        SizedBox(width: ResponsiveService.getResponsiveSpacing(context)),
        Expanded(child: _buildStatusDropdown(context)),
      ],
    );
  }

  /// Builds the responsive priority dropdown filter
  Widget _buildPriorityDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedPriority,
      decoration: InputDecoration(
        labelText: 'Priority',
        labelStyle: TextStyle(
          fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
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
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 'high',
          child: Text(
            'High',
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 'medium',
          child: Text(
            'Medium',
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 'low',
          child: Text(
            'Low',
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          onPriorityChanged(value);
        }
      },
    );
  }

  /// Builds the responsive status dropdown filter
  Widget _buildStatusDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: TextStyle(
          fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
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
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 'pending',
          child: Text(
            'Pending',
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 'in_progress',
          child: Text(
            'In Progress',
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 'completed',
          child: Text(
            'Completed',
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          onStatusChanged(value);
        }
      },
    );
  }
}
