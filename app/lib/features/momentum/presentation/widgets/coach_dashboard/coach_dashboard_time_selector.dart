import 'package:flutter/material.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/theme/app_theme.dart';

/// A responsive time range selector widget for the Coach Dashboard.
///
/// This widget provides a segmented button interface for selecting time ranges
/// (24h, 7d, 30d) with responsive design based on device type. It uses
/// ResponsiveService for consistent spacing and sizing across devices.
///
/// Example usage:
/// ```dart
/// CoachDashboardTimeSelector(
///   selectedTimeRange: '7d',
///   onTimeRangeChanged: (timeRange) {
///     // Handle time range change
///   },
/// )
/// ```
class CoachDashboardTimeSelector extends StatelessWidget {
  const CoachDashboardTimeSelector({
    super.key,
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
  });

  /// The currently selected time range ('24h', '7d', or '30d')
  final String selectedTimeRange;

  /// Callback function called when the time range selection changes
  final ValueChanged<String> onTimeRangeChanged;

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
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
            _buildSegmentedButton(context),
          ],
        ),
      ),
    );
  }

  /// Builds the responsive segmented button for time range selection
  Widget _buildSegmentedButton(BuildContext context) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: '24h',
          label: Text(
            '24h',
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
        ButtonSegment(
          value: '7d',
          label: Text(
            '7d',
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
        ButtonSegment(
          value: '30d',
          label: Text(
            '30d',
            style: TextStyle(
              fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
            ),
          ),
        ),
      ],
      selected: {selectedTimeRange},
      onSelectionChanged: (Set<String> selection) {
        if (selection.isNotEmpty) {
          onTimeRangeChanged(selection.first);
        }
      },
    );
  }
}
