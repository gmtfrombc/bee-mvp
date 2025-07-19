import 'package:app/features/profile/presentation/widgets/metabolic_health_tile.dart';
import 'package:app/features/health_signals/biometrics/providers/metabolic_health_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MetabolicHealthTile displays score and chart', (tester) async {
    const testScore = 75.0;
    final testHistory = List<double>.generate(30, (i) => testScore - i);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          latestMhsProvider.overrideWith((ref) async => testScore),
          mhsThirtyDayHistoryProvider.overrideWith((ref) async => testHistory),
        ],
        child: const MaterialApp(home: Scaffold(body: MetabolicHealthTile())),
      ),
    );

    // Wait for build.
    await tester.pumpAndSettle();

    expect(find.text('75'), findsOneWidget);
    expect(find.byType(MetabolicHealthTile), findsOneWidget);
  });
}
