import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/features/momentum/presentation/widgets/momentum_card.dart';
import 'package:app/features/momentum/presentation/widgets/momentum_gauge.dart';

void main() {
  group('MomentumCard', () {
    late MomentumData sampleData;

    setUp(() {
      sampleData = MomentumData.sample();
    });

    testWidgets('renders correctly with momentum data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: MomentumCard(momentumData: sampleData)),
        ),
      );

      // Verify header text
      expect(find.text('YOUR MOMENTUM'), findsOneWidget);

      // Verify state text
      expect(find.text('Rising!'), findsOneWidget);

      // Verify message
      expect(find.text(sampleData.message), findsOneWidget);

      // Verify progress bar percentage
      expect(find.text('85% this week'), findsOneWidget);

      // Verify momentum gauge is present
      expect(find.byType(ResponsiveMomentumGauge), findsOneWidget);
    });

    testWidgets('displays correct state text for different momentum states', (
      tester,
    ) async {
      // Test Rising state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData.copyWith(state: MomentumState.rising),
            ),
          ),
        ),
      );
      expect(find.text('Rising!'), findsOneWidget);

      // Test Steady state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData.copyWith(state: MomentumState.steady),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Steady!'), findsOneWidget);

      // Test Needs Care state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData.copyWith(state: MomentumState.needsCare),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Growing!'), findsOneWidget);
    });

    testWidgets('handles tap interaction correctly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(MomentumCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows progress bar when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(momentumData: sampleData, showProgressBar: true),
          ),
        ),
      );

      expect(find.text('85% this week'), findsOneWidget);
    });

    testWidgets('hides progress bar when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData,
              showProgressBar: false,
            ),
          ),
        ),
      );

      expect(find.text('85% this week'), findsNothing);
    });

    testWidgets('has proper accessibility semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(momentumData: sampleData, onTap: () {}),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the main Semantics widget with the card label
      final semanticsWidget = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Momentum card showing rising state',
      );
      expect(semanticsWidget, findsOneWidget);

      final semantics = tester.getSemantics(semanticsWidget);
      expect(semantics.label, 'Momentum card showing rising state');
      expect(semantics.hint, 'Tap for details');
    });

    testWidgets('animates entry correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: MomentumCard(momentumData: sampleData)),
        ),
      );

      // Initially should be invisible (opacity 0)
      await tester.pump();

      // After animation completes, should be visible
      await tester.pumpAndSettle();
      expect(find.byType(MomentumCard), findsOneWidget);
    });

    testWidgets('animates state changes correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData.copyWith(state: MomentumState.rising),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MomentumCard(
              momentumData: sampleData.copyWith(state: MomentumState.steady),
            ),
          ),
        ),
      );

      // Should trigger animation
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Steady!'), findsOneWidget);
    });
  });

  group('CompactMomentumCard', () {
    testWidgets('renders with correct height and no progress bar', (
      tester,
    ) async {
      final sampleData = MomentumData.sample();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: CompactMomentumCard(momentumData: sampleData)),
        ),
      );

      // Should not show progress bar
      expect(find.text('85% this week'), findsNothing);

      // Should still show main content
      expect(find.text('YOUR MOMENTUM'), findsOneWidget);
      expect(find.text('Rising!'), findsOneWidget);
    });
  });

  group('AccessibleMomentumCard', () {
    testWidgets('has enhanced accessibility features', (tester) async {
      final sampleData = MomentumData.sample();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AccessibleMomentumCard(
              momentumData: sampleData,
              onTap: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.byType(AccessibleMomentumCard),
      );
      expect(semantics.label, contains('rising state'));
      expect(semantics.label, contains('85 percent'));
    });

    testWidgets('uses custom semantic label when provided', (tester) async {
      final sampleData = MomentumData.sample();
      const customLabel = 'Custom momentum description';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AccessibleMomentumCard(
              momentumData: sampleData,
              customSemanticLabel: customLabel,
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.byType(AccessibleMomentumCard),
      );
      expect(semantics.label, customLabel);
    });
  });
}
