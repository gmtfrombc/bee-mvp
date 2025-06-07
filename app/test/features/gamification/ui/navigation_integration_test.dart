import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/gamification/ui/achievements_screen.dart';
import 'package:app/features/momentum/presentation/screens/profile_settings_screen.dart';
import 'package:app/features/gamification/providers/gamification_providers.dart';
import 'package:app/features/gamification/models/badge.dart';

void main() {
  group('Gamification Navigation Integration', () {
    testWidgets('Achievements menu item removed from ProfileSettingsScreen', (
      WidgetTester tester,
    ) async {
      // Build the ProfileSettingsScreen wrapped in necessary providers
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override challengeProvider to avoid timer issues in tests
            challengeProvider.overrideWith(
              (ref) => Stream.value(<Challenge>[]),
            ),
            achievementsProvider.overrideWith((ref) async => <Badge>[]),
            earnedBadgesCountProvider.overrideWith((ref) async => 0),
            currentStreakProvider.overrideWith((ref) async => 0),
            totalPointsProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(home: const ProfileSettingsScreen()),
        ),
      );

      // Verify the screen loads
      expect(find.text('Profile & Settings'), findsOneWidget);

      // Verify achievements menu item is NOT present (moved to Rewards tab)
      expect(find.text('Achievements'), findsNothing);
      expect(find.text('View badges and progress'), findsNothing);

      // Verify other menu items are still present
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
    });

    testWidgets('AchievementsScreen renders correctly', (
      WidgetTester tester,
    ) async {
      // Build the AchievementsScreen directly with provider overrides
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override challengeProvider to avoid timer issues in tests
            challengeProvider.overrideWith(
              (ref) => Stream.value(<Challenge>[]),
            ),
            achievementsProvider.overrideWith((ref) async => <Badge>[]),
            earnedBadgesCountProvider.overrideWith((ref) async => 0),
            currentStreakProvider.overrideWith((ref) async => 0),
            totalPointsProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(home: const AchievementsScreen()),
        ),
      );

      // Wait for async data loading
      await tester.pumpAndSettle();

      // Verify the screen type is present
      expect(find.byType(AchievementsScreen), findsOneWidget);

      // Verify key elements are present (these should be in app bar)
      expect(find.text('Achievements & Challenges'), findsAtLeast(1));
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('ProgressDashboard can be accessed from AchievementsScreen', (
      WidgetTester tester,
    ) async {
      // Build the AchievementsScreen with provider overrides
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override challengeProvider to avoid timer issues in tests
            challengeProvider.overrideWith(
              (ref) => Stream.value(<Challenge>[]),
            ),
            achievementsProvider.overrideWith((ref) async => <Badge>[]),
            earnedBadgesCountProvider.overrideWith((ref) async => 0),
            currentStreakProvider.overrideWith((ref) async => 0),
            totalPointsProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(home: const AchievementsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the progress dashboard icon
      await tester.tap(find.byIcon(Icons.bar_chart));
      await tester.pumpAndSettle();

      // Verify navigation to ProgressDashboard
      expect(find.text('Progress Dashboard'), findsOneWidget);
    });
  });
}
