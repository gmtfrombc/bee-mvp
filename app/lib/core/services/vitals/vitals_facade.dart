// ignore_for_file: unused_shown_name
/// Vitals module public API facade.
///
/// Facade that replaces the legacy `VitalsNotifierService` while maintaining
/// a compatible public surface.
///
/// ignore_for_file: unused_shown_name
library;

import 'dart:async';

import 'package:app/core/services/vitals/stream_manager/connection_status.dart';
import 'package:app/core/services/vitals/stream_manager/subscription_controller.dart';
import 'package:app/core/services/vitals/processing/vitals_aggregator.dart';
import 'package:app/core/services/vitals/cache/vitals_cache.dart';

// Upstream dependencies
import 'package:app/core/services/wearable_live_service.dart';
import 'package:app/core/services/wearable_data_repository.dart';

import 'package:app/core/services/vitals_notifier_service.dart'
    as legacy
    show
        VitalsQuality,
        VitalsData,
        VitalsNotifierService; // Re-export legacy types until full migration.

import 'package:shared_preferences/shared_preferences.dart';

export 'package:app/core/services/vitals_notifier_service.dart'
    show VitalsQuality, VitalsData, VitalsNotifierService;

class VitalsService {
  VitalsService({
    required WearableLiveService liveService,
    required WearableDataRepository repository,
    VitalsCache? cache,
  }) : _cache = cache ?? VitalsCache() {
    _aggregator = VitalsAggregator();
    _controller = SubscriptionController(
      liveService: liveService,
      repository: repository,
      aggregator: _aggregator,
    );
  }

  late final VitalsAggregator _aggregator;
  late final SubscriptionController _controller;
  final VitalsCache _cache;

  // Streams -----------------------------------------------------------------
  Stream<legacy.VitalsData> get vitalsStream => _aggregator.stream;
  Stream<VitalsConnectionStatus> get statusStream => _controller.statusStream;

  legacy.VitalsData? get currentVitals => _aggregator.current;

  // Lifecycle ----------------------------------------------------------------
  bool _initialised = false;

  Future<bool> initialize() async {
    if (_initialised) return true;
    // Restore cached snapshot so UI has something immediately.
    final cached = await _cache.read();
    if (cached != null) _aggregator.add(cached);
    _initialised = true;
    return true;
  }

  Future<bool> startSubscription(String userId) async {
    if (!_initialised) await initialize();

    // Honour stored adaptive polling preference
    final prefs = await SharedPreferences.getInstance();
    final usePolling =
        prefs.getBool(legacy.VitalsNotifierService.adaptivePollingPrefKey) ??
        false;

    return _controller.start(userId, forcePolling: usePolling);
  }

  Future<void> stopSubscription() => _controller.stop();
  Future<void> dispose() => _controller.dispose();

  // Manual refresh (poll once) ----------------------------------------------
  Future<void> refreshVitals() async {
    await _controller.start('self', forcePolling: true);
  }

  // Helper utilities ---------------------------------------------------------
  List<legacy.VitalsData> getRecentVitals({
    Duration window = const Duration(seconds: 30),
  }) {
    final cutoff = DateTime.now().subtract(window);
    return _aggregator.history
        .where((d) => d.timestamp.isAfter(cutoff))
        .toList();
  }

  double? getAverageHeartRate({Duration window = const Duration(seconds: 30)}) {
    final recent = getRecentVitals(window: window);
    final list =
        recent.where((d) => d.hasHeartRate).map((d) => d.heartRate!).toList();
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }

  bool isStressIndicator() {
    final recent = getRecentVitals();
    if (recent.length < 2) return false;
    final hrs =
        recent.where((d) => d.hasHeartRate).map((d) => d.heartRate!).toList();
    if (hrs.length < 2) return false;
    final latest = hrs.last;
    final avg = hrs.reduce((a, b) => a + b) / hrs.length;
    return latest > avg * 1.15;
  }
}
