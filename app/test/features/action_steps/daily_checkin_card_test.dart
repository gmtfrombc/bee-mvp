import 'package:app/features/action_steps/ui/widgets/daily_checkin_card.dart';
import 'package:app/features/action_steps/state/daily_checkin_controller.dart';
import 'package:app/features/action_steps/models/action_step_day_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/action_steps/services/action_step_analytics.dart';

/// Test helper: Always returns `ActionStepDayStatus.skipped` immediately.
class _SkippedNotifier extends DailyCheckinController {
  @override
  Future<ActionStepDayStatus> build() async => ActionStepDayStatus.skipped;
}

/// No-op analytics used in widget tests.
class _FakeAnalytics extends Fake implements ActionStepAnalytics {
  @override
  Future<void> logSet({
    required String actionStepId,
    required String category,
    required String description,
    required int frequency,
    required String weekStart,
    String source = 'manual',
  }) async {}

  @override
  Future<void> logCompleted({
    required bool success,
    String? actionStepId,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyCheckinCard', () {
    testWidgets('shows Pending state initially', (tester) async {
      // Provide noop analytics to avoid Supabase initialization.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            actionStepAnalyticsProvider.overrideWithValue(_FakeAnalytics()),
          ],
          child: const MaterialApp(home: DailyCheckinCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      // Buttons should be enabled.
      expect(find.text('I did it'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('changes to Completed after tapping I did it', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            actionStepAnalyticsProvider.overrideWithValue(_FakeAnalytics()),
          ],
          child: const MaterialApp(home: DailyCheckinCard()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('I did it'));
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('renders overridden status (Skipped)', (tester) async {
      final override = dailyCheckinControllerProvider.overrideWith(
        _SkippedNotifier.new,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            override,
            actionStepAnalyticsProvider.overrideWithValue(_FakeAnalytics()),
          ],
          child: const MaterialApp(home: DailyCheckinCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Skipped'), findsOneWidget);
    });
  });
}
