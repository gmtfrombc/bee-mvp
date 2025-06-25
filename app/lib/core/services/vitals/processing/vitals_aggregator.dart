import 'dart:async';

import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/core/services/vitals/processing/step_deduplicator.dart';

/// Maintains a rolling history buffer of [VitalsData] samples and emits
/// aggregated "summary" records (steps-today, energy-today, nightly sleep).
class VitalsAggregator {
  VitalsAggregator({
    this.retentionWindow = const Duration(hours: 24),
    this.maxHistorySize = 200,
  });

  /// How long to retain samples in memory.
  final Duration retentionWindow;

  /// Maximum number of items kept irrespective of [retentionWindow].
  final int maxHistorySize;

  final List<VitalsData> _history = <VitalsData>[];

  VitalsData? _current; // last merged snapshot

  final StreamController<VitalsData> _out =
      StreamController<VitalsData>.broadcast();

  /// Stream of merged + aggregated records for UI or downstream consumers.
  Stream<VitalsData> get stream => _out.stream;

  /// Latest merged snapshot (may include aggregated fields).
  VitalsData? get current => _current;

  /// Unmodifiable view of raw history (incl. aggregated markers).
  List<VitalsData> get history => List.unmodifiable(_history);

  /// Adds [data] to the buffer, updates [_current], and emits any derived
  /// aggregations. Aggregated records are tagged with `metadata['aggregated']`
  /// so upstream logic can differentiate them from raw samples.
  void add(VitalsData data) {
    _history.add(data);
    _cleanupHistory();

    // Merge with previous so missing values are preserved.
    _mergeAndEmit(data);

    // Perform aggregations when relevant raw sample types arrive.
    if (data.hasSteps) _emitAggregatedSteps();
    if (data.hasEnergy) _emitAggregatedActiveEnergy();
    if (data.hasSleep) _emitAggregatedSleep();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------
  void _cleanupHistory() {
    final cutoff = DateTime.now().subtract(retentionWindow);
    _history.removeWhere((d) => d.timestamp.isBefore(cutoff));

    if (_history.length > maxHistorySize) {
      final excess = _history.length - maxHistorySize;
      _history.removeRange(0, excess);
    }
  }

  void _mergeAndEmit(VitalsData incoming) {
    // Skip raw step-only or sleep segment samples from being emitted directly.
    final isRawStepOnly =
        incoming.hasSteps &&
        !incoming.hasHeartRate &&
        !incoming.hasSleep &&
        (incoming.metadata['aggregated'] != true);

    final isRawSleepSegment =
        incoming.hasSleep && (incoming.metadata['aggregated'] != true);

    if (isRawStepOnly || isRawSleepSegment) return;

    VitalsData merged = incoming;
    if (_current != null) {
      merged = _current!.copyWith(
        heartRate: incoming.heartRate ?? _current!.heartRate,
        steps: incoming.steps ?? _current!.steps,
        heartRateVariability:
            incoming.heartRateVariability ?? _current!.heartRateVariability,
        sleepHours: incoming.sleepHours ?? _current!.sleepHours,
        activeEnergy: incoming.activeEnergy ?? _current!.activeEnergy,
        weight: incoming.weight ?? _current!.weight,
        timestamp: incoming.timestamp,
        quality: incoming.quality,
        metadata: incoming.metadata,
      );
    }
    _current = merged;
    _out.add(merged);
  }

  // ---------------- Aggregations --------------------------------------------
  int? _calculateStepsToday() {
    final midnight = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final rawToday =
        _history.where((d) {
          return d.hasSteps &&
              !d.timestamp.isBefore(midnight) &&
              d.metadata['aggregated'] != true;
        }).toList();

    return StepDeduplicator.sumSteps(rawToday);
  }

  double? _calculateActiveEnergyToday() {
    final midnight = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final samples = _history.where((d) {
      return d.hasEnergy &&
          !d.timestamp.isBefore(midnight) &&
          d.metadata['aggregated'] != true;
    });

    if (samples.isEmpty) return null;
    return samples
        .map((d) => d.activeEnergy ?? 0)
        .fold<double>(0, (prev, e) => prev + e);
  }

  void _emitAggregatedSteps() {
    final total = _calculateStepsToday();
    if (total == null || total == 0) return;

    final now = DateTime.now();

    final aggregated = VitalsData(
      steps: total,
      timestamp: now,
      quality: VitalsQuality.good,
      metadata: const {'aggregated': true},
    );
    _history.add(aggregated);
    _mergeAndEmit(aggregated);
  }

  void _emitAggregatedActiveEnergy() {
    final total = _calculateActiveEnergyToday();
    if (total == null || total == 0) return;

    final aggregated = VitalsData(
      activeEnergy: total,
      timestamp: DateTime.now(),
      quality: VitalsQuality.good,
      metadata: const {'aggregated': true},
    );
    _history.add(aggregated);
    _mergeAndEmit(aggregated);
  }

  void _emitAggregatedSleep() {
    // Analysis window: yesterday 6 PM → now.
    final now = DateTime.now();
    final analysisStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(hours: 6));

    double maxMinutesInBed = 0;
    double minutesAwake = 0;
    double minutesStages = 0;

    for (final d in _history) {
      if (!d.hasSleep) continue;
      if (d.timestamp.isBefore(analysisStart)) continue;
      if (d.metadata['aggregated'] == true) continue;

      final kind = d.metadata['sleepKind']?.toString() ?? 'unknown';
      final minutes = (d.sleepHours ?? 0) * 60;

      if (kind == 'awake') {
        minutesAwake += minutes;
      } else if (kind == 'inBed') {
        if (minutes > maxMinutesInBed) maxMinutesInBed = minutes;
      } else if (kind == 'stage') {
        minutesStages += minutes;
      }
    }

    double candidateInBed = maxMinutesInBed - minutesAwake;
    if (candidateInBed < 0) candidateInBed = 0;
    double candidateStages = minutesStages;

    final restfulMinutes =
        (candidateInBed > candidateStages) ? candidateInBed : candidateStages;

    if (restfulMinutes <= 0) return;

    final aggregated = VitalsData(
      sleepHours: restfulMinutes / 60.0,
      timestamp: now,
      quality: VitalsQuality.good,
      metadata: const {'aggregated': true},
    );

    _history.add(aggregated);
    _mergeAndEmit(aggregated);
  }
}
