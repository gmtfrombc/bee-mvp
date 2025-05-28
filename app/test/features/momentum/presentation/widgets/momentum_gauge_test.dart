import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/momentum/presentation/widgets/momentum_gauge.dart';

void main() {
  group('MomentumGauge Widget Tests', () {
    testWidgets('renders correctly with rising state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MomentumGauge(state: MomentumState.rising, percentage: 85.0),
          ),
        ),
      );

      // Verify the widget is rendered
      expect(find.byType(MomentumGauge), findsOneWidget);

      // Verify the emoji is displayed
      expect(find.text('🚀'), findsOneWidget);

      // Verify custom painter is present (there might be multiple CustomPaint widgets)
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders correctly with steady state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MomentumGauge(state: MomentumState.steady, percentage: 60.0),
          ),
        ),
      );

      expect(find.text('🙂'), findsOneWidget);
    });

    testWidgets('renders correctly with needs care state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MomentumGauge(
              state: MomentumState.needsCare,
              percentage: 30.0,
            ),
          ),
        ),
      );

      expect(find.text('🌱'), findsOneWidget);
    });

    testWidgets('handles tap interaction', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MomentumGauge(
              state: MomentumState.rising,
              percentage: 85.0,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the gauge
      await tester.tap(find.byType(MomentumGauge));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('has proper accessibility semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MomentumGauge(
              state: MomentumState.rising,
              percentage: 85.0,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify the specific semantics label is present
      final semanticsLabel = 'Momentum gauge showing rising state at 85%';

      // Check that our specific semantics are present
      expect(
        tester.getSemantics(find.byType(MomentumGauge)).label,
        contains(semanticsLabel),
      );

      // Verify the gauge widget itself is present
      expect(find.byType(MomentumGauge), findsOneWidget);
    });

    testWidgets('animation completes successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MomentumGauge(
              state: MomentumState.rising,
              percentage: 85.0,
              animationDuration: const Duration(
                milliseconds: 100,
              ), // Faster for testing
            ),
          ),
        ),
      );

      // Initial state
      await tester.pump();

      // Animation in progress
      await tester.pump(const Duration(milliseconds: 50));

      // Animation complete
      await tester.pump(const Duration(milliseconds: 100));

      // Verify no errors occurred during animation
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive gauge adapts to screen size', (
      WidgetTester tester,
    ) async {
      // Test small screen
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveMomentumGauge(
              state: MomentumState.rising,
              percentage: 85.0,
            ),
          ),
        ),
      );

      expect(find.byType(ResponsiveMomentumGauge), findsOneWidget);
      expect(find.byType(MomentumGauge), findsOneWidget);
    });

    testWidgets('updates when state changes', (WidgetTester tester) async {
      MomentumState currentState = MomentumState.rising;
      double currentPercentage = 85.0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    MomentumGauge(
                      state: currentState,
                      percentage: currentPercentage,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentState = MomentumState.needsCare;
                          currentPercentage = 30.0;
                        });
                      },
                      child: const Text('Change State'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Initial state
      expect(find.text('🚀'), findsOneWidget);

      // Change state
      await tester.tap(find.text('Change State'));
      await tester.pump();

      // Verify state changed
      expect(find.text('🌱'), findsOneWidget);
    });
  });

  group('MomentumGaugePainter Tests', () {
    test('should repaint when progress changes', () {
      final painter1 = MomentumGaugePainter(
        progress: 0.5,
        state: MomentumState.rising,
        strokeWidth: 8.0,
      );

      final painter2 = MomentumGaugePainter(
        progress: 0.8,
        state: MomentumState.rising,
        strokeWidth: 8.0,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('should repaint when state changes', () {
      final painter1 = MomentumGaugePainter(
        progress: 0.5,
        state: MomentumState.rising,
        strokeWidth: 8.0,
      );

      final painter2 = MomentumGaugePainter(
        progress: 0.5,
        state: MomentumState.steady,
        strokeWidth: 8.0,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('should not repaint when nothing changes', () {
      final painter1 = MomentumGaugePainter(
        progress: 0.5,
        state: MomentumState.rising,
        strokeWidth: 8.0,
      );

      final painter2 = MomentumGaugePainter(
        progress: 0.5,
        state: MomentumState.rising,
        strokeWidth: 8.0,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });
  });
}
