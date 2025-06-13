library;

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/services/wearable_data_repository.dart';
import '../../../core/services/wearable_platform_selection_service.dart';
import 'health_permissions_state.dart';
import 'health_permissions_modal.dart';
import '../../../core/models/wearable_platform_option.dart';
import '../../../core/providers/analytics_provider.dart';

/// Platform Chooser Widget
///
/// Displays Apple Health and Health Connect cards side-by-side.
/// Automatically detects platform / Health Connect availability
/// and deep-links users into the appropriate permission flow or
/// installation path.
class PlatformChooserWidget extends ConsumerWidget {
  /// Callback when the user selects a platform. Useful for persisting
  /// selection (handled in upcoming task T2.2.3.3a).
  final void Function(WearablePlatformOption platform)? onPlatformSelected;

  const PlatformChooserWidget({super.key, this.onPlatformSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = WearableDataRepository();

    // Ensure previously selected platform permissions are still valid.
    WearablePlatformSelectionService.instance.ensurePermissions();

    final bool isAppleHealthEnabled = Platform.isIOS;
    final bool isHealthConnectEnabled =
        Platform.isAndroid && repository.isHealthConnectAvailable;

    final cardSpacing = ResponsiveService.getMediumSpacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Health Platform',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: cardSpacing),
        Row(
          children: [
            Expanded(
              child: _PlatformCard(
                title: 'Apple Health',
                icon: CupertinoIcons.heart_fill,
                enabled: isAppleHealthEnabled,
                onTap: () => _handleAppleHealthTap(context, ref),
              ),
            ),
            SizedBox(width: cardSpacing),
            Expanded(
              child: _PlatformCard(
                title: 'Health Connect',
                icon: Icons.health_and_safety,
                enabled: isHealthConnectEnabled,
                onTap:
                    () => _handleHealthConnectTap(
                      context,
                      ref,
                      isHealthConnectEnabled,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleAppleHealthTap(BuildContext context, WidgetRef ref) async {
    if (!Platform.isIOS) return; // Safety guard
    final selectionService = WearablePlatformSelectionService.instance;
    await selectionService.selectPlatform(WearablePlatformOption.appleHealth);

    onPlatformSelected?.call(WearablePlatformOption.appleHealth);

    // Analytics
    await ref
        .read(analyticsServiceProvider)
        .logEvent('platform_selected', params: {'platform': 'apple_health'});

    await showHealthPermissionsModal(
      context,
      onPermissionsGranted: () {
        // Permissions granted callback handled by service.
      },
    );
  }

  void _handleHealthConnectTap(
    BuildContext context,
    WidgetRef ref,
    bool isAvailable,
  ) async {
    if (!Platform.isAndroid) return; // Safety guard

    final selectionService = WearablePlatformSelectionService.instance;
    await selectionService.selectPlatform(WearablePlatformOption.healthConnect);

    onPlatformSelected?.call(WearablePlatformOption.healthConnect);

    // Analytics
    await ref
        .read(analyticsServiceProvider)
        .logEvent('platform_selected', params: {'platform': 'health_connect'});

    if (isAvailable) {
      // ignore: use_build_context_synchronously
      await showHealthPermissionsModal(context, onPermissionsGranted: () {});
    } else {
      // Trigger install / setup flow via existing notifier helper.
      await ref
          .read(healthPermissionsProvider.notifier)
          .openHealthConnectSetup();
    }
  }
}

/// Internal reusable card widget.
class _PlatformCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(
      ResponsiveService.getBorderRadius(context),
    );

    final cardColor = enabled ? Colors.white : Colors.grey[100];
    final borderColor = enabled ? Colors.grey[300] : Colors.grey[200];
    final iconColor = enabled ? Theme.of(context).primaryColor : Colors.grey;
    final textColor = enabled ? Colors.black : Colors.grey;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: borderRadius,
      child: Ink(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: borderRadius,
          border: Border.all(color: borderColor!),
          boxShadow: [
            if (enabled)
              const BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
          ],
        ),
        padding: ResponsiveService.getLargePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: ResponsiveService.getIconSize(context, baseSize: 36),
            ),
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!enabled && Platform.isAndroid && title == 'Health Connect')
              Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveService.getTinySpacing(context),
                ),
                child: Text(
                  'Install Required',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.red[800]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
