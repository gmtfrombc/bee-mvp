import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/services/health_permission_manager.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/models/permission_summary.dart';
import 'package:app/core/providers/permission_summary_provider.dart';

/// Widget that shows overall Health permission status (Granted / Partial /
/// Denied).  Tapping it re-requests any missing permissions when possible or
/// directs the user to Apple Health / Health Connect settings.
///
/// Behaviour:
/// • Displays a green (on) switch when *all* required permissions are granted.
/// • Displays a grey (off) switch when one or more permissions are missing.
/// • Tapping the switch triggers the permission request flow via
///   [HealthPermissionManager.requestPermissions()].
///
/// Note: Permission revocation cannot be performed in-app, so turning the
/// switch *off* simply opens platform settings so the user can manage
/// permissions manually.
class HealthPermissionToggle extends ConsumerWidget {
  const HealthPermissionToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(permissionSummaryProvider);

    return summaryAsync.when(
      data: (summary) => _buildContent(context, summary, ref),
      loading:
          () => const ListTile(
            title: Text('Health Data Permissions'),
            trailing: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(),
            ),
          ),
      error:
          (e, _) => ListTile(
            title: const Text('Health Data Permissions'),
            subtitle: Text('Error: $e'),
            trailing: const Icon(Icons.error, color: Colors.red),
          ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PermissionSummary summary,
    WidgetRef ref,
  ) {
    final mgr = HealthPermissionManager();
    final colorScheme = Theme.of(context).colorScheme;

    Icon icon;
    String subtitle;
    if (summary.isConnected) {
      icon = const Icon(Icons.check_circle, color: AppTheme.momentumRising);
      subtitle = 'Connected';
    } else {
      icon = Icon(Icons.cancel, color: colorScheme.error);
      subtitle = 'Not Connected – tap to enable';
    }

    Future<void> handleTap() async {
      if (summary.isConnected &&
          summary.state == PermissionAggregateState.granted) {
        // Show info dialog – guide user to system settings to revoke.
        await showDialog<void>(
          context: context,
          builder:
              (_) => const AlertDialog(
                title: Text('Manage Permissions'),
                content: Text(
                  'To change health permissions, open the Apple Health app (Sources → Apps) '
                  'or Health Connect on Android.',
                ),
              ),
        );
        return;
      }

      // Re-request missing permissions.
      final snack = ScaffoldMessenger.of(context);
      snack.showSnackBar(
        const SnackBar(content: Text('Requesting permissions…')),
      );

      final resultMap = await mgr.requestPermissions(
        dataTypes: summary.missingTypes,
      );
      final allGranted = resultMap.values.every((g) => g);

      snack.hideCurrentSnackBar();
      snack.showSnackBar(
        SnackBar(
          content: Text(
            allGranted
                ? 'Permissions granted'
                : 'Some permissions still missing',
          ),
        ),
      );
    }

    return ListTile(
      title: Text(
        'Health Data Permissions',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.getTextPrimary(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.getTextSecondary(context),
        ),
      ),
      trailing: icon,
      onTap: handleTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
