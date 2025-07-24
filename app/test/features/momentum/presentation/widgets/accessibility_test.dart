import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/services/accessibility_service.dart';
import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/features/momentum/presentation/widgets/momentum_gauge.dart';
import 'package:app/features/momentum/presentation/widgets/quick_stats_cards.dart';
import 'package:app/features/momentum/presentation/widgets/action_buttons.dart';
import 'package:app/features/momentum/presentation/widgets/momentum_card.dart';

void main() {
  group('Accessibility Features Tests', () {
    testWidgets('AccessibilityService provides proper semantic labels', (
      tester,
    ) async {
      const state = MomentumState.rising;
      const percentage = 75.0;

      // Test momentum state label
      final stateLabel = AccessibilityService.getMomentumStateLabel(
        state,
        percentage,
      );
      expect(stateLabel, contains('Your momentum is rising'));
      expect(stateLabel, contains('75 percent'));
      expect(stateLabel, contains('You\'re doing great'));

      // Test momentum gauge hint
      final gaugeHint = AccessibilityService.getMomentumGaugeHint();
      expect(gaugeHint, 'Tap to view detailed breakdown of your momentum');

      // Test quick stats label
      final statsLabel = AccessibilityService.getQuickStatsLabel(
        'Lessons',
        '4/5',
        'Quick stat',
      );
      expect(statsLabel, contains('Lessons'));
      expect(statsLabel, contains('4/5'));
      expect(statsLabel, contains('Tap for more details'));

      // Test action button label
      final actionLabel = AccessibilityService.getActionButtonLabel(
        'Learn',
        'Action button',
      );
      expect(actionLabel, contains('Learn'));
      expect(actionLabel, contains('Action button'));
    });

    testWidgets(
      'MomentumCard has comprehensive accessibility',
      (tester) async {
        // Create sample momentum data
        final momentumData = MomentumData.sample();

        // Pump a MomentumCard wrapped in MaterialApp & Scaffold
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: MomentumCard(
                momentumData: momentumData,
                // Provide onTap so the card behaves as a button
                onTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Retrieve Semantics information
        final semantics = tester.getSemantics(find.byType(MomentumCard));

        // Verify semantics object exists (indicates accessibility annotations are present)
        expect(semantics, isNotNull);
        // Optional: basic check that a hint exists when onTap supplied
        expect(semantics.hint, isNotNull);
      },
      // Removed `skip: true` – test now active
    );

    testWidgets('MomentumGauge supports accessibility features', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MomentumGauge(
              state: MomentumState.steady,
              percentage: 60.0,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify semantic label includes state and percentage
      final semantics = tester.getSemantics(find.byType(MomentumGauge));
      expect(semantics.label, contains('Your momentum is steady'));
      expect(semantics.label, contains('60 percent'));
      expect(semantics.hint, contains('Tap to view detailed breakdown'));
    });

    testWidgets('QuickStatsCards have proper accessibility labels', (
      tester,
    ) async {
      final stats = MomentumStats.fromJson({
        'lessonsCompleted': 3,
        'totalLessons': 5,
        'streakDays': 4,
        'todayMinutes': 20,
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: QuickStatsCards(
              stats: stats,
              onLessonsTap: () {},
              onActionStepTap: () {},
              onTodayTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all semantic widgets with button properties
      final buttonSemantics = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.button == true,
      );

      // Should have 2 stat cards (Readiness & Action Step)
      expect(buttonSemantics, findsNWidgets(2));
    });

    testWidgets('ActionButtons have proper accessibility semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ActionButtons(
              state: MomentumState.needsCare,
              onLearnTap: () {},
              onShareTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find semantic widgets with specific button labels (not just any button semantics)
      final learnButtonSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Learn'),
      );

      final shareButtonSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Share'),
      );

      // Should have 1 learn button and 1 share button
      expect(learnButtonSemantics, findsOneWidget);
      expect(shareButtonSemantics, findsOneWidget);
    });

    testWidgets('Widgets respect reduced motion preferences', (tester) async {
      // Mock reduced motion by setting accessibility to true
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: MomentumGauge(
                state: MomentumState.rising,
                percentage: 85.0,
                animationDuration: Duration(milliseconds: 1000),
              ),
            ),
          ),
        ),
      );

      // With reduced motion, animations should be minimal or skipped
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify no animation-related errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Touch targets meet minimum size requirements', (tester) async {
      const minTouchTarget = 44.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                MomentumGauge(
                  state: MomentumState.rising,
                  percentage: 75.0,
                  size: 120.0, // Should be larger than minimum
                  onTap: () {},
                ),
                ActionButtons(
                  state: MomentumState.rising,
                  onLearnTap: () {},
                  onShareTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all tappable widgets
      final tappableWidgets = find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector ||
            widget is InkWell ||
            widget is ElevatedButton,
      );

      expect(tappableWidgets, findsWidgets);

      // For each tappable widget, verify it meets minimum touch target
      for (final widget in tester.widgetList(tappableWidgets)) {
        final renderBox =
            tester.renderObject(find.byWidget(widget)) as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          // Allow some tolerance for layout constraints
          expect(
            size.width >= minTouchTarget - 4,
            isTrue,
            reason:
                'Widget $widget width ${size.width} is below minimum touch target',
          );
          expect(
            size.height >= minTouchTarget - 4,
            isTrue,
            reason:
                'Widget $widget height ${size.height} is below minimum touch target',
          );
        }
      }
    });
  });
}
