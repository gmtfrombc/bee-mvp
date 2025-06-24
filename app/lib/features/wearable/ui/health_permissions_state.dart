/// Health Permissions State Management
///
/// This file contains all state management logic for health permissions,
/// including the state class, state notifier, and provider.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/wearable_data_repository.dart';
import '../../../core/services/wearable_data_models.dart';
import '../../../core/services/android_settings_service.dart';

/// Provider for health permissions state management
final healthPermissionsProvider =
    StateNotifierProvider<HealthPermissionsNotifier, HealthPermissionsState>((
      ref,
    ) {
      return HealthPermissionsNotifier();
    });

/// State for health permissions flow
class HealthPermissionsState {
  final bool isLoading;
  final HealthPermissionStatus status;
  final Map<WearableDataType, bool> individualPermissions;
  final String? errorMessage;
  final bool showSettingsPrompt;
  final bool showHealthConnectInstallPrompt;
  final bool isPermanentlyDenied;
  final bool isHealthConnectAvailable;
  final HealthConnectAvailabilityResult? healthConnectAvailability;

  const HealthPermissionsState({
    this.isLoading = false,
    this.status = HealthPermissionStatus.notDetermined,
    this.individualPermissions = const {},
    this.errorMessage,
    this.showSettingsPrompt = false,
    this.showHealthConnectInstallPrompt = false,
    this.isPermanentlyDenied = false,
    this.isHealthConnectAvailable = true,
    this.healthConnectAvailability,
  });

  HealthPermissionsState copyWith({
    bool? isLoading,
    HealthPermissionStatus? status,
    Map<WearableDataType, bool>? individualPermissions,
    String? errorMessage,
    bool? showSettingsPrompt,
    bool? showHealthConnectInstallPrompt,
    bool? isPermanentlyDenied,
    bool? isHealthConnectAvailable,
    HealthConnectAvailabilityResult? healthConnectAvailability,
  }) {
    return HealthPermissionsState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      individualPermissions:
          individualPermissions ?? this.individualPermissions,
      errorMessage: errorMessage ?? this.errorMessage,
      showSettingsPrompt: showSettingsPrompt ?? this.showSettingsPrompt,
      showHealthConnectInstallPrompt:
          showHealthConnectInstallPrompt ?? this.showHealthConnectInstallPrompt,
      isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
      isHealthConnectAvailable:
          isHealthConnectAvailable ?? this.isHealthConnectAvailable,
      healthConnectAvailability:
          healthConnectAvailability ?? this.healthConnectAvailability,
    );
  }

  /// Get user-friendly message for current Health Connect state
  String? get healthConnectStatusMessage {
    return healthConnectAvailability?.userMessage;
  }

  /// Check if Health Connect issue can be resolved
  bool get canResolveHealthConnectIssue {
    return healthConnectAvailability?.canResolve ?? false;
  }

  /// Get action text for resolving Health Connect issue
  String get healthConnectActionText {
    return healthConnectAvailability?.actionText ?? 'Install Health Connect';
  }
}

/// State notifier for managing health permissions
class HealthPermissionsNotifier extends StateNotifier<HealthPermissionsState> {
  HealthPermissionsNotifier() : super(const HealthPermissionsState());

  final _repository = WearableDataRepository();
  static const _cacheKey = 'health_permissions_granted_v1';
  static const _explicitGrantKey = 'health_permissions_explicit_grant_v1';

  Future<void> _saveGrantedFlag(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cacheKey, granted);
  }

  Future<bool?> _loadGrantedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cacheKey);
  }

  Future<void> _saveExplicitGrant(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_explicitGrantKey, granted);
  }

  Future<bool?> _loadExplicitGrant() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_explicitGrantKey);
  }

  /// Initialize the repository and check current permissions
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final initialized = await _repository.initialize();
      if (!initialized) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to initialize health data access',
        );
        return;
      }

      // Check platform-specific availability
      if (Platform.isAndroid) {
        // Use enhanced availability check for detailed results
        final availabilityResult = await _repository.getDetailedAvailability();
        final isAvailable = availabilityResult.isAvailable;
        final isPermanentlyDenied = _repository.hasBeenPermanentlyDenied;

        state = state.copyWith(
          isHealthConnectAvailable: isAvailable,
          isPermanentlyDenied: isPermanentlyDenied,
          showHealthConnectInstallPrompt:
              !isAvailable && availabilityResult.canResolve,
          healthConnectAvailability: availabilityResult,
        );

        if (!isAvailable) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: availabilityResult.userMessage,
          );
          return;
        }

        if (isPermanentlyDenied) {
          state = state.copyWith(
            isLoading: false,
            status: HealthPermissionStatus.denied,
            showSettingsPrompt: true,
          );
          return;
        }
      }

      // If we previously cached a granted state, and no permission revocation
      // has occurred, skip redundant dialog.
      final cachedGranted = await _loadGrantedFlag();

      var status = await _repository.checkPermissions();

      // If user explicitly granted before, treat as authorized even if
      // HealthKit still reports unknown (common right after fresh grant).
      final explicitGrant = await _loadExplicitGrant();
      if (explicitGrant == true &&
          status != HealthPermissionStatus.authorized) {
        status = HealthPermissionStatus.authorized;
      }

      if (status == HealthPermissionStatus.authorized &&
          cachedGranted != true) {
        // Persist granted flag for next launch
        // ignore: unawaited_futures
        _saveGrantedFlag(true);
      }

      state = state.copyWith(isLoading: false, status: status);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error initializing health permissions: $e',
      );
    }
  }

  /// Request health permissions
  Future<void> requestPermissions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Android-specific checks
      if (Platform.isAndroid) {
        if (!state.isHealthConnectAvailable) {
          state = state.copyWith(
            isLoading: false,
            showHealthConnectInstallPrompt: true,
            errorMessage: 'Health Connect app is required but not available',
          );
          return;
        }

        if (state.isPermanentlyDenied) {
          state = state.copyWith(
            isLoading: false,
            showSettingsPrompt: true,
            errorMessage:
                'Permissions have been permanently denied. Please enable in Settings.',
          );
          return;
        }
      }

      final statusReq = await _repository.requestPermissions();

      // Immediately re-query to capture the true state after the system sheet
      // closes (handles the case where the user changed their mind inside the
      // dialog).  This avoids having to cold-restart the app.
      final status = await _repository.checkPermissions();

      // On iOS the plugin may still return unknown immediately after a grant
      // even though requestAuthorization succeeded. When that happens, trust
      // the positive request result for this session.
      var effectiveStatus = status;
      if (Platform.isIOS &&
          statusReq == HealthPermissionStatus.authorized &&
          status != HealthPermissionStatus.authorized) {
        effectiveStatus = HealthPermissionStatus.authorized;
      }

      if (effectiveStatus == HealthPermissionStatus.authorized) {
        // Persist granted flag
        // ignore: unawaited_futures
        _saveGrantedFlag(true);
        // Remember explicit grant
        // ignore: unawaited_futures
        _saveExplicitGrant(true);

        state = state.copyWith(
          isLoading: false,
          status: HealthPermissionStatus.authorized,
        );
      } else if (status == HealthPermissionStatus.denied) {
        // Save negative
        // ignore: unawaited_futures
        _saveGrantedFlag(false);
        // clear explicit grant
        // ignore: unawaited_futures
        _saveExplicitGrant(false);

        // Check if this was a permanent denial on Android
        if (Platform.isAndroid && _repository.hasBeenPermanentlyDenied) {
          state = state.copyWith(
            isLoading: false,
            status: status,
            showSettingsPrompt: true,
            isPermanentlyDenied: true,
            errorMessage:
                'Permissions permanently denied. Please enable in Settings.',
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            status: status,
            showSettingsPrompt:
                Platform.isIOS, // iOS shows settings, Android can retry
            errorMessage:
                Platform.isAndroid
                    ? 'Permissions denied. You can try again or enable in Settings.'
                    : 'Permissions denied. Please enable in Settings.',
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error requesting permissions: $e',
      );
    }
  }

  /// Open device settings
  Future<void> openSettings() async {
    if (Platform.isIOS) {
      const settingsUrl = 'app-settings:';
      if (await canLaunchUrl(Uri.parse(settingsUrl))) {
        await launchUrl(Uri.parse(settingsUrl));
      }
    } else if (Platform.isAndroid) {
      final androidSettings = AndroidSettingsService();

      // For permanent denial, try Health Connect specific settings first
      if (state.isPermanentlyDenied) {
        final success = await androidSettings.openHealthConnectSettings();
        if (!success) {
          debugPrint(
            'Failed to open Health Connect settings, showing instructions',
          );
          // Update state to show manual instructions
          state = state.copyWith(
            errorMessage: androidSettings.getPermissionInstructions(
              isHealthConnectAvailable: state.isHealthConnectAvailable,
            ),
          );
        }
      } else {
        // Regular settings opening
        await androidSettings.openAppSettings();
      }
    }
  }

  /// Open Health Connect installation/setup (Android specific)
  Future<void> openHealthConnectSetup() async {
    if (!Platform.isAndroid) return;

    try {
      // Try to open Health Connect app or Play Store
      const healthConnectPackage = 'com.google.android.apps.healthdata';
      const playStoreUrl =
          'market://details?id=$healthConnectPackage&url=healthconnect%3A%2F%2Fonboarding';

      if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
        await launchUrl(Uri.parse(playStoreUrl));
      } else {
        // Fallback to web Play Store
        const webUrl =
            'https://play.google.com/store/apps/details?id=$healthConnectPackage';
        if (await canLaunchUrl(Uri.parse(webUrl))) {
          await launchUrl(Uri.parse(webUrl));
        }
      }
    } catch (e) {
      debugPrint('Error opening Health Connect setup: $e');
    }
  }

  /// Reset and retry permissions (useful for Android after addressing issues)
  Future<void> retryPermissions() async {
    if (Platform.isAndroid) {
      _repository.resetPermissionDenialTracking();
    }
    await requestPermissions();
  }

  /// Dismiss the settings prompt
  void dismissSettingsPrompt() {
    state = state.copyWith(showSettingsPrompt: false);
  }

  /// Dismiss the Health Connect install prompt
  void dismissHealthConnectInstallPrompt() {
    state = state.copyWith(showHealthConnectInstallPrompt: false);
  }

  /// Lightweight foreground refresh used by app lifecycle listener.
  Future<void> refreshPermissions() async {
    try {
      final status = await _repository.checkPermissions();

      // If explicit grant stored but now revoked, clear flag.
      final explicitGrant = await _loadExplicitGrant();
      if (explicitGrant == true && status == HealthPermissionStatus.denied) {
        await _saveExplicitGrant(false);
      }

      // If explicit grant exists treat as authorized.
      final effective =
          (explicitGrant == true) ? HealthPermissionStatus.authorized : status;

      state = state.copyWith(status: effective);
    } catch (e) {
      debugPrint('Error refreshing permissions: $e');
    }
  }
}
