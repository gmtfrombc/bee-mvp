/// Android Permission Guidance Widget
///
/// Provides detailed step-by-step guidance for Android users when health
/// permissions have been permanently denied, helping them navigate to the
/// correct settings to re-enable permissions.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../core/services/responsive_service.dart';
import 'health_permissions_state.dart';

/// Widget that provides detailed Android permission guidance
class AndroidPermissionGuidanceWidget extends StatelessWidget {
  final HealthPermissionsState state;
  final VoidCallback onTryOpenSettings;
  final VoidCallback onDismiss;
  final bool? forceShow; // For testing purposes

  const AndroidPermissionGuidanceWidget({
    super.key,
    required this.state,
    required this.onTryOpenSettings,
    required this.onDismiss,
    this.forceShow,
  });

  @override
  Widget build(BuildContext context) {
    if (forceShow != true &&
        (!Platform.isAndroid || !state.isPermanentlyDenied)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: ResponsiveService.getMediumPadding(context),
      padding: ResponsiveService.getMediumPadding(context),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
          _buildGuidanceSteps(context),
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.exclamationmark_triangle_fill,
          color: Colors.orange[700],
          size: 24,
        ),
        SizedBox(width: ResponsiveService.getSmallSpacing(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permissions Permanently Denied',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manual setup required to enable health data access',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidanceSteps(BuildContext context) {
    final isHealthConnectAvailable = state.isHealthConnectAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow these steps to enable permissions:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[800],
          ),
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        if (isHealthConnectAvailable)
          ..._buildHealthConnectSteps(context)
        else
          ..._buildFallbackSteps(context),
      ],
    );
  }

  List<Widget> _buildHealthConnectSteps(BuildContext context) {
    return [
      _buildStep(
        context,
        '1',
        'Open Health Connect app',
        'Tap the button below or find Health Connect in your apps',
      ),
      _buildStep(
        context,
        '2',
        'Find BEE-MVP app',
        'Look for our app in the "Connected apps" list',
      ),
      _buildStep(
        context,
        '3',
        'Enable permissions',
        'Turn on: Steps, Heart Rate, Sleep, and Active Energy',
      ),
      _buildStep(
        context,
        '4',
        'Return to our app',
        'Come back and tap "Try Again" to continue',
      ),
      SizedBox(height: ResponsiveService.getSmallSpacing(context)),
      Container(
        padding: ResponsiveService.getSmallPadding(context),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.info_circle, color: Colors.blue[700], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'If Health Connect settings don\'t open, use: Settings > Apps > Health Connect > Connected apps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue[800],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildFallbackSteps(BuildContext context) {
    return [
      _buildStep(
        context,
        '1',
        'Open device Settings',
        'Go to your Android device Settings app',
      ),
      _buildStep(
        context,
        '2',
        'Find Apps section',
        'Look for "Apps" or "Application Manager"',
      ),
      _buildStep(
        context,
        '3',
        'Select BEE-MVP',
        'Find and tap on our app in the list',
      ),
      _buildStep(
        context,
        '4',
        'Open Permissions',
        'Tap on "Permissions" to see available options',
      ),
      _buildStep(
        context,
        '5',
        'Enable health permissions',
        'Turn on all health-related permissions',
      ),
      SizedBox(height: ResponsiveService.getSmallSpacing(context)),
      Container(
        padding: ResponsiveService.getSmallPadding(context),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber[200]!),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.lightbulb, color: Colors.amber[700], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Consider installing Health Connect from Play Store for better health data integration',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.amber[800],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildStep(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveService.getSmallSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.orange[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onTryOpenSettings,
            icon: const Icon(CupertinoIcons.settings, size: 18),
            label: Text(
              state.isHealthConnectAvailable
                  ? 'Open Health Connect'
                  : 'Open Settings',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: ResponsiveService.getSmallSpacing(context)),
        TextButton(
          onPressed: onDismiss,
          child: Text('Dismiss', style: TextStyle(color: Colors.orange[700])),
        ),
      ],
    );
  }
}
