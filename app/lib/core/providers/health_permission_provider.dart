/// Health Permission Provider for Riverpod State Management
///
/// This file provides Riverpod providers for health permission management,
/// including the permission manager service, permission status state, and
/// toast notifications for missing permissions.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/health_permission_manager.dart';
import '../services/wearable_data_models.dart';

/// Provider for the HealthPermissionManager singleton
final healthPermissionManagerProvider = Provider<HealthPermissionManager>((
  ref,
) {
  return HealthPermissionManager();
});

/// Provider for current permission status
final permissionStatusProvider =
    StateNotifierProvider<PermissionStatusNotifier, PermissionStatusState>((
      ref,
    ) {
      final manager = ref.watch(healthPermissionManagerProvider);
      return PermissionStatusNotifier(manager);
    });

/// Provider for permission delta stream
final permissionDeltaStreamProvider = StreamProvider<List<PermissionDelta>>((
  ref,
) {
  final manager = ref.watch(healthPermissionManagerProvider);
  return manager.deltaStream;
});

/// Provider for toast notification stream
final permissionToastStreamProvider = StreamProvider<String>((ref) {
  final manager = ref.watch(healthPermissionManagerProvider);
  return manager.toastStream;
});

/// Provider for missing permissions
final missingPermissionsProvider = FutureProvider<List<WearableDataType>>((
  ref,
) async {
  final manager = ref.watch(healthPermissionManagerProvider);
  if (!manager.isInitialized) {
    await manager.initialize();
  }
  return manager.getMissingPermissions();
});

/// Provider for individual permission status
final individualPermissionProvider =
    FutureProvider.family<bool, WearableDataType>((ref, dataType) async {
      final manager = ref.watch(healthPermissionManagerProvider);
      if (!manager.isInitialized) {
        await manager.initialize();
      }
      final permissions = await manager.checkPermissions(dataTypes: [dataType]);
      return permissions[dataType] ?? false;
    });

/// State class for permission status
class PermissionStatusState {
  final bool isInitialized;
  final bool isLoading;
  final Map<WearableDataType, bool> permissions;
  final List<WearableDataType> missingPermissions;
  final String? errorMessage;
  final DateTime? lastChecked;

  const PermissionStatusState({
    this.isInitialized = false,
    this.isLoading = false,
    this.permissions = const {},
    this.missingPermissions = const [],
    this.errorMessage,
    this.lastChecked,
  });

  PermissionStatusState copyWith({
    bool? isInitialized,
    bool? isLoading,
    Map<WearableDataType, bool>? permissions,
    List<WearableDataType>? missingPermissions,
    String? errorMessage,
    DateTime? lastChecked,
  }) {
    return PermissionStatusState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      permissions: permissions ?? this.permissions,
      missingPermissions: missingPermissions ?? this.missingPermissions,
      errorMessage: errorMessage ?? this.errorMessage,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  /// Whether all required permissions are granted
  bool get hasAllRequiredPermissions => missingPermissions.isEmpty;

  /// Get permission status for a specific data type
  bool isPermissionGranted(WearableDataType dataType) =>
      permissions[dataType] ?? false;
}

/// State notifier for permission status management
class PermissionStatusNotifier extends StateNotifier<PermissionStatusState> {
  PermissionStatusNotifier(this._manager)
    : super(const PermissionStatusState()) {
    _initialize();
  }

  final HealthPermissionManager _manager;

  /// Initialize the permission manager and load current state
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      final initialized = await _manager.initialize();
      if (initialized) {
        await _refreshPermissions();
        state = state.copyWith(
          isInitialized: true,
          isLoading: false,
          lastChecked: DateTime.now(),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to initialize permission manager',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error initializing permissions: $e',
      );
      debugPrint('Error initializing PermissionStatusNotifier: $e');
    }
  }

  /// Refresh current permission status
  Future<void> _refreshPermissions() async {
    try {
      final permissions = await _manager.checkPermissions();
      final missingPermissions = await _manager.getMissingPermissions();

      state = state.copyWith(
        permissions: permissions,
        missingPermissions: missingPermissions,
        lastChecked: DateTime.now(),
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error refreshing permissions: $e');
      debugPrint('Error refreshing permissions: $e');
    }
  }

  /// Request all required permissions
  Future<bool> requestAllPermissions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await _manager.requestPermissions();
      await _refreshPermissions();

      final allGranted = results.values.every((granted) => granted);

      state = state.copyWith(isLoading: false);
      return allGranted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error requesting permissions: $e',
      );
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Request specific permissions
  Future<bool> requestPermissions(List<WearableDataType> dataTypes) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await _manager.requestPermissions(dataTypes: dataTypes);
      await _refreshPermissions();

      final allGranted = results.values.every((granted) => granted);

      state = state.copyWith(isLoading: false);
      return allGranted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error requesting permissions: $e',
      );
      debugPrint('Error requesting permissions for $dataTypes: $e');
      return false;
    }
  }

  /// Check and refresh permission status
  Future<void> checkPermissions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _refreshPermissions();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error checking permissions: $e',
      );
      debugPrint('Error checking permissions: $e');
    }
  }

  /// Clear permission cache and refresh
  Future<void> clearCache() async {
    try {
      await _manager.clearCache();
      await _refreshPermissions();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error clearing cache: $e');
      debugPrint('Error clearing permission cache: $e');
    }
  }

  /// Reset permission denial tracking
  void resetDenialTracking() {
    try {
      _manager.resetDenialTracking();
    } catch (e) {
      debugPrint('Error resetting denial tracking: $e');
    }
  }

  /// Show missing permission toast
  Future<void> showMissingPermissionToast(String message) async {
    try {
      await _manager.showMissingPermissionToast(message);
    } catch (e) {
      debugPrint('Error showing permission toast: $e');
    }
  }
}
