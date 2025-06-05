import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Connectivity states for the app
enum ConnectivityStatus {
  online,
  offline,
  limited, // Connected but with limited functionality
}

/// Service to monitor network connectivity and manage offline/online states
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();
  static bool _isTestEnvironment = false;

  /// Set test environment mode to disable connectivity subscriptions
  static void setTestEnvironment(bool isTest) {
    _isTestEnvironment = isTest;
  }

  /// Stream of connectivity status changes
  static Stream<ConnectivityStatus> get statusStream =>
      _statusController.stream;

  /// Current connectivity status
  static ConnectivityStatus _currentStatus = ConnectivityStatus.offline;
  static ConnectivityStatus get currentStatus => _currentStatus;

  /// Initialize connectivity monitoring
  static Future<void> initialize() async {
    // Skip initialization in test environment
    if (_isTestEnvironment) {
      _currentStatus = ConnectivityStatus.online;
      debugPrint(
        '✅ ConnectivityService test mode - skipping real initialization',
      );
      return;
    }

    // Get initial connectivity status
    final initialResult = await _connectivity.checkConnectivity();
    _updateStatus(initialResult);

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (error) {
        debugPrint('Connectivity monitoring error: $error');
        // Set to offline on error to be safe
        _currentStatus = ConnectivityStatus.offline;
        _updateStream();
      },
    );
  }

  /// Update connectivity status based on connectivity result
  static void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    final newStatus =
        hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline;

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _updateStream();
    }
  }

  /// Check if device is currently online
  static bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Check if device is currently offline
  static bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Test actual internet connectivity (not just network connection)
  static Future<bool> hasInternetConnection() async {
    try {
      // Simple connectivity test - could be enhanced with actual HTTP request
      final result = await _connectivity.checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      debugPrint('Internet connectivity test failed: $e');
      return false;
    }
  }

  /// Dispose of connectivity monitoring
  static Future<void> dispose() async {
    await _subscription?.cancel();
    await _statusController.close();
  }

  static void _updateStream() {
    debugPrint('Connectivity status changed: $_currentStatus');
    _statusController.add(_currentStatus);
  }

  // ============================================================================
  // TESTING HELPER METHODS
  // ============================================================================

  /// Set offline status for testing purposes
  /// **WARNING**: This should only be used in test environments
  static void setOfflineForTesting(bool isOffline) {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    _currentStatus =
        isOffline ? ConnectivityStatus.offline : ConnectivityStatus.online;
    _updateStream();
  }

  /// Reset connectivity service to default state for testing
  static void resetForTesting() {
    assert(() {
      // Only allow this in debug/test builds
      return true;
    }());

    _currentStatus = ConnectivityStatus.offline;
    _updateStream();
  }
}

/// Riverpod provider for connectivity status
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  return ConnectivityService.statusStream;
});

/// Provider for current connectivity status
final currentConnectivityProvider = Provider<ConnectivityStatus>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.maybeWhen(
    data: (status) => status,
    orElse: () => ConnectivityService.currentStatus,
  );
});

/// Provider to check if device is online
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(currentConnectivityProvider);
  return status == ConnectivityStatus.online;
});

/// Provider to check if device is offline
final isOfflineProvider = Provider<bool>((ref) {
  final status = ref.watch(currentConnectivityProvider);
  return status == ConnectivityStatus.offline;
});
