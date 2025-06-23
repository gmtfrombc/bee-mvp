import 'package:app/core/services/health_permission_manager.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:async';

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
  final HealthPermissionManager? manager;
  const HealthPermissionToggle({super.key, this.manager});

  @override
  State<HealthPermissionToggle> createState() => _HealthPermissionToggleState();
}

class _HealthPermissionToggleState extends State<HealthPermissionToggle> {
  bool _permissionsGranted = false;
  bool _isLoading = true;
  late final HealthPermissionManager _manager;
  StreamSubscription<List<PermissionDelta>>? _deltaSub;

  @override
  void initState() {
    super.initState();
    _manager = widget.manager ?? HealthPermissionManager();
    _init();
  }

  Future<void> _init() async {
    // Initialise manager once (noop on subsequent calls).
    if (!_manager.isInitialized) {
      await _manager.initialize();
    }
    await _refreshStatus();

    // Listen for permission deltas to update UI live.
    _deltaSub = _manager.deltaStream.listen((_) => _refreshStatus());
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

  Future<void> _handleTap() async {
    if (!_permissionsGranted) {
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
  void dispose() {
    _deltaSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final icon =
        _permissionsGranted
            ? const Icon(Icons.check_circle, color: AppTheme.momentumRising)
            : Icon(Icons.cancel, color: Theme.of(context).colorScheme.error);

    return ListTile(
      title: Text(
        'Health Data Permissions',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.getTextPrimary(context),
        ),
      ),
      subtitle: Text(
        _permissionsGranted ? 'Granted' : 'Not Granted',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.getTextSecondary(context),
        ),
      ),
      trailing: icon,
      onTap: _handleTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
