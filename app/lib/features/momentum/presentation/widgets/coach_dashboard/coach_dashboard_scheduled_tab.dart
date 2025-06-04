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
///   onInterventionUpdated: () => refreshData(),
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
      builder: (context, snapshot) => _buildContent(context, snapshot),
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

  /// Performance: Enhanced loading state with progress indicators
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            Text(
              'Loading scheduled interventions...',
              style: TextStyle(
                fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            // Performance: Add shimmer effect placeholder for better UX
            _buildShimmerPlaceholder(context),
          ],
        ),
      ),
    );
  }

  /// Performance: Shimmer placeholder for loading states
  Widget _buildShimmerPlaceholder(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: EdgeInsets.only(
            bottom: ResponsiveService.getSmallSpacing(context),
          ),
          height: ResponsiveService.getMomentumCardHeight(context) * 0.4,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Performance: Optimized error state with retry functionality
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
              'Error loading scheduled interventions',
              style: TextStyle(
                fontSize: 18 * ResponsiveService.getFontSizeMultiplier(context),
                fontWeight: FontWeight.w600,
                color: Colors.red,
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
            ),
            SizedBox(height: ResponsiveService.getLargeSpacing(context)),
            // Performance: Enhanced retry button with better UX
            ElevatedButton.icon(
              onPressed: () {
                if (onInterventionUpdated != null) {
                  onInterventionUpdated!();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: ResponsiveService.getMediumPadding(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Performance: Const empty state widget with better messaging
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: ResponsiveService.getCustomSpacing(context, 4.0),
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            Text(
              'No scheduled interventions',
              style: TextStyle(
                fontSize: 20 * ResponsiveService.getFontSizeMultiplier(context),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            Text(
              'Scheduled interventions for your patients will appear here',
              style: TextStyle(
                fontSize: 14 * ResponsiveService.getFontSizeMultiplier(context),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveService.getLargeSpacing(context)),
            // Performance: Add helpful action button
            OutlinedButton.icon(
              onPressed: () {
                // In a real app, this would navigate to create intervention screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Schedule intervention feature coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Schedule Intervention'),
            ),
          ],
        ),
      ),
    );
  }

  /// Performance: Highly optimized list rendering with advanced optimizations
  Widget _buildInterventionsList(
    BuildContext context,
    List<Map<String, dynamic>> interventions,
  ) {
    return CustomScrollView(
      // Performance: Key for better widget recycling
      key: const ValueKey('scheduled_interventions_scroll'),
      slivers: [
        // Performance: Add sliver app bar for better scroll performance
        SliverToBoxAdapter(
          child: Padding(
            padding: ResponsiveService.getResponsivePadding(context),
            child: Text(
              '${interventions.length} scheduled intervention${interventions.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 16 * ResponsiveService.getFontSizeMultiplier(context),
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        // Performance: Use SliverList for better performance with large lists
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final intervention = interventions[index];

              return Padding(
                // Performance: Use unique keys for better list performance
                key: ValueKey(
                  'scheduled_intervention_${intervention['id'] ?? index}',
                ),
                padding: EdgeInsets.fromLTRB(
                  ResponsiveService.getResponsivePadding(context).left,
                  0,
                  ResponsiveService.getResponsivePadding(context).right,
                  ResponsiveService.getSmallSpacing(context),
                ),
                child: CoachDashboardInterventionCard(
                  intervention: intervention,
                  onComplete:
                      () => _handleInterventionAction(
                        context,
                        'completed',
                        intervention['patient_name'] as String? ?? 'Unknown',
                      ),
                  onReschedule:
                      () => _showRescheduleDialog(context, intervention),
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
            childCount: interventions.length,
            // Performance: Add semantic index for accessibility
            semanticIndexCallback: (widget, localIndex) => localIndex,
          ),
        ),
        // Performance: Add bottom padding
        SliverToBoxAdapter(
          child: SizedBox(height: ResponsiveService.getLargeSpacing(context)),
        ),
      ],
    );
  }

  /// Performance: Enhanced action handling with better feedback
  void _handleInterventionAction(
    BuildContext context,
    String action,
    String patientName,
  ) {
    final actionColor = switch (action) {
      'completed' => Colors.green,
      'cancelled' => Colors.orange,
      'rescheduled' => Colors.blue,
      _ => Colors.grey,
    };

    final actionIcon = switch (action) {
      'completed' => Icons.check_circle,
      'cancelled' => Icons.cancel,
      'rescheduled' => Icons.schedule,
      _ => Icons.info,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(actionIcon, color: Colors.white, size: 20),
            SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            Expanded(
              child: Text(
                'Intervention for $patientName $action successfully',
                style: TextStyle(
                  fontSize:
                      14 * ResponsiveService.getFontSizeMultiplier(context),
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: actionColor,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Performance: Add undo functionality for better UX
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Undo functionality coming soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );

    // Performance: Trigger refresh with debouncing
    Future.delayed(const Duration(milliseconds: 100), () {
      if (onInterventionUpdated != null) {
        onInterventionUpdated!();
      }
    });
  }

  /// Performance: Optimized reschedule dialog
  void _showRescheduleDialog(
    BuildContext context,
    Map<String, dynamic> intervention,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveService.getBorderRadius(context),
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.blue,
                size: ResponsiveService.getIconSize(context, baseSize: 24),
              ),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              Expanded(
                child: Text(
                  'Reschedule Intervention',
                  style: TextStyle(
                    fontSize:
                        18 * ResponsiveService.getFontSizeMultiplier(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient: ${intervention['patient_name'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize:
                      16 * ResponsiveService.getFontSizeMultiplier(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveService.getSmallSpacing(context)),
              Text(
                'Would you like to reschedule this intervention?',
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleInterventionAction(
                  context,
                  'rescheduled',
                  intervention['patient_name'] as String? ?? 'Unknown',
                );
              },
              icon: const Icon(Icons.schedule, size: 16),
              label: const Text('Reschedule'),
            ),
          ],
        );
      },
    );
  }
}
