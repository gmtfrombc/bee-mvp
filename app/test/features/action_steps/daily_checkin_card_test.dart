import 'package:app/features/action_steps/ui/widgets/daily_checkin_card.dart';
import 'package:app/features/action_steps/state/daily_checkin_controller.dart';
import 'package:app/features/action_steps/models/action_step_day_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/action_steps/services/action_step_analytics.dart';
import 'package:app/l10n/s.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart'
    show currentActionStepProvider;

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

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child, {List<Override> overrides = const []}) {
    // Provide fake Supabase client to avoid initialization
    final fakeClient = _FakeSupabaseClient();
    return ProviderScope(
      overrides: [
        actionStepAnalyticsProvider.overrideWithValue(_FakeAnalytics()),
        supabaseClientProvider.overrideWithValue(fakeClient),
        currentActionStepProvider.overrideWith((ref) async => null),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: child,
      ),
    );
  }

  group('DailyCheckinCard', () {
    testWidgets('shows Pending state initially', (tester) async {
      // Provide noop analytics to avoid Supabase initialization.
      await tester.pumpWidget(buildTestApp(const DailyCheckinCard()));
      await tester.pumpAndSettle();

      final l10n = S.of(tester.element(find.byType(DailyCheckinCard)));
      expect(find.text(l10n.checkin_status_pending), findsOneWidget);
      // Buttons should be enabled.
      expect(find.text(l10n.checkin_done_button), findsOneWidget);
      expect(find.text(l10n.checkin_skip_button), findsOneWidget);
    });

    testWidgets('changes to Completed after tapping I did it', (tester) async {
      await tester.pumpWidget(buildTestApp(const DailyCheckinCard()));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(
          S
              .of(tester.element(find.byType(DailyCheckinCard)))
              .checkin_done_button,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          S
              .of(tester.element(find.byType(DailyCheckinCard)))
              .checkin_status_completed,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders overridden status (Skipped)', (tester) async {
      final override = dailyCheckinControllerProvider.overrideWith(
        _SkippedNotifier.new,
      );

      await tester.pumpWidget(
        buildTestApp(const DailyCheckinCard(), overrides: [override]),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          S
              .of(tester.element(find.byType(DailyCheckinCard)))
              .checkin_status_skipped,
        ),
        findsOneWidget,
      );
    });
  });
}
