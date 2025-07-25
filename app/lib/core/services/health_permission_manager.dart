/// HealthPermissionManager – central service for health data permissions across iOS (HealthKit) & Android (Health Connect).
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart';

import 'wearable_data_models.dart';
import 'wearable_data_repository.dart';
import '../utils/logger.dart';
import '../utils/health_permission_utils.dart';
part 'health_permission_models.dart';

/// Health Permission Manager Service
class HealthPermissionManager {
  static final HealthPermissionManager _instance =
      HealthPermissionManager._internal();
  factory HealthPermissionManager() => _instance;
  HealthPermissionManager._internal();

  final WearableDataRepository _repository = WearableDataRepository();
  final StreamController<List<PermissionDelta>> _deltaStreamController =
      StreamController<List<PermissionDelta>>.broadcast();
  final StreamController<String> _toastStreamController =
      StreamController<String>.broadcast();

  Map<WearableDataType, PermissionCacheEntry> _permissionCache = {};
  PermissionManagerConfig _config = const PermissionManagerConfig();
  bool _isInitialized = false;
  Timer? _periodicCheckTimer;

  // Storage keys
  static const String _cacheKey = 'health_permission_cache';
  static const String _configKey = 'health_permission_config';

  /// Stream of permission changes/deltas
  Stream<List<PermissionDelta>> get deltaStream =>
      _deltaStreamController.stream;

  /// Stream of toast messages for missing permissions
  Stream<String> get toastStream => _toastStreamController.stream;

  /// Current permission cache
  Map<WearableDataType, PermissionCacheEntry> get permissionCache =>
      Map.unmodifiable(_permissionCache);

  /// Configuration
  PermissionManagerConfig get config => _config;

  /// Whether the manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the permission manager
  Future<bool> initialize({PermissionManagerConfig? config}) async {
    // Prevent double-initialisation (might be called by multiple providers)
    if (_isInitialized) return true;

    try {
      if (config != null) {
        _config = config;
      }

      // Bootstrap repo, warm permissions cache & start periodic monitoring
      final repoOk = await _repository.initialize();
      if (!repoOk) {
        logD('Failed to initialize WearableDataRepository');
        return false;
      }

      _isInitialized = true;

      await _loadPermissionCache();
      await _ensurePermissions();
      await _loadConfiguration();
      await _performInitialPermissionCheck();

      _startPeriodicMonitoring();

      logD('HealthPermissionManager initialized successfully');
      return true;
    } catch (e) {
      logD('Failed to initialize HealthPermissionManager: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Update configuration
  Future<void> updateConfig(PermissionManagerConfig config) async {
    _config = config;
    await _saveConfiguration();

    // Restart periodic monitoring with new config
    _startPeriodicMonitoring();
  }

  /// Request permissions for specified data types
  Future<Map<WearableDataType, bool>> requestPermissions({
    List<WearableDataType>? dataTypes,
  }) async {
    if (!_isInitialized) {
      throw StateError('PermissionManager not initialized');
    }

    final typesToRequest = dataTypes ?? _config.requiredPermissions;

    // Batch request optimisation
    try {
      final healthTypes = typesToRequest.map(mapToHealthDataType).toList();
      final accesses = List<HealthDataAccess>.filled(
        healthTypes.length,
        HealthDataAccess.READ,
      );

      logD('Requesting HK types: $healthTypes');

      final batchOk = await _repository.requestPermissionsRaw(
        healthTypes,
        accesses,
      );

      if (batchOk) {
        // Mark all as granted and update cache quickly.
        final now = DateTime.now();
        for (final dt in typesToRequest) {
          _permissionCache[dt] = PermissionCacheEntry(
            dataType: dt,
            isGranted: true,
            lastChecked: now,
            grantedAt: now,
            deniedAt: null,
            denialCount: 0,
          );
        }
        await _savePermissionCache();
        await _checkMissingPermissionsAndNotify();
        return {for (var t in typesToRequest) t: true};
      }
    } catch (e) {
      logD('Batch permission request skipped/fell back: $e');
    }

    final results = <WearableDataType, bool>{};
    final deltas = <PermissionDelta>[];

    for (final dataType in typesToRequest) {
      try {
        // Get current cached status
        final cachedEntry = _permissionCache[dataType];
        final previousStatus = cachedEntry?.isGranted;

        // Request permission for this specific data type
        final status = await _repository.requestPermissions(
          dataTypes: [dataType],
        );
        final isGranted = status == HealthPermissionStatus.authorized;

        if (!isGranted) {
          logD('Permission $dataType denied with status $status');
        }

        // Update cache
        final entry = PermissionCacheEntry(
          dataType: dataType,
          isGranted: isGranted,
          lastChecked: DateTime.now(),
          grantedAt: isGranted ? DateTime.now() : cachedEntry?.grantedAt,
          deniedAt: !isGranted ? DateTime.now() : cachedEntry?.deniedAt,
          denialCount: !isGranted ? (cachedEntry?.denialCount ?? 0) + 1 : 0,
        );

        _permissionCache[dataType] = entry;
        results[dataType] = isGranted;

        // Track delta
        if (previousStatus != isGranted) {
          deltas.add(
            PermissionDelta(
              dataType: dataType,
              previousStatus: previousStatus,
              currentStatus: isGranted,
              timestamp: DateTime.now(),
            ),
          );
        }

        logD('Permission request for $dataType: $isGranted');
      } catch (e) {
        logD('Error requesting permission for $dataType: $e');
        results[dataType] = false;
      }
    }

    // Save updated cache
    await _savePermissionCache();

    // Emit deltas if any
    if (deltas.isNotEmpty) {
      _deltaStreamController.add(deltas);
    }

    // Check for missing permissions and show toasts
    await _checkMissingPermissionsAndNotify();

    return results;
  }

  /// Check current permission status for specified data types
  Future<Map<WearableDataType, bool>> checkPermissions({
    List<WearableDataType>? dataTypes,
    bool useCache = true,
  }) async {
    if (!_isInitialized) {
      throw StateError('PermissionManager not initialized');
    }

    final typesToCheck = dataTypes ?? _config.requiredPermissions;
    final results = <WearableDataType, bool>{};
    final deltas = <PermissionDelta>[];
    final now = DateTime.now();

    for (final dataType in typesToCheck) {
      try {
        final cachedEntry = _permissionCache[dataType];
        bool shouldCheckFresh =
            !useCache ||
            cachedEntry == null ||
            now.difference(cachedEntry.lastChecked) > _config.cacheExpiration;

        bool isGranted;
        if (shouldCheckFresh) {
          // Check fresh from system
          final status = await _repository.checkPermissions(
            dataTypes: [dataType],
          );
          isGranted = status == HealthPermissionStatus.authorized;

          if (!isGranted) {
            logD('Permission $dataType denied with status $status');
          }

          // Update cache
          final entry = PermissionCacheEntry(
            dataType: dataType,
            isGranted: isGranted,
            lastChecked: now,
            grantedAt:
                isGranted
                    ? (cachedEntry?.grantedAt ?? now)
                    : cachedEntry?.grantedAt,
            deniedAt: !isGranted ? now : cachedEntry?.deniedAt,
            denialCount: cachedEntry?.denialCount ?? 0,
          );

          // Track delta if status changed
          if (cachedEntry != null && cachedEntry.isGranted != isGranted) {
            deltas.add(
              PermissionDelta(
                dataType: dataType,
                previousStatus: cachedEntry.isGranted,
                currentStatus: isGranted,
                timestamp: now,
              ),
            );
          }

          _permissionCache[dataType] = entry;
        } else {
          // Use cached value
          isGranted = cachedEntry.isGranted;
        }

        results[dataType] = isGranted;
      } catch (e) {
        logD('Error checking permission for $dataType: $e');
        results[dataType] = false;
      }
    }

    // Save updated cache if we made fresh checks
    if (deltas.isNotEmpty) {
      await _savePermissionCache();
      _deltaStreamController.add(deltas);
    }

    if (kDebugMode) {
      final snapshot = _permissionCache.entries
          .map((e) => '${e.key.name}:${e.value.isGranted}')
          .join(', ');
      logD('checkPermissions final cache → {$snapshot}');
    }

    return results;
  }

  /// Get missing permissions from required list
  Future<List<WearableDataType>> getMissingPermissions() async {
    final permissions = await checkPermissions();
    return permissions.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get permission deltas since last check
  List<PermissionDelta> getRecentDeltas({Duration? since}) {
    // This would typically be stored and retrieved from cache
    // For now, returning empty list as deltas are emitted via stream
    return [];
  }

  /// Surface missing permission toast notification
  Future<void> showMissingPermissionToast(
    String message, {
    Duration? duration,
  }) async {
    _toastStreamController.add(message);
    logD('Permission toast: $message');
  }

  /// Check for missing permissions and notify user
  Future<void> _checkMissingPermissionsAndNotify() async {
    final missingPermissions = await getMissingPermissions();

    if (missingPermissions.isNotEmpty) {
      final message = buildMissingPermissionMessage(missingPermissions);
      await showMissingPermissionToast(message);
    }
  }

  /// Perform initial permission check on startup
  Future<void> _performInitialPermissionCheck() async {
    try {
      await checkPermissions(useCache: false);
      logD('Initial permission check completed');
    } catch (e) {
      logD('Error during initial permission check: $e');
    }
  }

  /// Start periodic permission monitoring
  void _startPeriodicMonitoring() {
    _periodicCheckTimer?.cancel();

    // Check permissions every hour
    _periodicCheckTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        await checkPermissions(useCache: false);
      } catch (e) {
        logD('Error during periodic permission check: $e');
      }
    });
  }

  /// Load permission cache from storage
  Future<void> _loadPermissionCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      if (cacheJson != null) {
        final cacheMap = jsonDecode(cacheJson) as Map<String, dynamic>;
        _permissionCache = cacheMap.map(
          (key, value) => MapEntry(
            WearableDataType.values.firstWhere(
              (e) => e.name == key,
              orElse: () => WearableDataType.unknown,
            ),
            PermissionCacheEntry.fromMap(value as Map<String, dynamic>),
          ),
        );
        logD('Loaded ${_permissionCache.length} cached permissions');
        if (kDebugMode) {
          for (final entry in _permissionCache.entries) {
            logD(
              ' • CACHE LOAD → ${entry.key.name}: granted=${entry.value.isGranted} '
              '| lastChecked=${entry.value.lastChecked.toIso8601String()}',
            );
          }
        }
      }
    } catch (e) {
      logD('Error loading permission cache: $e');
      _permissionCache = {};
    }
  }

  /// Save permission cache to storage
  Future<void> _savePermissionCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheMap = _permissionCache.map(
        (key, value) => MapEntry(key.name, value.toMap()),
      );
      await prefs.setString(_cacheKey, jsonEncode(cacheMap));
      logD('Saved permission cache with ${_permissionCache.length} entries');
      if (kDebugMode) {
        for (final entry in _permissionCache.entries) {
          logD(
            ' • CACHE SAVE ← ${entry.key.name}: granted=${entry.value.isGranted} '
            '| lastChecked=${entry.value.lastChecked.toIso8601String()}',
          );
        }
      }
    } catch (e) {
      logD('Error saving permission cache: $e');
    }
  }

  /// Load configuration from storage
  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);

      if (configJson != null) {
        // Configuration loading would be implemented here
        logD('Configuration loaded from storage');
      }
    } catch (e) {
      logD('Error loading configuration: $e');
    }
  }

  /// Save configuration to storage
  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Configuration saving would be implemented here
      await prefs.setString(_configKey, jsonEncode({}));
      logD('Configuration saved to storage');
    } catch (e) {
      logD('Error saving configuration: $e');
    }
  }

  /// Clear all cached permissions
  Future<void> clearCache() async {
    _permissionCache.clear();
    await _savePermissionCache();
    logD('Permission cache cleared');
  }

  /// Reset permission denial tracking
  void resetDenialTracking() {
    _repository.resetPermissionDenialTracking();
    logD('Permission denial tracking reset');
  }

  /// Re-request any missing permissions at runtime (can be called from Settings screen)
  Future<void> reRequestMissingPermissions() async {
    if (!_isInitialized) return;
    await _ensurePermissions();
  }

  /// Internal helper that checks current permission status and re-requests for any missing types.
  Future<void> _ensurePermissions() async {
    final allTypes = _config.requiredPermissions;
    final healthTypes = allTypes.map(mapToHealthDataType).toList();

    final access = List<HealthDataAccess>.filled(
      healthTypes.length,
      HealthDataAccess.READ,
    );

    bool? current;
    try {
      current = await _repository.hasPermissionsRaw(healthTypes, access);
    } catch (e) {
      logD('Permission pre-check failed: $e');
    }

    final missing = <HealthDataType>[];
    if (current != true) {
      // API returned false or null => at least one permission missing; ask for all
      missing.addAll(healthTypes);
    }

    if (missing.isNotEmpty) {
      logD('Re-requesting missing HK permissions: $missing');
      final ok = await _repository.requestPermissionsRaw(
        missing,
        List<HealthDataAccess>.filled(missing.length, HealthDataAccess.READ),
      );
      logD('Batch permission request result: $ok');
    }
  }

  /// Dispose resources
  void dispose() {
    _periodicCheckTimer?.cancel();
    _deltaStreamController.close();
    _toastStreamController.close();
    logD('HealthPermissionManager disposed');
  }

  // Helper methods migrated to health_permission_utils.dart
}
