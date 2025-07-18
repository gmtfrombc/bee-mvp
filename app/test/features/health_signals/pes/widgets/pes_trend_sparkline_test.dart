import 'package:app/features/health_signals/pes/widgets/pes_trend_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/health_data/models/energy_level.dart';
import 'package:app/features/health_signals/pes/pes_providers.dart';
import 'package:app/l10n/s.dart';

void main() {
  group('PesTrendSparkline', () {
    testWidgets('shows empty placeholder when no data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pesTrendProvider.overrideWith((ref) async => <EnergyLevelEntry>[]),
          ],
          child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: PesTrendSparkline(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Your energy trend will appear here after you log a few days.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders chart when 7 entries available', (tester) async {
      final sampleEntries = List.generate(7, (i) {
        return EnergyLevelEntry.newEntry(
          userId: 'uid',
          level: EnergyLevel.values[i % 5],
          recordedAt: DateTime.now().subtract(Duration(days: 6 - i)),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pesTrendProvider.overrideWith((ref) async => sampleEntries),
          ],
          child: const MaterialApp(home: PesTrendSparkline()),
        ),
      );

      await tester.pumpAndSettle();

      // Expect at least one FlChart widget present.
      expect(find.byType(PesTrendSparkline), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
