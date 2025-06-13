import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:app/features/gamification/ui/progress_dashboard.dart';
import 'package:app/features/gamification/models/badge.dart';
import 'package:app/features/gamification/providers/gamification_providers.dart';

void main() {
  group('ProgressDashboard', () {
    late List<ProgressData> mockProgressData;
    late List<Badge> mockBadges;

    setUp(() {
      mockProgressData = [
        ProgressData(
          date: DateTime.now().subtract(const Duration(days: 6)),
          points: 15,
          badgesEarned: [],
        ),
        ProgressData(
          date: DateTime.now().subtract(const Duration(days: 5)),
          points: 20,
          badgesEarned: [],
        ),
        ProgressData(
          date: DateTime.now().subtract(const Duration(days: 4)),
          points: 25,
          badgesEarned: [],
        ),
      ];

      mockBadges = [
        Badge(
          id: '1',
          title: 'First Steps',
          description: 'Complete your first day',
          imagePath: 'assets/badges/first_steps.png',
          category: BadgeCategory.milestone,
          isEarned: true,
          earnedAt: DateTime.now().subtract(const Duration(days: 2)),
          requiredPoints: 10,
          currentProgress: 10,
        ),
      ];
    });

    testWidgets('chart paints with sample stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressProvider.overrideWith((ref) async => mockProgressData),
            achievementsProvider.overrideWith((ref) async => mockBadges),
          ],
          child: const MaterialApp(home: ProgressDashboard()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart exists
      expect(find.byType(LineChart), findsOneWidget);

      // Verify chart title
      expect(find.text('Weekly Progress'), findsOneWidget);

      // Verify chart renders with data points
      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(lineChart.data.lineBarsData.isNotEmpty, isTrue);
      expect(lineChart.data.lineBarsData.first.spots.length, equals(3));
    });

    testWidgets('timeline list scrolls', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressProvider.overrideWith((ref) async => mockProgressData),
            achievementsProvider.overrideWith((ref) async => mockBadges),
          ],
          child: const MaterialApp(home: ProgressDashboard()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify scrollable content exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Verify badge timeline section exists
      expect(find.text('Achievement Timeline'), findsOneWidget);

      // Verify badge is displayed in timeline
      expect(find.text('First Steps'), findsOneWidget);
    });
  });
}
