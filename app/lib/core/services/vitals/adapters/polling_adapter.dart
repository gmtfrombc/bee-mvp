import 'dart:async';

import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/services/vitals/processing/numeric_helpers.dart';
import 'package:app/core/services/vitals/processing/vitals_aggregator.dart';
import 'package:app/core/services/wearable_data_models.dart';
import 'package:app/core/services/wearable_data_repository.dart';

/// Handles Health repository polling, back-off, and error handling.
class PollingAdapter {
  PollingAdapter({
    required this.repository,
    required this.aggregator,
    this.interval = const Duration(minutes: 5),
  });

  final WearableDataRepository repository; // existing singleton
  final VitalsAggregator aggregator;
  final Duration interval;

  Timer? _timer;
  bool _active = false;

  Future<void> start() async {
    if (_active) return;
    _active = true;

    // Ensure repository is initialised.
    if (!repository.isInitialized) {
      await repository.initialize();
    }

    // Immediate poll then schedule.
    await _poll();
    _timer = Timer.periodic(interval, (_) => _poll());
  }

  Future<void> stop() async {
    _active = false;
    _timer?.cancel();
  }

  Future<void> _poll() async {
    if (!_active) return;
    await _performCompositeFetch();
  }

  Future<void> _performCompositeFetch() async {
    final now = DateTime.now();

    // Ensure repository initialised.
    if (!repository.isInitialized) {
      await repository.initialize();
    }

    // --- 1️⃣ Point-in-time metrics (look-back 5 min) --------------------
    final pointTypes =
        repository.config.dataTypes.where((t) {
          return !t.isCumulative &&
              t != WearableDataType.weight &&
              t != WearableDataType.restingHeartRate;
        }).toList();

    final pointRes = await repository.getHealthData(
      dataTypes: pointTypes,
      startTime: now.subtract(const Duration(minutes: 5)),
      endTime: now,
    );

    // --- 2️⃣ Cumulative metrics since midnight --------------------------
    final midnight = DateTime(now.year, now.month, now.day);
    final cumulativeTypes =
        repository.config.dataTypes.where((t) => t.isCumulative).toList();

    final cumulRes = await repository.getHealthData(
      dataTypes: cumulativeTypes,
      startTime: midnight,
      endTime: now,
    );

    // --- 3️⃣ Weight – most recent sample in last 30 days ---------------
    final weightRes = await repository.getHealthData(
      dataTypes: [WearableDataType.weight],
      startTime: now.subtract(const Duration(days: 30)),
      endTime: now,
    );

    // Keep only most recent weight sample.
    HealthSample? latestWeight;
    if (weightRes.samples.isNotEmpty) {
      weightRes.samples.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      latestWeight = weightRes.samples.first;
    }

    // --- 4️⃣ Sleep – previous night 18:00 → now -------------------------
    final sleepWindowStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(hours: 6));

    final sleepRes = await repository.getHealthData(
      dataTypes: [
        WearableDataType.sleepDuration,
        WearableDataType.sleepAwake,
        WearableDataType.sleepAsleep,
        WearableDataType.sleepDeep,
        WearableDataType.sleepLight,
        WearableDataType.sleepRem,
      ],
      startTime: sleepWindowStart,
      endTime: now,
    );

    // --- 5️⃣ Resting Heart Rate – latest in last 24 h ------------------
    final rhrRes = await repository.getHealthData(
      dataTypes: [WearableDataType.restingHeartRate],
      startTime: now.subtract(const Duration(hours: 24)),
      endTime: now,
    );

    HealthSample? latestRhr;
    if (rhrRes.samples.isNotEmpty) {
      rhrRes.samples.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      latestRhr = rhrRes.samples.first;
    }

    // ---------------- Merge & forward ----------------------------------
    final allSamples = [
      ...pointRes.samples,
      ...cumulRes.samples,
      if (latestWeight != null) latestWeight,
      if (latestRhr != null) latestRhr,
      ...sleepRes.samples,
    ];

    for (final s in allSamples) {
      final data = _toVitalsData(s);
      if (data != null) aggregator.add(data);
    }
  }

  Future<void> pollOnce() async {
    try {
      await _performCompositeFetch();
    } catch (_) {
      // snapshot best-effort
    }
  }

  VitalsData? _toVitalsData(HealthSample sample) {
    final ts = sample.timestamp;
    double? hr;
    int? steps;
    double? hrv;
    double? sleep;
    double? energy;
    double? weight;

    switch (sample.type) {
      case WearableDataType.heartRate:
      case WearableDataType.restingHeartRate:
        hr = NumericHelpers.toDouble(sample.value);
        break;
      case WearableDataType.steps:
        steps = NumericHelpers.toInt(sample.value);
        break;
      case WearableDataType.heartRateVariability:
        hrv = NumericHelpers.toDouble(sample.value);
        break;
      case WearableDataType.sleepDuration:
      case WearableDataType.sleepInBed:
      case WearableDataType.sleepDeep:
      case WearableDataType.sleepLight:
      case WearableDataType.sleepRem:
      case WearableDataType.sleepAsleep:
      case WearableDataType.sleepAwake:
        // We'll defer aggregation; still store per-sample (sleepKind meta)
        final minutes = NumericHelpers.toDouble(sample.value);
        if (minutes != null) sleep = minutes / 60.0;
        break;
      case WearableDataType.activeEnergyBurned:
        energy = NumericHelpers.toDouble(sample.value);
        break;
      case WearableDataType.weight:
        final kg = NumericHelpers.toDouble(sample.value);
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

    final meta = {'source': sample.source};

    // Mark sleep kind for aggregator fine-grain logic
    if (sample.type.name.startsWith('sleep')) {
      meta['sleepKind'] = _sleepKindForType(sample.type);
      meta['stageType'] = sample.type.name; // e.g., sleepDeep, sleepAsleep
      meta['sampleId'] = sample.id;
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
      metadata: meta,
    );
  }

  String _sleepKindForType(WearableDataType t) {
    switch (t) {
      case WearableDataType.sleepAwake:
        return 'awake';
      case WearableDataType.sleepInBed:
      case WearableDataType.sleepDuration:
        return 'inBed';
      default:
        return 'stage';
    }
  }
}
