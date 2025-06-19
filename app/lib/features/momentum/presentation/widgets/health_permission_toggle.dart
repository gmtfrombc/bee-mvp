import 'package:app/core/services/health_permission_manager.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Toggle widget that shows overall Health permission status and lets
/// the user request authorization again if permissions have been revoked.
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
class HealthPermissionToggle extends StatefulWidget {
  const HealthPermissionToggle({super.key});

  @override
  State<HealthPermissionToggle> createState() => _HealthPermissionToggleState();
}

class _HealthPermissionToggleState extends State<HealthPermissionToggle> {
  bool _permissionsGranted = false;
  bool _isLoading = true;
  final HealthPermissionManager _manager = HealthPermissionManager();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Initialise manager once (noop on subsequent calls).
    if (!_manager.isInitialized) {
      await _manager.initialize();
    }
    await _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final required = _manager.config.requiredPermissions;
    final granted = required.every((type) {
      final entry = _manager.permissionCache[type];
      return entry?.isGranted ?? false;
    });
    setState(() {
      _permissionsGranted = granted;
      _isLoading = false;
    });
  }

  Future<void> _handleToggle(bool value) async {
    if (value) {
      // Request permissions again
      setState(() => _isLoading = true);
      final results = await _manager.requestPermissions();
      final granted = results.values.every((v) => v);
      setState(() {
        _permissionsGranted = granted;
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Health permissions granted'
                : 'Some permissions are still missing',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Cannot revoke via API – guide user to system settings
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Manage Permissions'),
              content: const Text(
                'To revoke health data access, please use the Health app (iOS) or '
                'Health Connect settings (Android).',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SwitchListTile(
      title: Text(
        'Health Data Permissions',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.getTextPrimary(context),
        ),
      ),
      subtitle: Text(
        _permissionsGranted
            ? 'All required permissions granted'
            : 'Permissions missing – tap to grant access',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.getTextSecondary(context),
        ),
      ),
      value: _permissionsGranted,
      onChanged: _handleToggle,
      activeColor: AppTheme.momentumRising,
      contentPadding: EdgeInsets.zero,
    );
  }
}
