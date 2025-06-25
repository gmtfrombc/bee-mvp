import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/vitals/adapters/live_adapter.dart';
import 'package:app/core/services/vitals/processing/vitals_aggregator.dart';
import 'package:app/core/services/wearable_live_models.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  test(
    'LiveAdapter converts messages to VitalsData and feeds aggregator',
    () async {
      final aggregator = VitalsAggregator();
      final adapter = LiveAdapter(aggregator: aggregator);

      final controller = StreamController<List<WearableLiveMessage>>();
      adapter.start(controller.stream);

      final msg = WearableLiveMessage(
        timestamp: DateTime(2025, 6, 25, 12, 0),
        type: WearableDataType.heartRate,
        value: 80,
        source: 'watch',
      );

      controller.add([msg]);
      await Future.delayed(Duration.zero);

      expect(aggregator.current?.heartRate, 80);

      await adapter.stop();
      await controller.close();
    },
  );
}
