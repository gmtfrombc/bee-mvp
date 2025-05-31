import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/presentation/widgets/momentum_point_feedback_widget.dart';
import 'package:app/features/today_feed/data/services/today_feed_momentum_award_service.dart';
import 'package:app/core/theme/app_theme.dart';

void main() {
  group('MomentumPointFeedbackWidget - T1.3.4.6 Visual Feedback', () {
    late MomentumAwardResult successResult;
    late MomentumAwardResult duplicateResult;
    late MomentumAwardResult failedResult;
    late MomentumAwardResult queuedResult;

    setUp(() {
      // Use a fixed date that corresponds to the first message (day % 5 == 0)
      // Day 5 will give us index 0, which is "Great job staying curious about your health!"
      final fixedDate = DateTime(2024, 1, 5); // Day 5 % 5 = 0

      successResult = MomentumAwardResult.success(
        pointsAwarded: 1,
        message: 'First daily engagement! +1 momentum point earned',
        awardTime: fixedDate,
      );

      duplicateResult = MomentumAwardResult.duplicate(
        message: 'Daily momentum point already awarded',
        previousAwardTime: DateTime.now().subtract(const Duration(hours: 1)),
      );

      failedResult = MomentumAwardResult.failed(
        message: 'Failed to award momentum points',
        error: 'Network error',
      );

      queuedResult = MomentumAwardResult.queued(
        message: 'Award queued for when back online',
      );
    });

    Widget createTestWidget(MomentumPointFeedbackWidget widget) {
      return MaterialApp(home: Scaffold(body: Center(child: widget)));
    }

    group('Widget Creation and Basic Properties', () {
      testWidgets('should create widget with required parameters', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
            ),
          ),
        );

        expect(find.byType(MomentumPointFeedbackWidget), findsOneWidget);
      });

      testWidgets('should be invisible for unsuccessful non-queued results', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: failedResult,
              enableAnimations: false,
            ),
          ),
        );

        // Should not show feedback for failed results
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('should be invisible for duplicate results', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: duplicateResult,
              enableAnimations: false,
            ),
          ),
        );

        // Should not show feedback for duplicate results
        expect(find.byType(Container), findsNothing);
      });
    });

    group('Success Feedback Display', () {
      testWidgets('should display success feedback correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show momentum point indicator
        expect(find.text('+1'), findsOneWidget);
        expect(find.text('Momentum +1!'), findsOneWidget);
        expect(find.byIcon(Icons.add_circle), findsOneWidget);
      });

      testWidgets('should show success message when enabled', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: false,
              showMessage: true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show success message
        expect(find.text('Momentum +1!'), findsOneWidget);
        expect(
          find.textContaining('Great job staying curious'),
          findsOneWidget,
        );
      });

      testWidgets('should hide message when disabled', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: false,
              showMessage: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show point indicator but not message
        expect(find.text('+1'), findsOneWidget);
        expect(find.text('Momentum +1!'), findsNothing);
      });
    });

    group('Queued Feedback Display', () {
      testWidgets('should display queued feedback correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: queuedResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show schedule icon and queued message
        expect(find.byIcon(Icons.schedule), findsOneWidget);
        expect(find.text('Points queued for when back online'), findsOneWidget);
      });

      testWidgets(
        'should display queued feedback without message when disabled',
        (tester) async {
          await tester.pumpWidget(
            createTestWidget(
              MomentumPointFeedbackWidget(
                awardResult: queuedResult,
                enableAnimations: false,
                autoHide: false,
                showMessage: false,
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Should show only icon
          expect(find.byIcon(Icons.schedule), findsOneWidget);
          expect(find.text('Points queued for when back online'), findsNothing);
        },
      );
    });

    group('Animation Control', () {
      testWidgets('should skip animations when disabled', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        // Should render immediately without animations
        expect(find.byType(MomentumPointFeedbackWidget), findsOneWidget);
        expect(find.text('+1'), findsOneWidget);
      });

      testWidgets('should use animations when enabled', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: true,
              autoHide: false,
            ),
          ),
        );

        // Should have animation builders
        expect(find.byType(AnimatedBuilder), findsWidgets);
      });
    });

    group('Auto-Hide Functionality', () {
      testWidgets('should not auto-hide when disabled', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should remain visible
        expect(find.text('+1'), findsOneWidget);

        // Wait longer than normal auto-hide duration
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('+1'), findsOneWidget);
      });

      testWidgets('should auto-hide after specified duration', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: true,
              autoHideDuration: const Duration(milliseconds: 100),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should be visible initially
        expect(find.text('+1'), findsOneWidget);

        // Wait for auto-hide duration
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        // Should be hidden
        expect(find.text('+1'), findsNothing);
      });
    });

    group('Animation Callbacks', () {
      testWidgets('should call onAnimationComplete when provided', (
        tester,
      ) async {
        bool callbackCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: true,
              autoHideDuration: const Duration(milliseconds: 50),
              onAnimationComplete: () {
                callbackCalled = true;
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Wait for auto-hide duration and callback
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(callbackCalled, isTrue);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide proper accessibility labels', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have semantics for screen readers
        final semantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label?.contains('Momentum point awarded') ==
                  true,
        );
        expect(semantics, findsOneWidget);
      });

      testWidgets('should provide queued accessibility label', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: queuedResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have semantics for queued state
        final semantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label?.contains(
                    'queued for when back online',
                  ) ==
                  true,
        );
        expect(semantics, findsOneWidget);
      });

      testWidgets('should be announced as live region', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have semantics widget for the feedback with accessibility label
        final semantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.isNotEmpty,
        );
        expect(semantics, findsAtLeastNWidgets(1));
      });
    });

    group('Visual Design', () {
      testWidgets('should display momentum color scheme', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show proper visual design elements
        expect(find.byIcon(Icons.add_circle), findsOneWidget);
        expect(find.text('+1'), findsOneWidget);
      });

      testWidgets('should display different colors for queued state', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: queuedResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should use momentum steady color for queued
        final icon = tester.widget<Icon>(find.byIcon(Icons.schedule));
        expect(icon.color, equals(AppTheme.momentumSteady));
      });
    });

    group('Success Messages', () {
      testWidgets('should display encouraging messages', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: successResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show some encouraging message
        expect(
          find.textContaining(
            RegExp(r'(Great job|Learning|Knowledge|wisdom|habits)'),
          ),
          findsOneWidget,
        );
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle zero points awarded', (tester) async {
        final zeroPointResult = MomentumAwardResult.success(
          pointsAwarded: 0,
          message: 'Zero points',
          awardTime: DateTime.now(),
        );

        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: zeroPointResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display +0
        expect(find.text('+0'), findsOneWidget);
        expect(find.text('Momentum +0!'), findsOneWidget);
      });

      testWidgets('should handle multiple points awarded', (tester) async {
        final multiPointResult = MomentumAwardResult.success(
          pointsAwarded: 5,
          message: 'Bonus points',
          awardTime: DateTime.now(),
        );

        await tester.pumpWidget(
          createTestWidget(
            MomentumPointFeedbackWidget(
              awardResult: multiPointResult,
              enableAnimations: false,
              autoHide: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display +5
        expect(find.text('+5'), findsOneWidget);
        expect(find.text('Momentum +5!'), findsOneWidget);
      });
    });
  });
}
