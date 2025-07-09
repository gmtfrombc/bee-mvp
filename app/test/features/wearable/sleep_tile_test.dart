import 'dart:async';

import 'package:app/core/providers/vitals_notifier_provider.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/features/wearable/ui/tiles/sleep_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:app/core/providers/analytics_provider.dart';
import 'package:app/core/services/analytics_service.dart';

class _FakeAnalyticsService extends AnalyticsService {
  _FakeAnalyticsService(super.client);

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {}
}

void main() {
  group('SleepTile', () {
    late StreamController<VitalsData> controller;
    late SupabaseClient dummyClient;

    setUp(() {
      controller = StreamController<VitalsData>.broadcast();
      dummyClient = SupabaseClient('https://localhost', 'public-anon-key');
    });

    tearDown(() async {
      await controller.close();
    });

    Widget wrap(Widget child) => ProviderScope(
      overrides: [
        vitalsDataStreamProvider.overrideWith((ref) => controller.stream),
        supabaseClientProvider.overrideWithValue(dummyClient),
        analyticsServiceProvider.overrideWithValue(
          _FakeAnalyticsService(dummyClient),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );

    testWidgets('shows hours & minutes when data present', (tester) async {
      final data = VitalsData(sleepHours: 7.5, timestamp: DateTime.now());
      await tester.pumpWidget(wrap(const SleepTile()));
      controller.add(data);
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      expect(find.text('30'), findsOneWidget); // minutes displayed
    });

    testWidgets('shows No stats when null', (tester) async {
      final data = VitalsData(timestamp: DateTime.now());
      await tester.pumpWidget(wrap(const SleepTile()));
      controller.add(data);
      await tester.pumpAndSettle();

      expect(find.text('No sleep data'), findsOneWidget);
    });
  });
}
