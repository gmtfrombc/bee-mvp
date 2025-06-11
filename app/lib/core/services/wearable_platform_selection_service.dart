import 'package:hive_flutter/hive_flutter.dart';

import 'wearable_data_repository.dart';
import '../models/wearable_platform_option.dart';
import 'health_permission_manager.dart';

/// Service responsible for storing the user-selected health platform
/// (Apple Health or Health Connect) and re-triggering permission setup
/// whenever necessary.
class WearablePlatformSelectionService {
  static const String _boxName = 'wearable_prefs';
  static const String _platformKey = 'selected_platform';
  static WearablePlatformSelectionService? _instance;

  Box<String>? _box;
  bool _isInitialized = false;

  WearablePlatformSelectionService._();

  static WearablePlatformSelectionService get instance =>
      _instance ??= WearablePlatformSelectionService._();

  Future<void> initialize() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    _isInitialized = true;
  }

  /// Save the chosen platform and immediately kick off setup.
  Future<void> selectPlatform(WearablePlatformOption platform) async {
    await initialize();
    await _box!.put(_platformKey, platform.name);
    await _performSetup(platform);
  }

  /// Currently saved platform (null if not chosen yet).
  WearablePlatformOption? get selectedPlatform {
    if (!_isInitialized) return null;
    final raw = _box!.get(_platformKey);
    if (raw == null) return null;
    try {
      return WearablePlatformOption.values.byName(raw);
    } catch (_) {
      return null;
    }
  }

  /// Ensure permissions are still granted; if not, start re-auth flow.
  Future<void> ensurePermissions() async {
    await initialize();
    final platform = selectedPlatform;
    if (platform == null) return;

    final permissionManager = HealthPermissionManager();
    if (!permissionManager.isInitialized) {
      await permissionManager.initialize();
    }

    final missing =
        permissionManager.permissionCache.values
            .where((e) => !e.isGranted)
            .toList();
    if (missing.isNotEmpty) {
      // trigger request for the missing permissions only
      await permissionManager.requestPermissions(
        dataTypes: missing.map((e) => e.dataType).toList(),
      );
    }
  }

  Future<void> _performSetup(WearablePlatformOption platform) async {
    // Initialize repository and request baseline permissions for key metrics.
    final repository = WearableDataRepository();
    await repository.initialize();

    final permissionManager = HealthPermissionManager();
    if (!permissionManager.isInitialized) {
      await permissionManager.initialize();
    }
    await permissionManager.requestPermissions();
  }
}
