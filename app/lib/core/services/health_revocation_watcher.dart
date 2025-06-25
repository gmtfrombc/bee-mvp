/// Health Revocation Watcher – optional lightweight layer that
/// tracks if *any* of the required health data permissions become
/// revoked at runtime.  It writes a boolean flag to SharedPreferences
/// so UI layers can decide whether to surface an "Open Settings" CTA
/// even when the existing permission state machines still think
/// everything is fine (e.g. because of the explicit-grant override).
///
/// The watcher is completely side-effect free when the feature flag
/// [kEnableLiveHealthRevocation] is `false` (the default).  This makes
/// it safe to ship without risking regressions.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'health_permission_manager.dart';

/// Feature flag – enabled automatically in debug/profile builds so that
/// QA can verify behaviour without needing a code change.  It remains off
/// in release/APK builds (where `kReleaseMode == true`).
const bool kEnableLiveHealthRevocation = !kReleaseMode;

/// Key used to persist the current "revoked" state.
const String kRevokedFlagPrefsKey = 'health_permissions_revoked_v1';

/// Singleton service.
class HealthRevocationWatcher {
  HealthRevocationWatcher._internal();
  static final HealthRevocationWatcher _instance =
      HealthRevocationWatcher._internal();
  factory HealthRevocationWatcher() => _instance;

  StreamSubscription? _deltaSub;
  bool _initialised = false;
  final StreamController<bool> _revokedStreamController =
      StreamController<bool>.broadcast();

  /// Public stream of the current revoked flag. UI layers can subscribe to
  /// this to rebuild instantly without polling SharedPreferences.
  Stream<bool> get revokedStream => _revokedStreamController.stream;

  Future<void> _lazyInit() async {
    if (_initialised || !kEnableLiveHealthRevocation) return;
    _initialised = true;

    final mgr = HealthPermissionManager();
    if (!mgr.isInitialized) await mgr.initialize();

    // Listen to live deltas so we react immediately when a user toggles
    // permissions in the background and brings the app back to foreground.
    _deltaSub = mgr.deltaStream.listen(_handleDeltas, onError: (_) {});

    // Evaluate once at startup so the flag is accurate even if no deltas
    // are emitted during the session.
    await evaluateCurrentPermissions();
  }

  /// Public API – should be called by app lifecycle hooks after a
  /// fresh permission check.
  Future<void> evaluateCurrentPermissions() async {
    if (!kEnableLiveHealthRevocation) return;
    await _lazyInit();

    final mgr = HealthPermissionManager();
    final perms = await mgr.checkPermissions(useCache: false);
    final revoked = perms.values.any((granted) => !granted);
    await _persistRevokedFlag(revoked);
  }

  // ------------------------------------------------------------------
  // Internal helpers
  // ------------------------------------------------------------------
  Future<void> _handleDeltas(List deltas) async {
    // A delta is emitted per WearableDataType that changed.  If at least one
    // turned "false" we mark revoked=true.  If all became true we clear it.
    if (deltas.isEmpty) return;

    bool revoked = false;
    for (final delta in deltas) {
      if (delta is PermissionDelta) {
        if (delta.isNewlyDenied) {
          revoked = true;
          break;
        }
      }
    }

    if (!revoked) {
      // No new denial => re-evaluate full permission map.
      final mgr = HealthPermissionManager();
      final perms = await mgr.checkPermissions();
      revoked = perms.values.any((granted) => !granted);
    }

    await _persistRevokedFlag(revoked);
  }

  Future<void> _persistRevokedFlag(bool revoked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kRevokedFlagPrefsKey, revoked);
    if (kDebugMode) {
      // ignore: avoid_print
      print('[RevocationWatcher] revoked=$revoked');
    }

    // Push to stream listeners.
    if (!_revokedStreamController.isClosed) {
      _revokedStreamController.add(revoked);
    }
  }

  void dispose() {
    _deltaSub?.cancel();
    _revokedStreamController.close();
  }
}
