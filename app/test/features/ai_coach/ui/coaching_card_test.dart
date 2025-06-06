import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/ai_coach/ui/coaching_card.dart';
import 'package:app/core/theme/app_theme.dart';

void main() {
  group('CoachingCard', () {
    testWidgets('renders with correct title and subtitle', (tester) async {
      const testTitle = 'Build Habits';
      const testSubtitle = 'Start with small daily actions';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CoachingCard(
              title: testTitle,
              subtitle: testSubtitle,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testSubtitle), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CoachingCard(
              title: 'Test Card',
              subtitle: 'Test subtitle',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CoachingCard));
      expect(tapped, isTrue);
    });

    testWidgets('displays icon when provided', (tester) async {
      const testIcon = Icons.lightbulb;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CoachingCard(
              title: 'Test Card',
              subtitle: 'Test subtitle',
              icon: testIcon,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(testIcon), findsOneWidget);
    });

    testWidgets('uses momentum color for accent when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CoachingCard(
              title: 'Test Card',
              subtitle: 'Test subtitle',
              momentumState: MomentumState.rising,
              onTap: () {},
            ),
          ),
        ),
      );

      // Card should render without errors
      expect(find.byType(CoachingCard), findsOneWidget);
    });
  });

  group('CompactCoachingCard', () {
    testWidgets('renders with correct title and emoji', (tester) async {
      const testTitle = 'Daily Habits';
      const testEmoji = '🌱';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CompactCoachingCard(
              title: testTitle,
              emoji: testEmoji,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testEmoji), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CompactCoachingCard(
              title: 'Test Card',
              emoji: '🚀',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CompactCoachingCard));
      expect(tapped, isTrue);
    });
  });
}
