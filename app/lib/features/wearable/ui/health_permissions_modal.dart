/// Health Permissions Modal UI
///
/// This modal provides a user-friendly interface for requesting health data
/// permissions on both iOS (HealthKit) and Android (Health Connect), with clear
/// explanations of why each permission is needed and platform-specific handling
/// for different scenarios including Health Connect availability and permission denial.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/services/wearable_data_models.dart';
import 'health_permissions_state.dart';
import 'health_permissions_components.dart';
import 'health_permissions_platform_widgets.dart';
import 'android_permission_guidance_widget.dart';

/// Health Permissions Modal Widget
class HealthPermissionsModal extends ConsumerStatefulWidget {
  final VoidCallback? onPermissionsGranted;
  final VoidCallback? onSkipped;

  const HealthPermissionsModal({
    super.key,
    this.onPermissionsGranted,
    this.onSkipped,
  });

  @override
  ConsumerState<HealthPermissionsModal> createState() =>
      _HealthPermissionsModalState();
}

class _HealthPermissionsModalState
    extends ConsumerState<HealthPermissionsModal> {
  @override
  void initState() {
    super.initState();
    // Initialize permissions check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthPermissionsProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthPermissionsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveService.getBorderRadius(context)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandleBar(context),
          Flexible(
            child: SingleChildScrollView(
              padding: ResponsiveService.getLargePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HealthPermissionsHeaderWidget(),
                  SizedBox(height: ResponsiveService.getLargeSpacing(context)),
                  _buildContent(context, state),
                  if (state.errorMessage != null) ...[
                    SizedBox(
                      height: ResponsiveService.getMediumSpacing(context),
                    ),
                    HealthPermissionsErrorWidget(message: state.errorMessage!),
                  ],
                  SizedBox(height: ResponsiveService.getLargeSpacing(context)),
                  _buildActions(context, state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandleBar(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: EdgeInsets.only(
        top: ResponsiveService.getSmallSpacing(context),
        bottom: ResponsiveService.getMediumSpacing(context),
      ),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HealthPermissionsState state) {
    // Platform-specific content based on state
    if (Platform.isAndroid && state.showHealthConnectInstallPrompt) {
      return HealthConnectInstallPromptWidget(
        onInstall: _handleOpenHealthConnectSetup,
        onSkip: _handleDismissHealthConnectPrompt,
        availabilityResult: state.healthConnectAvailability,
      );
    }

    // Show detailed guidance for Android permanent permission denial
    if (Platform.isAndroid && state.isPermanentlyDenied) {
      return AndroidPermissionGuidanceWidget(
        state: state,
        onTryOpenSettings: _handleOpenSettings,
        onDismiss: _handleDismissSettings,
      );
    }

    if (state.showSettingsPrompt) {
      return HealthPermissionsSettingsPromptWidget(
        state: state,
        onOpenSettings: _handleOpenSettings,
        onDismiss: _handleDismissSettings,
      );
    }

    // Normal permissions flow
    return Column(
      children: [
        const HealthPermissionsListWidget(),
        SizedBox(height: ResponsiveService.getLargeSpacing(context)),
        if (Platform.isAndroid) const AndroidHealthConnectInfoWidget(),
      ],
    );
  }

  Widget _buildActions(BuildContext context, HealthPermissionsState state) {
    return HealthPermissionsButtonsWidget(
      state: state,
      onGrantPermissions: _handleGrantPermissions,
      onSkip: _handleSkip,
    );
  }

  // Event handlers
  void _handleGrantPermissions() async {
    final state = ref.read(healthPermissionsProvider);

    if (state.isPermanentlyDenied) {
      await ref.read(healthPermissionsProvider.notifier).openSettings();
      return;
    }

    if (Platform.isAndroid &&
        state.status == HealthPermissionStatus.denied &&
        !state.isPermanentlyDenied) {
      // Android retry case
      await ref.read(healthPermissionsProvider.notifier).retryPermissions();
    } else {
      await ref.read(healthPermissionsProvider.notifier).requestPermissions();
    }

    final newState = ref.read(healthPermissionsProvider);

    if (newState.status == HealthPermissionStatus.authorized) {
      widget.onPermissionsGranted?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleSkip() {
    widget.onSkipped?.call();
    Navigator.of(context).pop();
  }

  void _handleOpenSettings() async {
    await ref.read(healthPermissionsProvider.notifier).openSettings();
  }

  void _handleDismissSettings() {
    ref.read(healthPermissionsProvider.notifier).dismissSettingsPrompt();
  }

  void _handleOpenHealthConnectSetup() async {
    await ref.read(healthPermissionsProvider.notifier).openHealthConnectSetup();
  }

  void _handleDismissHealthConnectPrompt() {
    ref
        .read(healthPermissionsProvider.notifier)
        .dismissHealthConnectInstallPrompt();
  }
}

/// Helper function to show the health permissions modal
Future<void> showHealthPermissionsModal(
  BuildContext context, {
  VoidCallback? onPermissionsGranted,
  VoidCallback? onSkipped,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: HealthPermissionsModal(
            onPermissionsGranted: onPermissionsGranted,
            onSkipped: onSkipped,
          ),
        ),
  );
}
