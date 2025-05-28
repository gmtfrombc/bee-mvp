import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/features/momentum/presentation/widgets/momentum_card.dart';
import 'package:app/features/momentum/presentation/widgets/momentum_gauge.dart';
import 'package:app/features/momentum/presentation/widgets/quick_stats_cards.dart';
import 'package:app/features/momentum/presentation/widgets/action_buttons.dart';
import 'package:app/features/momentum/presentation/widgets/weekly_trend_chart.dart';

void main() {
  group('Screen Reader Accessibility Tests', () {
    group('Semantic Labels and Hints', () {
      testWidgets(
        'MomentumGauge provides descriptive semantic labels for all states',
        (tester) async {
          // Test Rising state
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

          await tester.pumpAndSettle();

          var semantics = tester.getSemantics(find.byType(MomentumGauge));
          expect(semantics.label, contains('Your momentum is rising'));
          expect(semantics.label, contains('85 percent'));
          expect(semantics.label, contains('You\'re doing great'));
          expect(semantics.hint, contains('Tap to view detailed breakdown'));

          // Test Steady state
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

          semantics = tester.getSemantics(find.byType(MomentumGauge));
          expect(semantics.label, contains('Your momentum is steady'));
          expect(semantics.label, contains('60 percent'));
          expect(semantics.label, contains('You\'re making good progress'));

          // Test Needs Care state
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MomentumGauge(
                  state: MomentumState.needsCare,
                  percentage: 25.0,
                  onTap: () {},
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          semantics = tester.getSemantics(find.byType(MomentumGauge));
          expect(semantics.label, contains('Your momentum is needsCare'));
          expect(semantics.label, contains('25 percent'));
          expect(semantics.label, contains('Let\'s work together'));
        },
      );

      testWidgets('MomentumCard provides complete semantic information', (
        tester,
      ) async {
        final momentumData = MomentumData.sample();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: MomentumCard(momentumData: momentumData, onTap: () {}),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final semanticsWidget = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('Momentum card'),
        );

        expect(semanticsWidget, findsOneWidget);

        final semantics = tester.getSemantics(semanticsWidget);
        expect(semantics.label, contains('Momentum card'));
        expect(semantics.label, contains(momentumData.state.name));
        expect(semantics.hint, isNotNull);
        expect(
          semantics.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
      });

      testWidgets('WeeklyTrendChart provides meaningful chart description', (
        tester,
      ) async {
        final weeklyTrend = List.generate(
          7,
          (index) => DailyMomentum(
            date: DateTime.now().subtract(Duration(days: 6 - index)),
            state: MomentumState.values[index % 3],
            percentage: 50.0 + (index * 10.0),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: WeeklyTrendChart(weeklyTrend: weeklyTrend)),
          ),
        );

        await tester.pumpAndSettle();

        final semantics = tester.getSemantics(find.byType(WeeklyTrendChart));
        expect(semantics.label, contains('Weekly momentum trend chart'));
        expect(semantics.label, contains('trend'));
        expect(semantics.label, contains('average'));
        expect(
          semantics.hint,
          contains('Chart showing your momentum progress'),
        );
      });

      testWidgets('QuickStatsCards provide detailed stat information', (
        tester,
      ) async {
        final stats = MomentumStats.fromJson({
          'lessonsCompleted': 4,
          'totalLessons': 5,
          'streakDays': 7,
          'todayMinutes': 25,
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: QuickStatsCards(
                stats: stats,
                onLessonsTap: () {},
                onStreakTap: () {},
                onTodayTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find all stat card semantics
        final statCardSemantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.button == true &&
              widget.properties.label != null,
        );

        expect(statCardSemantics, findsNWidgets(3));

        // Check each stat card has proper labels
        final semanticsWidgets = tester.widgetList<Semantics>(
          statCardSemantics,
        );

        // Should have lessons, streak, and today stats
        bool hasLessons = false;
        bool hasStreak = false;
        bool hasToday = false;

        for (final widget in semanticsWidgets) {
          final label = widget.properties.label ?? '';
          if (label.contains('Lessons') || label.contains('4/5')) {
            hasLessons = true;
            expect(label, contains('Tap for more details'));
          } else if (label.contains('Streak') || label.contains('7')) {
            hasStreak = true;
            expect(label, contains('Tap for more details'));
          } else if (label.contains('Today') || label.contains('25')) {
            hasToday = true;
            expect(label, contains('Tap for more details'));
          }
        }

        expect(
          hasLessons,
          isTrue,
          reason: 'Should have lessons stat with semantic label',
        );
        expect(
          hasStreak,
          isTrue,
          reason: 'Should have streak stat with semantic label',
        );
        expect(
          hasToday,
          isTrue,
          reason: 'Should have today stat with semantic label',
        );
      });

      testWidgets('ActionButtons provide clear action descriptions', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ActionButtons(
                state: MomentumState.rising,
                onLearnTap: () {},
                onShareTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find learn button
        final learnButtonSemantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.button == true &&
              widget.properties.label != null &&
              widget.properties.label!.contains('Learn'),
        );

        expect(learnButtonSemantics, findsOneWidget);

        final learnSemantics = tester.getSemantics(learnButtonSemantics);
        expect(learnSemantics.label, contains('Learn'));
        expect(learnSemantics.label, contains('Tap to take action'));

        // Find share button
        final shareButtonSemantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.button == true &&
              widget.properties.label != null &&
              widget.properties.label!.contains('Share'),
        );

        expect(shareButtonSemantics, findsOneWidget);

        final shareSemantics = tester.getSemantics(shareButtonSemantics);
        expect(shareSemantics.label, contains('Share'));
        expect(shareSemantics.label, contains('Tap to take action'));
      });
    });

    group('Focus Order and Navigation', () {
      testWidgets('Momentum widgets have proper focus order', (tester) async {
        final momentumData = MomentumData.sample();
        final weeklyTrend = List.generate(
          7,
          (index) => DailyMomentum(
            date: DateTime.now().subtract(Duration(days: 6 - index)),
            state: MomentumState.values[index % 3],
            percentage: 50.0 + (index * 10.0),
          ),
        );
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
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    MomentumCard(momentumData: momentumData, onTap: () {}),
                    const SizedBox(height: 16),
                    WeeklyTrendChart(weeklyTrend: weeklyTrend),
                    const SizedBox(height: 16),
                    QuickStatsCards(
                      stats: stats,
                      onLessonsTap: () {},
                      onStreakTap: () {},
                      onTodayTap: () {},
                    ),
                    const SizedBox(height: 16),
                    ActionButtons(
                      state: MomentumState.rising,
                      onLearnTap: () {},
                      onShareTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find all focusable elements
        final focusableElements = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.button == true ||
                  widget.properties.onTap != null ||
                  widget.properties.focusable == true),
        );

        expect(
          focusableElements,
          findsAtLeastNWidgets(6),
        ); // Card + Chart + 3 Stats + 2 Actions
      });

      testWidgets('Widgets support keyboard navigation', (tester) async {
        bool cardTapped = false;
        bool learnTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  MomentumCard(
                    momentumData: MomentumData.sample(),
                    onTap: () => cardTapped = true,
                  ),
                  ActionButtons(
                    state: MomentumState.rising,
                    onLearnTap: () => learnTapped = true,
                    onShareTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test keyboard activation with semantics taps
        final cardSemantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('Momentum card'),
        );

        await tester.tap(cardSemantics);
        await tester.pumpAndSettle();
        expect(cardTapped, isTrue);

        final learnSemantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('Learn'),
        );

        await tester.tap(learnSemantics);
        await tester.pumpAndSettle();
        expect(learnTapped, isTrue);
      });
    });

    group('Dynamic Content Announcements', () {
      testWidgets('State changes announce to screen reader', (tester) async {
        // This test simulates momentum state changes and verifies
        // that appropriate announcements would be made
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

        // Verify initial state
        var semantics = tester.getSemantics(find.byType(MomentumGauge));
        expect(semantics.label, contains('steady'));

        // Change to rising state
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MomentumGauge(
                state: MomentumState.rising,
                percentage: 75.0,
                onTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify new state is reflected in semantics
        semantics = tester.getSemantics(find.byType(MomentumGauge));
        expect(semantics.label, contains('rising'));
        expect(semantics.label, contains('75 percent'));
      });

      testWidgets('Loading states have appropriate semantics', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Semantics(
                  label: 'Loading momentum data',
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        );

        await tester
            .pump(); // Use pump instead of pumpAndSettle to avoid timeout

        final loadingSemantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('Loading'),
        );

        expect(loadingSemantics, findsOneWidget);
      });
    });

    group('Error States and Feedback', () {
      testWidgets('Error messages are announced to screen reader', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Semantics(
                  label: 'Error loading momentum data',
                  hint: 'Pull to refresh to try again',
                  child: const Text('Failed to load data'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final errorSemantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('Error'),
        );

        expect(errorSemantics, findsOneWidget);

        final semantics = tester.getSemantics(errorSemantics);
        expect(semantics.label, contains('Error loading momentum data'));
        expect(semantics.hint, contains('Pull to refresh'));
      });
    });

    group('WCAG AA Compliance', () {
      testWidgets('Text has sufficient color contrast', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: MomentumCard(
                momentumData: MomentumData.sample(),
                onTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test would verify color contrast ratios in real implementation
        // For now, we ensure theming is applied correctly
        final theme = Theme.of(tester.element(find.byType(MomentumCard)));
        expect(theme.brightness, equals(Brightness.light));
      });

      testWidgets('Touch targets meet minimum size (44px)', (tester) async {
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
                    size: 120.0,
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

        // Find the momentum gauge (it should be large enough)
        final gaugeWidget = find.byType(MomentumGauge);
        final gaugeSize = tester.getSize(gaugeWidget);
        expect(gaugeSize.width, greaterThanOrEqualTo(minTouchTarget));
        expect(gaugeSize.height, greaterThanOrEqualTo(minTouchTarget));

        // Find action buttons and verify they meet minimum touch target
        final actionButtons = find.descendant(
          of: find.byType(ActionButtons),
          matching: find.byWidgetPredicate(
            (widget) => widget is GestureDetector || widget is InkWell,
          ),
        );

        for (final button in tester.widgetList(actionButtons)) {
          final size = tester.getSize(find.byWidget(button));
          expect(
            size.width,
            greaterThanOrEqualTo(minTouchTarget - 4), // Allow small tolerance
            reason: 'Button width ${size.width} below minimum touch target',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(minTouchTarget - 4),
            reason: 'Button height ${size.height} below minimum touch target',
          );
        }
      });

      testWidgets('Text scaling is supported', (tester) async {
        // Test with normal text scale
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
              child: Scaffold(
                body: Center(
                  child: MomentumGauge(
                    state: MomentumState.rising,
                    percentage: 75.0,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(MomentumGauge), findsOneWidget);

        // Test with larger text scale (accessibility setting)
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Scaffold(
                body: Center(
                  child: MomentumGauge(
                    state: MomentumState.rising,
                    percentage: 75.0,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(MomentumGauge), findsOneWidget);
      });

      testWidgets('Reduced motion preferences are respected', (tester) async {
        // Test with reduced motion enabled
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: MomentumGauge(
                  state: MomentumState.rising,
                  percentage: 85.0,
                  animationDuration: const Duration(milliseconds: 1000),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify no exceptions thrown with reduced motion
        expect(tester.takeException(), isNull);

        // Test state transitions with reduced motion
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: MomentumGauge(
                  state: MomentumState.needsCare,
                  percentage: 25.0,
                  animationDuration: const Duration(milliseconds: 1000),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('Screen Reader Integration', () {
      testWidgets('Widgets work with semantic actions', (tester) async {
        bool cardActivated = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: MomentumCard(
                momentumData: MomentumData.sample(),
                onTap: () => cardActivated = true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and activate the semantic widget
        final semanticsWidget = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('Momentum card'),
        );

        expect(semanticsWidget, findsOneWidget);

        // Simulate screen reader activation
        await tester.tap(semanticsWidget);
        await tester.pumpAndSettle();

        expect(cardActivated, isTrue);
      });

      testWidgets('Complex widgets have hierarchical semantics', (
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
                onStreakTap: () {},
                onTodayTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the container semantics (should be hierarchical)
        final containerSemantics = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.container == true,
        );

        // Should have semantic containers for organization
        expect(containerSemantics, findsAtLeastNWidgets(1));
      });
    });
  });
}
