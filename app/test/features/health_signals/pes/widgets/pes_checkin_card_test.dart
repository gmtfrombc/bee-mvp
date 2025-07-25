import 'package:app/features/health_signals/pes/widgets/pes_checkin_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/health_signals/pes/widgets/energy_input_slider.dart';
import 'package:app/features/health_signals/pes/widgets/pes_trend_sparkline.dart';
import 'package:app/features/health_signals/pes/pes_providers.dart';
import 'package:app/core/health_data/models/pes_entry.dart';

void main() {
  group('PesCheckinCard', () {
    testWidgets('shows EnergyInputSlider when no entry today', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [todayPesEntryProvider.overrideWith((ref) async => null)],
          child: const MaterialApp(home: PesCheckinCard()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(EnergyInputSlider), findsOneWidget);
    });

    testWidgets('shows PesTrendSparkline when entry exists', (tester) async {
      final entry = PesEntry.newEntry(
        userId: 'uid',
        date: DateTime.now(),
        score: 4,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [todayPesEntryProvider.overrideWith((ref) async => entry)],
          child: const MaterialApp(home: PesCheckinCard()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PesTrendSparkline), findsOneWidget);
    });
  });
}
