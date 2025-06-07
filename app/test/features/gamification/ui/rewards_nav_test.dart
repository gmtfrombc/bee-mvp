import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/gamification/ui/rewards_navigator.dart';
import 'package:app/features/gamification/providers/gamification_providers.dart';
import 'package:app/features/gamification/models/badge.dart';

void main() {
  group('RewardsNavigator', () {
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

    testWidgets('displays rewards navigation with tabs', (tester) async {
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

      // Verify the app bar title
      expect(find.text('Rewards'), findsOneWidget);

      // Verify tabs are present
      expect(find.text('Badges'), findsOneWidget);
      expect(find.text('Challenges'), findsOneWidget);

      // Verify tab icons exist
      expect(find.byIcon(Icons.emoji_events), findsWidgets);
      expect(find.byIcon(Icons.flag), findsWidgets);
    });

    testWidgets('can switch between tabs', (tester) async {
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

      // Initially on Badges tab - should see achievements content
      expect(find.text('Your Badges'), findsOneWidget);

      // Tap on Challenges tab
      await tester.tap(find.text('Challenges'));
      await tester.pumpAndSettle();

      // Should now see challenges content
      expect(find.text('Challenges Coming Soon!'), findsOneWidget);
    });

    testWidgets('challenges screen shows placeholder content', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChallengesListScreen()));

      await tester.pumpAndSettle();

      // Verify placeholder content
      expect(find.text('Challenges Coming Soon!'), findsOneWidget);
      expect(
        find.text(
          'Weekly and daily challenges will be available in the next update.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });
  });
}
