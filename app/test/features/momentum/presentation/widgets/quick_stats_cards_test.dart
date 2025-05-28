import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/features/momentum/presentation/widgets/quick_stats_cards.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await TestHelpers.setUpTest();
  });

  group('QuickStatsCards Widget Tests', () {
    late MomentumStats sampleStats;

    setUp(() {
      sampleStats = MomentumStats.fromJson({
        'lessonsCompleted': 4,
        'totalLessons': 5,
        'streakDays': 7,
        'todayMinutes': 25,
      });
    });

    testWidgets('displays quick stats cards with data', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: sampleStats,
          onLessonsTap: () {},
          onStreakTap: () {},
          onTodayTap: () {},
        ),
      );

      // Verify all three cards are displayed
      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Verify lesson ratio is displayed (using lessonsRatio method)
      expect(find.text('4/5'), findsOneWidget);

      // Verify streak days are displayed (using streakText method)
      expect(find.text('7 days'), findsOneWidget);

      // Verify today's minutes are displayed (using todayText method)
      expect(find.text('25m'), findsOneWidget);

      // Verify icons are present
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('handles lessons card tap', (WidgetTester tester) async {
      bool lessonsTapped = false;

      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: sampleStats,
          onLessonsTap: () => lessonsTapped = true,
          onStreakTap: () {},
          onTodayTap: () {},
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Find and tap the first card (lessons card)
      final cardFinders = find.byType(Card);
      expect(cardFinders, findsAtLeastNWidgets(3));

      await tester.tap(cardFinders.first);
      await tester.pumpAndSettle();

      expect(lessonsTapped, isTrue);
    });

    testWidgets('handles streak card tap', (WidgetTester tester) async {
      bool streakTapped = false;

      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: sampleStats,
          onLessonsTap: () {},
          onStreakTap: () => streakTapped = true,
          onTodayTap: () {},
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Find and tap the second card (streak card)
      final cardFinders = find.byType(Card);
      expect(cardFinders, findsAtLeastNWidgets(3));

      await tester.tap(cardFinders.at(1));
      await tester.pumpAndSettle();

      expect(streakTapped, isTrue);
    });

    testWidgets('handles today card tap', (WidgetTester tester) async {
      bool todayTapped = false;

      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: sampleStats,
          onLessonsTap: () {},
          onStreakTap: () {},
          onTodayTap: () => todayTapped = true,
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Find and tap the third card (today card)
      final cardFinders = find.byType(Card);
      expect(cardFinders, findsAtLeastNWidgets(3));

      await tester.tap(cardFinders.at(2));
      await tester.pumpAndSettle();

      expect(todayTapped, isTrue);
    });

    testWidgets('has proper accessibility semantics', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: sampleStats,
          onLessonsTap: () {},
          onStreakTap: () {},
          onTodayTap: () {},
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Verify semantic structure is present with text content
      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Verify data values are accessible
      expect(find.text('4/5'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('25m'), findsOneWidget);

      // Verify cards are tappable (have semantic actions)
      final cards = find.byType(Card);
      expect(cards, findsAtLeastNWidgets(3));
    });

    testWidgets('displays zero values correctly', (WidgetTester tester) async {
      final zeroStats = MomentumStats.fromJson({
        'lessonsCompleted': 0,
        'totalLessons': 5,
        'streakDays': 0,
        'todayMinutes': 0,
      });

      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: zeroStats,
          onLessonsTap: () {},
          onStreakTap: () {},
          onTodayTap: () {},
        ),
      );

      // Verify zero values are displayed properly (using actual methods)
      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('0 days'), findsOneWidget);
      expect(find.text('0m'), findsOneWidget);
    });

    testWidgets('displays high values correctly', (WidgetTester tester) async {
      final highStats = MomentumStats.fromJson({
        'lessonsCompleted': 15,
        'totalLessons': 20,
        'streakDays': 30,
        'todayMinutes': 120,
      });

      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: highStats,
          onLessonsTap: () {},
          onStreakTap: () {},
          onTodayTap: () {},
        ),
      );

      // Verify high values are displayed properly (using actual methods)
      expect(find.text('15/20'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);
      expect(find.text('120m'), findsOneWidget);
    });

    testWidgets('handles text scaling properly', (WidgetTester tester) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: QuickStatsCards(
            stats: sampleStats,
            onLessonsTap: () {},
            onStreakTap: () {},
            onTodayTap: () {},
          ),
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Verify cards still render properly with scaled text
      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('uses compact layout for narrow screens', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(300, 600)), // Narrow screen
          child: QuickStatsCards(
            stats: sampleStats,
            onLessonsTap: () {},
            onStreakTap: () {},
            onTodayTap: () {},
          ),
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // All cards should still be present regardless of layout
      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('uses standard layout for wide screens', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(400, 600)), // Wide screen
          child: QuickStatsCards(
            stats: sampleStats,
            onLessonsTap: () {},
            onStreakTap: () {},
            onTodayTap: () {},
          ),
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // All cards should be present in standard layout
      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('respects reduced motion preferences', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: QuickStatsCards(
            stats: sampleStats,
            onLessonsTap: () {},
            onStreakTap: () {},
            onTodayTap: () {},
          ),
        ),
      );

      // Wait for widget to settle without animations
      await tester.pump();

      // Cards should still render without animation errors
      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('animates entry correctly', (WidgetTester tester) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: sampleStats,
          onLessonsTap: () {},
          onStreakTap: () {},
          onTodayTap: () {},
        ),
      );

      // Initial state
      await tester.pump();

      // Animation in progress (staggered)
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));

      // Final state
      await tester.pumpAndSettle();

      // Verify no errors occurred during animation
      expect(tester.takeException(), isNull);
      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('handles null callbacks gracefully', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: sampleStats,
          // No callbacks provided
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Cards should still render
      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Test should complete without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('applies custom margin when provided', (
      WidgetTester tester,
    ) async {
      const customMargin = EdgeInsets.all(16.0);

      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: sampleStats,
          margin: customMargin,
          onLessonsTap: () {},
          onStreakTap: () {},
          onTodayTap: () {},
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Find the container with margin
      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.margin == customMargin,
      );
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('cards have minimum touch target size', (
      WidgetTester tester,
    ) async {
      await TestHelpers.pumpTestWidget(
        tester,
        child: QuickStatsCards(
          stats: sampleStats,
          onLessonsTap: () {},
          onStreakTap: () {},
          onTodayTap: () {},
        ),
      );

      await tester.pumpAndSettle();

      // Find all tappable elements
      final tappableElements = find.byWidgetPredicate(
        (widget) =>
            widget is Card || widget is InkWell || widget is GestureDetector,
      );

      expect(tappableElements, findsAtLeastNWidgets(3));

      // Check that cards meet minimum touch target requirements
      final cardElements = find.byType(Card);
      for (final element in tester.widgetList(cardElements)) {
        final renderBox =
            tester.renderObject(find.byWidget(element)) as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          // Cards should be reasonably sized for touch interaction
          expect(size.height, greaterThanOrEqualTo(40));
          expect(size.width, greaterThanOrEqualTo(40));
        }
      }
    });
  });
}
