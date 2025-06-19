import 'dart:async';

import 'package:app/core/providers/vitals_notifier_provider.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/features/wearable/ui/tiles/steps_tile.dart';
import 'package:app/features/wearable/ui/tiles/heart_rate_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vitals Tiles – fallback behaviour', () {
    testWidgets('StepsTile shows cached value when vitals stream is loading', (
      tester,
    ) async {
      // Prepare a dummy cached VitalsData
      final cached = VitalsData(
        steps: 1234,
        timestamp: DateTime(2025, 6, 20, 12, 0),
      );

      // A stream controller that never emits (remains loading)
      final controller = StreamController<VitalsData>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalsDataStreamProvider.overrideWith((_) => controller.stream),
            currentVitalsProvider.overrideWithValue(cached),
          ],
          child: const MaterialApp(home: Scaffold(body: StepsTile())),
        ),
      );

      // Expect the cached steps value to be rendered
      expect(find.text('1234'), findsOneWidget);
      // No spinner should be present
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('HeartRateTile renders timestamp and BPM with cached data', (
      tester,
    ) async {
      final ts = DateTime(2025, 6, 20, 15, 30);
      final cached = VitalsData(heartRate: 58, timestamp: ts);

      final controller = StreamController<VitalsData>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalsDataStreamProvider.overrideWith((_) => controller.stream),
            currentVitalsProvider.overrideWithValue(cached),
          ],
          child: const MaterialApp(home: Scaffold(body: HeartRateTile())),
        ),
      );

      // BPM value visible
      expect(find.text('58'), findsOneWidget);
      // Timestamp (formatted h:mm a) visible
      expect(find.text('3:30 PM'), findsOneWidget);
    });
  });
}
