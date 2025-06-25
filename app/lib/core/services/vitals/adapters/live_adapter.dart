import 'dart:async';

import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/services/vitals/processing/numeric_helpers.dart';
import 'package:app/core/services/vitals/processing/vitals_aggregator.dart';
import 'package:app/core/services/wearable_live_models.dart';
import 'package:app/core/services/wearable_data_models.dart';

/// Translates `WearableLiveService` messages into domain [VitalsData] objects
/// and forwards them to a [VitalsAggregator].
class LiveAdapter {
  LiveAdapter({required this.aggregator});

  final VitalsAggregator aggregator;

  StreamSubscription<List<WearableLiveMessage>>? _sub;

  /// Starts listening to [liveStream] and forwarding results.
  void start(Stream<List<WearableLiveMessage>> liveStream) {
    _sub = liveStream.listen(_handleBatch);
  }

  Future<void> stop() async => _sub?.cancel();

  void _handleBatch(List<WearableLiveMessage> batch) {
    for (final msg in batch) {
      final data = _toVitalsData(msg);
      if (data != null) aggregator.add(data);
    }
  }

  VitalsData? _toVitalsData(WearableLiveMessage m) {
    final ts = m.timestamp;
    double? hr;
    int? steps;
    double? hrv;
    double? sleep;
    double? energy;
    double? weight;

    switch (m.type) {
      case WearableDataType.heartRate:
        hr = NumericHelpers.toDouble(m.value);
        break;
      case WearableDataType.steps:
        steps = NumericHelpers.toInt(m.value);
        break;
      case WearableDataType.heartRateVariability:
        hrv = NumericHelpers.toDouble(m.value);
        break;
      case WearableDataType.sleepDuration:
        final minutes = NumericHelpers.toDouble(m.value);
        if (minutes != null) sleep = minutes / 60.0;
        break;
      case WearableDataType.activeEnergyBurned:
        energy = NumericHelpers.toDouble(m.value);
        break;
      case WearableDataType.weight:
        final kg = NumericHelpers.toDouble(m.value);
        if (kg != null) weight = kg * 2.20462;
        break;
      default:
        return null;
    }

    if (hr == null &&
        steps == null &&
        hrv == null &&
        sleep == null &&
        energy == null &&
        weight == null) {
      return null;
    }

    return VitalsData(
      heartRate: hr,
      steps: steps,
      heartRateVariability: hrv,
      sleepHours: sleep,
      activeEnergy: energy,
      weight: weight,
      timestamp: ts,
      quality: VitalsQuality.good,
      metadata: {'source': m.source},
    );
  }
}
