/// Android Garmin Beta Warning Widget
///
/// This widget displays warnings to users when Garmin support is not yet
/// enabled on their Android device, implementing the core functionality
/// required by Task T2.2.1.8.
///
/// **Features**:
/// - Detects Health Connect data origin
/// - Shows contextual warnings when Garmin data missing
/// - Provides setup guidance and actions
/// - Respects user preferences and cooldowns
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

import '../../../core/providers/android_garmin_feature_flag_provider.dart';
import '../../../core/services/android_garmin_feature_flag_service.dart';
import '../../../core/services/responsive_service.dart';
import 'garmin_wizard/garmin_enablement_wizard.dart';

/// Main warning widget that conditionally shows Garmin setup warnings
class AndroidGarminBetaWarningWidget extends ConsumerWidget {
  final EdgeInsets? padding;
  final bool showInModal;

  const AndroidGarminBetaWarningWidget({
    super.key,
    this.padding,
    this.showInModal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if service is ready
    final isServiceReady = ref.watch(isGarminServiceReadyProvider);
    if (!isServiceReady) {
      return const SizedBox.shrink();
    }

    // Watch feature state
    final featureState = ref.watch(garminFeatureStateProvider);

    // Only show on Android when feature is enabled
    if (!featureState.shouldShowFeatures) {
      return const SizedBox.shrink();
    }

    // Watch warning recommendation
    final shouldShowWarningAsync = ref.watch(shouldShowGarminWarningProvider);

    return shouldShowWarningAsync.when(
      data: (shouldShow) {
        if (!shouldShow) return const SizedBox.shrink();

        return _buildWarningContent(context, ref, featureState);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildWarningContent(
    BuildContext context,
    WidgetRef ref,
    GarminFeatureState featureState,
  ) {
    if (showInModal) {
      return _buildModalWarning(context, ref, featureState);
    } else {
      return _buildInlineWarning(context, ref, featureState);
    }
  }

  Widget _buildInlineWarning(
    BuildContext context,
    WidgetRef ref,
    GarminFeatureState featureState,
  ) {
    return Container(
      margin: padding ?? ResponsiveService.getMediumPadding(context),
      padding: ResponsiveService.getMediumPadding(context),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: GarminWarningCard(
        featureState: featureState,
        onSetupGarmin: () => _handleSetupGarmin(context, ref),
        onDismiss: () => _handleDismiss(context, ref),
      ),
    );
  }

  Widget _buildModalWarning(
    BuildContext context,
    WidgetRef ref,
    GarminFeatureState featureState,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
      ),
      child: Padding(
        padding: ResponsiveService.getLargePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GarminWarningCard(
              featureState: featureState,
              onSetupGarmin: () => _handleSetupGarmin(context, ref),
              onDismiss: () => _handleDismiss(context, ref),
            ),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _handleOptOut(context, ref),
                  child: const Text('Don\'t show again'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSetupGarmin(BuildContext context, WidgetRef ref) {
    // Record that warning was shown (since user engaged with it)
    final recordWarning = ref.read(recordGarminWarningProvider);
    recordWarning();

    // Show Garmin setup wizard
    showDialog(
      context: context,
      builder: (context) => const GarminEnablementWizard(),
    );
  }

  void _handleDismiss(BuildContext context, WidgetRef ref) {
    // Record warning shown to respect cooldown
    final recordWarning = ref.read(recordGarminWarningProvider);
    recordWarning();

    // If this is a modal, close it
    if (showInModal) {
      Navigator.of(context).pop();
    }
  }

  void _handleOptOut(BuildContext context, WidgetRef ref) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Disable Garmin Warnings'),
            content: const Text(
              'Are you sure you want to disable Garmin setup warnings? '
              'You can re-enable them in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final setOptOut = ref.read(setGarminWarningOptOutProvider);
                  setOptOut(true);
                  Navigator.of(context).pop();
                  if (showInModal) {
                    Navigator.of(context).pop(); // Close warning modal too
                  }
                },
                child: const Text('Disable'),
              ),
            ],
          ),
    );
  }
}

/// Extracted warning card content widget for better separation of concerns
class GarminWarningCard extends StatelessWidget {
  final GarminFeatureState featureState;
  final VoidCallback onSetupGarmin;
  final VoidCallback onDismiss;

  const GarminWarningCard({
    super.key,
    required this.featureState,
    required this.onSetupGarmin,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and title
        Row(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: Colors.orange[700],
              size: ResponsiveService.getIconSize(context, baseSize: 24),
            ),
            SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            Expanded(
              child: Text(
                'Garmin Data Not Detected',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: ResponsiveService.getSmallSpacing(context)),

        // Status message
        Text(
          featureState.statusMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.orange[800],
            height: 1.4,
          ),
        ),

        SizedBox(height: ResponsiveService.getSmallSpacing(context)),

        // Data sources info
        if (featureState.detectedSources.isNotEmpty) ...[
          Text(
            'Detected data sources:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
          SizedBox(height: ResponsiveService.getTinySpacing(context)),
          ...featureState.detectedSources.map(
            (source) => Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                '• $source',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange[700]),
              ),
            ),
          ),
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        ],

        // Action buttons
        Row(
          children: [
            Expanded(child: _buildSetupButton(context)),
            SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            _buildDismissButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildSetupButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onSetupGarmin,
      icon: Icon(
        CupertinoIcons.settings,
        size: ResponsiveService.getIconSize(context, baseSize: 16),
      ),
      label: const Text('Setup Garmin'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        padding: ResponsiveService.getSmallPadding(context),
      ),
    );
  }

  Widget _buildDismissButton(BuildContext context) {
    return IconButton(
      onPressed: onDismiss,
      icon: Icon(
        CupertinoIcons.xmark,
        color: Colors.orange[600],
        size: ResponsiveService.getIconSize(context, baseSize: 20),
      ),
      tooltip: 'Dismiss',
    );
  }
}

/// Status indicator widget showing current Garmin integration status
class GarminStatusIndicatorWidget extends ConsumerWidget {
  final bool compact;

  const GarminStatusIndicatorWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isServiceReady = ref.watch(isGarminServiceReadyProvider);
    if (!isServiceReady) {
      return const SizedBox.shrink();
    }

    final featureState = ref.watch(garminFeatureStateProvider);

    if (!featureState.isPlatformSupported) {
      return const SizedBox.shrink();
    }

    return _buildStatusIndicator(context, featureState);
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    GarminFeatureState featureState,
  ) {
    final (icon, color, text) = _getStatusDisplay(featureState);

    if (compact) {
      return Tooltip(message: text, child: Icon(icon, color: color, size: 16));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _getStatusDisplay(GarminFeatureState featureState) {
    if (!featureState.isEnabled) {
      return (CupertinoIcons.minus_circle, Colors.grey, 'Beta Disabled');
    }

    switch (featureState.status) {
      case GarminDataStatus.available:
        return (
          CupertinoIcons.checkmark_circle,
          Colors.green,
          'Garmin Connected',
        );
      case GarminDataStatus.notDetected:
        return (
          CupertinoIcons.exclamationmark_triangle,
          Colors.orange,
          'Garmin Not Found',
        );
      case GarminDataStatus.noData:
        return (CupertinoIcons.xmark_circle, Colors.red, 'No Health Data');
      case GarminDataStatus.unknown:
        return (CupertinoIcons.question_circle, Colors.grey, 'Status Unknown');
    }
  }
}

/// Debug widget for development/testing
class GarminDebugInfoWidget extends ConsumerWidget {
  const GarminDebugInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugInfo = ref.watch(garminDebugInfoProvider);

    return ExpansionTile(
      title: const Text('Garmin Debug Info'),
      leading: const Icon(CupertinoIcons.info_circle),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...debugInfo.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveService.getSmallSpacing(context)),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final analyze = ref.read(analyzeGarminDataSourceProvider);
                      analyze();
                    },
                    child: const Text('Analyze Data Sources'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final toggle = ref.read(setGarminBetaEnabledProvider);
                      final current = ref.read(garminBetaIsEnabledProvider);
                      toggle(!current);
                    },
                    child: const Text('Toggle Feature'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
