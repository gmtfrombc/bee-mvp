/// Handles starting/stopping adapters and surfaces status events.
library;

import 'dart:async';

import 'package:app/core/services/wearable_live_service.dart';
import 'package:app/core/services/wearable_data_repository.dart';
import 'package:app/core/services/vitals/processing/vitals_aggregator.dart';
import 'package:app/core/services/vitals/adapters/live_adapter.dart';
import 'package:app/core/services/vitals/adapters/polling_adapter.dart';
import 'package:app/core/services/vitals/stream_manager/connection_status.dart';

/// Orchestrates [LiveAdapter] and [PollingAdapter] and exposes consolidated
/// vitals + connection status streams.  The controller is agnostic of UI
/// and provides a simple facade for higher-level services (see
/// `vitals_facade.dart`).
class SubscriptionController {
  SubscriptionController({
    required WearableLiveService liveService,
    required WearableDataRepository repository,
    required VitalsAggregator aggregator,
  }) : _liveService = liveService,
       _repository = repository,
       _aggregator = aggregator,
       _liveAdapter = LiveAdapter(aggregator: aggregator),
       _pollingAdapter = PollingAdapter(
         repository: repository,
         aggregator: aggregator,
       );

  final WearableLiveService _liveService;
  final WearableDataRepository _repository; // ignore: unused_field
  final VitalsAggregator _aggregator; // ignore: unused_field

  final LiveAdapter _liveAdapter;
  final PollingAdapter _pollingAdapter;

  // -----------------------------------------------------------------------
  // Streams – surfaced to facade/UI
  // -----------------------------------------------------------------------
  final StreamController<VitalsConnectionStatus> _statusCtrl =
      StreamController<VitalsConnectionStatus>.broadcast();

  Stream<VitalsConnectionStatus> get statusStream => _statusCtrl.stream;

  VitalsConnectionStatus _status = VitalsConnectionStatus.disconnected;

  void _setStatus(VitalsConnectionStatus s) {
    if (_status != s) {
      _status = s;
      _statusCtrl.add(s);
    }
  }

  bool _active = false;
  bool get isActive => _active;

  /// Starts streaming vitals for [userId].  If [forcePolling] is `true`,
  /// realtime streaming is skipped and polling mode is used instead.  Returns
  /// `true` when the controller is active.
  Future<bool> start(String userId, {bool forcePolling = false}) async {
    if (_active) return true;

    // Decide between realtime vs polling.  For now we honour [forcePolling]
    // flag only – adaptive polling preference logic lives at a higher layer.
    final bool usePolling = forcePolling;

    _setStatus(VitalsConnectionStatus.connecting);

    if (usePolling) {
      await _pollingAdapter.start();
      _active = true;
      _setStatus(VitalsConnectionStatus.polling);
      return true;
    }

    // --- Realtime path ----------------------------------------------------
    final started = await _liveService.startStreaming(userId);
    if (!started) {
      _setStatus(VitalsConnectionStatus.error);
      return false;
    }

    _liveAdapter.start(_liveService.messageStream);

    // Fetch an immediate snapshot via polling so the UI has data even before
    // realtime packets arrive (mirrors legacy behaviour).
    await _pollingAdapter.pollOnce();

    _active = true;
    _setStatus(VitalsConnectionStatus.connected);
    return true;
  }

  /// Stops any active adapters and cleans-up resources.
  Future<void> stop() async {
    if (!_active) return;

    // Stop adapters regardless of currently active mode.
    await _pollingAdapter.stop();
    await _liveAdapter.stop();
    await _liveService.stopStreaming();

    _active = false;
    _setStatus(VitalsConnectionStatus.disconnected);
  }

  /// Disposes all controllers. After calling this the instance must not be
  /// used again.
  Future<void> dispose() async {
    await stop();
    await _statusCtrl.close();
  }
}
