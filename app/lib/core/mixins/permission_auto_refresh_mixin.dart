import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/health_permission_provider.dart'
    show healthPermissionManagerProvider;

/// Mixin that triggers a fresh permission check every time the app returns to
/// the foreground and then every 5 minutes while the host widget remains
/// mounted. Attach this mixin to *State* classes that also mix in
/// [ConsumerState] so that we can access the Riverpod `ref` object.
///
/// Usage:
/// ```dart
/// class _MyScreenState extends ConsumerState<MyScreen>
///     with PermissionAutoRefreshMixin<MyScreen> { ... }
/// ```
mixin PermissionAutoRefreshMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T>
    implements WidgetsBindingObserver {
  static const Duration _foregroundInterval = Duration(minutes: 5);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Kick-off once after build completes.
    _refreshPermissions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
      _startTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_foregroundInterval, (_) => _refreshPermissions());
  }

  Future<void> _refreshPermissions() async {
    final mgr = ref.read(healthPermissionManagerProvider);
    if (!mgr.isInitialized) {
      await mgr.initialize();
    }
    // Fresh check – skip cache so we pick up switch changes instantly.
    // Ignore errors; UI will fall back to last known state.
    // ignore: avoid_catches_without_on_clauses
    try {
      await mgr.checkPermissions(useCache: false);
    } catch (_) {}
  }

  // ---- WidgetsBindingObserver no-op overrides ----------------------------------
  @override
  void didChangeAccessibilityFeatures() {}

  @override
  void didChangeLocales(List<Locale>? locales) {}

  @override
  void didChangeMetrics() {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {}

  @override
  Future<bool> didPopRoute() async => false;

  @override
  Future<bool> didPushRoute(String route) async => false;

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async => false;

  // App exit / navigation callbacks intentionally no-op for this mixin.

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
