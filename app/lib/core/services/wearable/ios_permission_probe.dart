/// Lightweight HealthKit sample probe to infer read permission status on iOS.
///
/// Extracted from `wearable_data_repository.dart`.

library wearable.ios_permission_probe;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../wearable_data_models.dart';
import 'health_sample_mapper.dart';

const MethodChannel _iosReadProbeChannel = MethodChannel('health_read_probe');

/// Runs a native Swift query for recent [type] samples within [window].
/// Returns `true` when at least one sample exists – indicating that read
/// access is still granted.
Future<bool> iosProbeReadAccess({
  WearableDataType type = WearableDataType.steps,
  Duration window = const Duration(hours: 24),
}) async {
  try {
    final ok = await _iosReadProbeChannel.invokeMethod<bool>('probe', {
      'id': hkIdentifierFromWearableDataType(type),
      'interval': window.inSeconds,
    });
    return ok == true;
  } catch (e) {
    debugPrint('iOS read-probe failed: $e');
    return false;
  }
}
