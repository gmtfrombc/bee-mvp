import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/health_signals/pes/widgets/energy_input_slider.dart';
import 'package:app/features/health_signals/pes/pes_providers.dart';

void main() {
  group('EnergyInputSlider', () {
    testWidgets('selecting an emoji updates the provider', (tester) async {
      // Create a container to inspect provider state.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Build the widget under test.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: EnergyInputSlider()),
          ),
        ),
      );

      // Score 3 corresponds to the neutral emoji 😐
      final emojiFinder = find.text('😐');
      expect(emojiFinder, findsOneWidget);

      // Tap the emoji.
      await tester.tap(emojiFinder);
      await tester.pumpAndSettle();

      // Verify provider state updated.
      expect(container.read(energyScoreProvider), equals(3));
    });
  });
}
