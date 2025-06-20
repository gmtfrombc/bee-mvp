/// Health Permission Manager Service
///
/// This service manages health data permissions, caches granted permissions,
/// tracks permission deltas, and provides UI notifications for missing permissions.
/// Supports both iOS HealthKit and Android Health Connect permission flows.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'wearable_data_models.dart';
import 'wearable_data_repository.dart';

/// Permission cache entry with metadata
class PermissionCacheEntry {
  final WearableDataType dataType;
  final bool isGranted;
  final DateTime lastChecked;
  final DateTime? grantedAt;
  final DateTime? deniedAt;
  final int denialCount;

  const PermissionCacheEntry({
    required this.dataType,
    required this.isGranted,
    required this.lastChecked,
    this.grantedAt,
    this.deniedAt,
    this.denialCount = 0,
  });

  PermissionCacheEntry copyWith({
    WearableDataType? dataType,
    bool? isGranted,
    DateTime? lastChecked,
    DateTime? grantedAt,
    DateTime? deniedAt,
    int? denialCount,
  }) {
    return PermissionCacheEntry(
      dataType: dataType ?? this.dataType,
      isGranted: isGranted ?? this.isGranted,
      lastChecked: lastChecked ?? this.lastChecked,
      grantedAt: grantedAt ?? this.grantedAt,
      deniedAt: deniedAt ?? this.deniedAt,
      denialCount: denialCount ?? this.denialCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dataType': dataType.name,
      'isGranted': isGranted,
      'lastChecked': lastChecked.toIso8601String(),
      'grantedAt': grantedAt?.toIso8601String(),
      'deniedAt': deniedAt?.toIso8601String(),
      'denialCount': denialCount,
    };
  }

  factory PermissionCacheEntry.fromMap(Map<String, dynamic> map) {
    return PermissionCacheEntry(
      dataType: WearableDataType.values.firstWhere(
        (e) => e.name == map['dataType'],
        orElse: () => WearableDataType.unknown,
      ),
      isGranted: map['isGranted'] ?? false,
      lastChecked: DateTime.parse(map['lastChecked']),
      grantedAt:
          map['grantedAt'] != null ? DateTime.parse(map['grantedAt']) : null,
      deniedAt:
          map['deniedAt'] != null ? DateTime.parse(map['deniedAt']) : null,
      denialCount: map['denialCount'] ?? 0,
    );
  }
}

/// Permission delta representing changes in permission status
class PermissionDelta {
  final WearableDataType dataType;
  final bool? previousStatus;
  final bool currentStatus;
  final DateTime timestamp;

  const PermissionDelta({
    required this.dataType,
    this.previousStatus,
    required this.currentStatus,
    required this.timestamp,
  });

  bool get isNewlyGranted => previousStatus == false && currentStatus == true;
  bool get isNewlyDenied => previousStatus == true && currentStatus == false;
  bool get isFirstTimeChecked => previousStatus == null;

  @override
  String toString() {
    return 'PermissionDelta(dataType: $dataType, previousStatus: $previousStatus, currentStatus: $currentStatus, timestamp: $timestamp)';
  }
}

/// Configuration for permission manager
class PermissionManagerConfig {
  final Duration cacheExpiration;
  final Duration toastDisplayDuration;
  final bool enableAutoRetry;
  final int maxRetryAttempts;
  final List<WearableDataType> requiredPermissions;

  const PermissionManagerConfig({
    this.cacheExpiration = const Duration(hours: 24),
    this.toastDisplayDuration = const Duration(seconds: 4),
    this.enableAutoRetry = true,
    this.maxRetryAttempts = 3,
    this.requiredPermissions = const [
      WearableDataType.steps,
      WearableDataType.heartRate,
      WearableDataType.sleepDuration,
      WearableDataType.activeEnergyBurned,
      WearableDataType.heartRateVariability,
      WearableDataType.weight,
    ],
  });
}

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
    try {
      if (config != null) {
        _config = config;
      }

      // Initialize the wearable data repository
      final repositoryInitialized = await _repository.initialize();
      if (!repositoryInitialized) {
        debugPrint('Failed to initialize WearableDataRepository');
        return false;
      }

      // Load cached permissions
      await _loadPermissionCache();

      // Load configuration
      await _loadConfiguration();

      // Perform initial permission check
      await _performInitialPermissionCheck();

      // Start periodic permission monitoring
      _startPeriodicMonitoring();

      _isInitialized = true;
      debugPrint('HealthPermissionManager initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize HealthPermissionManager: $e');
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

        debugPrint('Permission request for $dataType: $isGranted');
      } catch (e) {
        debugPrint('Error requesting permission for $dataType: $e');
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
        debugPrint('Error checking permission for $dataType: $e');
        results[dataType] = false;
      }
    }

    // Save updated cache if we made fresh checks
    if (deltas.isNotEmpty) {
      await _savePermissionCache();
      _deltaStreamController.add(deltas);
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
    debugPrint('Permission toast: $message');
  }

  /// Check for missing permissions and notify user
  Future<void> _checkMissingPermissionsAndNotify() async {
    final missingPermissions = await getMissingPermissions();

    if (missingPermissions.isNotEmpty) {
      final dataTypeNames = missingPermissions
          .map((type) => _friendlyDataTypeName(type))
          .join(', ');

      final message =
          Platform.isAndroid
              ? 'Health permissions needed for $dataTypeNames. Enable in Health Connect.'
              : 'Health permissions needed for $dataTypeNames. Enable in Health app.';

      await showMissingPermissionToast(message);
    }
  }

  /// Get user-friendly name for data type
  String _friendlyDataTypeName(WearableDataType type) {
    switch (type) {
      case WearableDataType.steps:
        return 'Steps';
      case WearableDataType.heartRate:
        return 'Heart Rate';
      case WearableDataType.sleepDuration:
        return 'Sleep';
      case WearableDataType.activeEnergyBurned:
        return 'Active Energy';
      case WearableDataType.distanceWalking:
        return 'Walking Distance';
      case WearableDataType.flightsClimbed:
        return 'Flights Climbed';
      case WearableDataType.heartRateVariability:
        return 'Heart Rate Variability';
      case WearableDataType.weight:
        return 'Weight';
      default:
        return type.name;
    }
  }

  /// Perform initial permission check on startup
  Future<void> _performInitialPermissionCheck() async {
    try {
      await checkPermissions(useCache: false);
      debugPrint('Initial permission check completed');
    } catch (e) {
      debugPrint('Error during initial permission check: $e');
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
        debugPrint('Error during periodic permission check: $e');
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
        debugPrint('Loaded ${_permissionCache.length} cached permissions');
      }
    } catch (e) {
      debugPrint('Error loading permission cache: $e');
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
      debugPrint(
        'Saved permission cache with ${_permissionCache.length} entries',
      );
    } catch (e) {
      debugPrint('Error saving permission cache: $e');
    }
  }

  /// Load configuration from storage
  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);

      if (configJson != null) {
        // Configuration loading would be implemented here
        debugPrint('Configuration loaded from storage');
      }
    } catch (e) {
      debugPrint('Error loading configuration: $e');
    }
  }

  /// Save configuration to storage
  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Configuration saving would be implemented here
      await prefs.setString(_configKey, jsonEncode({}));
      debugPrint('Configuration saved to storage');
    } catch (e) {
      debugPrint('Error saving configuration: $e');
    }
  }

  /// Clear all cached permissions
  Future<void> clearCache() async {
    _permissionCache.clear();
    await _savePermissionCache();
    debugPrint('Permission cache cleared');
  }

  /// Reset permission denial tracking
  void resetDenialTracking() {
    _repository.resetPermissionDenialTracking();
    debugPrint('Permission denial tracking reset');
  }

  /// Dispose resources
  void dispose() {
    _periodicCheckTimer?.cancel();
    _deltaStreamController.close();
    _toastStreamController.close();
    debugPrint('HealthPermissionManager disposed');
  }
}
