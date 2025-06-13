import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/gamification/ui/achievements_screen.dart';
import 'package:app/features/gamification/models/badge.dart';
import 'package:app/features/gamification/providers/gamification_providers.dart';

void main() {
  group('AchievementsScreen', () {
    late List<Badge> mockBadges;

    setUp(() {
      mockBadges = [
        const Badge(
          id: '1',
          title: 'First Steps',
          description: 'Complete your first day',
          imagePath: 'assets/badges/first_steps.png',
          category: BadgeCategory.milestone,
          isEarned: true,
          earnedAt: null,
          requiredPoints: 10,
          currentProgress: 10,
        ),
        const Badge(
          id: '2',
          title: 'Streak Master',
          description: 'Maintain a 7-day streak',
          imagePath: 'assets/badges/streak_master.png',
          category: BadgeCategory.streak,
          isEarned: false,
          earnedAt: null,
          requiredPoints: 50,
          currentProgress: 25,
        ),
      ];
    });

    testWidgets('renders badge grid with earned and dimmed badges', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            achievementsProvider.overrideWith((ref) async => mockBadges),
            earnedBadgesCountProvider.overrideWith((ref) async => 1),
            currentStreakProvider.overrideWith((ref) async => 3),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: AchievementsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify grid exists
      expect(find.byType(GridView), findsOneWidget);

      // Verify both badges are rendered
      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('Streak Master'), findsOneWidget);

      // Verify earned badge has check icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify progress indicator for unearned badge
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('tapping badge opens detail sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            achievementsProvider.overrideWith((ref) async => mockBadges),
            earnedBadgesCountProvider.overrideWith((ref) async => 1),
            currentStreakProvider.overrideWith((ref) async => 3),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: AchievementsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down more to make the badges visible in the test viewport
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();

      // Find and tap the badge card instead of just the text
      final badgeCard =
          find
              .ancestor(
                of: find.text('First Steps'),
                matching: find.byType(Card),
              )
              .first;

      await tester.tap(badgeCard);
      await tester.pumpAndSettle();

      // Verify bottom sheet opened with badge details
      expect(find.text('First Steps'), findsAtLeastNWidgets(1));
      expect(find.text('Complete your first day'), findsOneWidget);
    });
  });
}
