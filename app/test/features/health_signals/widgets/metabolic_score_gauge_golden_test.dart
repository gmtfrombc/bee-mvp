library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/health_signals/widgets/metabolic_score_gauge.dart';

void main() {
  // Custom square device for gauge snapshot (200×200).
  const gaugeDevice = Device(name: 'gauge_200x200', size: Size(200, 200));

  GoldenToolkit.runWithConfiguration(
    () => _goldenTests(),
    config: GoldenToolkitConfiguration(
      enableRealShadows: false,
      defaultDevices: const [gaugeDevice],
      fileNameFactory: (name) => '../../../_goldens/health_signals/$name.png',
    ),
  );
}

void _goldenTests() {
  setUpAll(() async {
    await loadAppFonts();
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('MetabolicScoreGauge – Golden Tests', () {
    testGoldens('dark mode baseline', (tester) async {
      await tester.pumpWidgetBuilder(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Scaffold(
              body: Center(child: MetabolicScoreGauge(mhs: 45)),
            ),
          ),
        ),
      );

      await screenMatchesGolden(tester, 'metabolic_score_gauge_dark');
    });
  });
}
