import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/gamification/ui/rewards_navigator.dart';
import 'package:app/features/gamification/providers/gamification_providers.dart';
import 'package:app/features/gamification/models/badge.dart';

void main() {
  group('Deep Link Navigation', () {
    late List<Badge> mockBadges;

    setUp(() {
      mockBadges = [
        const Badge(
          id: 'streak_3',
          title: '3-Day Streak',
          description: 'Complete 3 consecutive days',
          imagePath: 'assets/badges/streak_3.png',
          isEarned: true,
          earnedAt: null,
          category: BadgeCategory.streak,
          requiredPoints: 100,
        ),
      ];
    });

    testWidgets('rewards navigator loads correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            achievementsProvider.overrideWith((ref) async => mockBadges),
            earnedBadgesCountProvider.overrideWith((ref) async => 1),
            currentStreakProvider.overrideWith((ref) async => 3),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: RewardsNavigator()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the Rewards screen
      expect(find.text('Rewards'), findsOneWidget); // App bar title
      expect(find.text('Badges'), findsOneWidget); // Tab
      expect(find.text('Challenges'), findsOneWidget); // Tab
    });

    testWidgets('rewards navigation shows badges by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            achievementsProvider.overrideWith((ref) async => mockBadges),
            earnedBadgesCountProvider.overrideWith((ref) async => 1),
            currentStreakProvider.overrideWith((ref) async => 3),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: RewardsNavigator()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show badges content by default
      expect(find.text('Your Badges'), findsOneWidget);
    });
  });
}
