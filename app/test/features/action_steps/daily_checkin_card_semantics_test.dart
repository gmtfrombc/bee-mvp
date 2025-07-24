import 'package:app/features/action_steps/ui/widgets/daily_checkin_card.dart';
import 'package:app/features/action_steps/services/action_step_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/l10n/s.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart'
    show currentActionStepProvider;

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

      final fakeClient = _FakeSupabaseClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            actionStepAnalyticsProvider.overrideWithValue(_FakeAnalytics()),
            supabaseClientProvider.overrideWithValue(fakeClient),
            currentActionStepProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: DailyCheckinCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = S.of(tester.element(find.byType(DailyCheckinCard)));
      expect(
        find.bySemanticsLabel(l10n.checkin_semantics_mark_completed),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(l10n.checkin_semantics_skip_today),
        findsOneWidget,
      );

      // Dispose semantics tree to avoid memory leaks in test runner.
      semanticsHandle.dispose();
    });
  });
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}
