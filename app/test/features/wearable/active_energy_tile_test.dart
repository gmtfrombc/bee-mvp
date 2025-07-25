import 'dart:async';

import 'package:app/core/providers/vitals_notifier_provider.dart';
import 'package:app/core/services/vitals_notifier_service.dart';
import 'package:app/features/wearable/ui/tiles/active_energy_tile.dart';
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
  group('ActiveEnergyTile', () {
    late StreamController<VitalsData> controller;
    late SupabaseClient dummyClient;

    setUp(() {
      controller = StreamController<VitalsData>.broadcast();
      dummyClient = SupabaseClient('https://localhost', 'anon-key');
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

    testWidgets('shows energy value when present', (tester) async {
      final data = VitalsData(activeEnergy: 250, timestamp: DateTime.now());
      await tester.pumpWidget(wrap(const ActiveEnergyTile()));
      controller.add(data);
      await tester.pumpAndSettle();

      expect(find.text('250'), findsOneWidget);
      expect(find.text('kcal'), findsOneWidget);
    });

    testWidgets('shows No stats when null', (tester) async {
      final data = VitalsData(timestamp: DateTime.now());
      await tester.pumpWidget(wrap(const ActiveEnergyTile()));
      controller.add(data);
      await tester.pumpAndSettle();

      expect(find.text('No stats'), findsOneWidget);
    });
  });
}
