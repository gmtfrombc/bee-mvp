/// Health Permissions Platform-Specific Widgets
///
/// This file contains platform-specific UI widgets for health permissions,
/// including Health Connect installation prompts and settings guidance.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/services/wearable_data_models.dart';
import 'health_permissions_state.dart';

/// Widget for Health Connect installation prompt (Android only)
class HealthConnectInstallPromptWidget extends StatelessWidget {
  final VoidCallback onInstall;
  final VoidCallback onSkip;
  final HealthConnectAvailabilityResult? availabilityResult;

  const HealthConnectInstallPromptWidget({
    super.key,
    required this.onInstall,
    required this.onSkip,
    this.availabilityResult,
  });

  @override
  Widget build(BuildContext context) {
    final result = availabilityResult;
    final title = _getTitle(result);
    final message =
        result?.userMessage ??
        'Health Connect is required to access health data on Android. It\'s a secure, centralized platform for managing health and fitness data.';
    final buttonText = result?.actionText ?? 'Install Health Connect';
    final canResolve = result?.canResolve ?? true;

    return Container(
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
          Row(
            children: [
              Icon(_getIcon(result), color: Colors.orange[700], size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.orange[800],
              height: 1.4,
            ),
          ),
          if (result?.unavailabilityReason ==
              HealthConnectUnavailabilityReason.deviceNotSupported) ...[
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This device does not support Health Connect. Please use a device with Android 9+ or consider alternative health data sources.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.red[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
          Row(
            children: [
              if (canResolve) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onInstall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(_getButtonIcon(result), size: 20),
                    label: Text(buttonText),
                  ),
                ),
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              ] else ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Health Connect is not supported on this device',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              ],
              TextButton(
                onPressed: onSkip,
                child: Text(
                  canResolve ? 'Skip' : 'Continue',
                  style: TextStyle(color: Colors.orange[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTitle(HealthConnectAvailabilityResult? result) {
    switch (result?.unavailabilityReason) {
      case HealthConnectUnavailabilityReason.notInstalled:
        return 'Health Connect Required';
      case HealthConnectUnavailabilityReason.deviceNotSupported:
        return 'Device Not Supported';
      case HealthConnectUnavailabilityReason.outdatedVersion:
        return 'Health Connect Update Required';
      default:
        return 'Health Connect Required';
    }
  }

  IconData _getIcon(HealthConnectAvailabilityResult? result) {
    switch (result?.unavailabilityReason) {
      case HealthConnectUnavailabilityReason.deviceNotSupported:
        return Icons.error_outline;
      case HealthConnectUnavailabilityReason.outdatedVersion:
        return Icons.update;
      default:
        return Icons.download_outlined;
    }
  }

  IconData _getButtonIcon(HealthConnectAvailabilityResult? result) {
    switch (result?.unavailabilityReason) {
      case HealthConnectUnavailabilityReason.outdatedVersion:
        return Icons.update;
      default:
        return Icons.download;
    }
  }
}

/// Widget for settings prompt when permissions are denied
class HealthPermissionsSettingsPromptWidget extends StatelessWidget {
  final HealthPermissionsState state;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  const HealthPermissionsSettingsPromptWidget({
    super.key,
    required this.state,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  String _getInstructionText(HealthPermissionsState state) {
    // Check if we have detailed instructions in the error message
    if (state.errorMessage != null &&
        state.errorMessage!.contains('To enable health permissions:')) {
      return state.errorMessage!;
    }

    // Default instructions based on permanent denial status
    if (state.isPermanentlyDenied) {
      return 'Health permissions have been permanently denied. To enable health data access, please go to Settings and grant the necessary permissions.';
    } else {
      return 'To enable health data access, please go to Settings and grant the necessary permissions.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle_fill,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                state.isPermanentlyDenied
                    ? 'Permissions Permanently Denied'
                    : 'Permissions Needed',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getInstructionText(state),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
          ),
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onOpenSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Open Settings'),
                ),
              ),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  'Dismiss',
                  style: TextStyle(color: Colors.orange[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget for main action buttons
class HealthPermissionsButtonsWidget extends StatelessWidget {
  final HealthPermissionsState state;
  final VoidCallback onGrantPermissions;
  final VoidCallback onSkip;

  const HealthPermissionsButtonsWidget({
    super.key,
    required this.state,
    required this.onGrantPermissions,
    required this.onSkip,
  });

  String _getButtonText() {
    if (state.isPermanentlyDenied) {
      return 'Open Settings';
    }
    if (Platform.isAndroid && state.status == HealthPermissionStatus.denied) {
      return 'Try Again';
    }
    return 'Grant Health Permissions';
  }

  @override
  Widget build(BuildContext context) {
    if (state.showHealthConnectInstallPrompt) {
      return const SizedBox.shrink(); // Buttons are in the install prompt
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: state.isLoading ? null : onGrantPermissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveService.getBorderRadius(context),
                ),
              ),
            ),
            child:
                state.isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text(
                      _getButtonText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: TextButton(
            onPressed: state.isLoading ? null : onSkip,
            child: Text(
              'Skip for Now',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }
}
