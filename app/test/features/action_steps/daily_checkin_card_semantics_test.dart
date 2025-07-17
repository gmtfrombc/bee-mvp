import 'package:app/features/action_steps/ui/widgets/daily_checkin_card.dart';
import 'package:app/features/action_steps/services/action_step_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('DailyCheckinCard semantics', () {
    testWidgets('exposes semantic labels for action buttons', (tester) async {
      // Enable semantics for this test.
      final semanticsHandle = tester.ensureSemantics();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            actionStepAnalyticsProvider.overrideWithValue(_FakeAnalytics()),
          ],
          child: const MaterialApp(home: DailyCheckinCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Mark today completed'), findsOneWidget);
      expect(find.bySemanticsLabel('Skip today'), findsOneWidget);

      // Dispose semantics tree to avoid memory leaks in test runner.
      semanticsHandle.dispose();
    });
  });
}
