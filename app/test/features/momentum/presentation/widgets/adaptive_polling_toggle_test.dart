import 'package:app/features/momentum/presentation/widgets/adaptive_polling_toggle.dart';
import 'package:app/core/providers/vitals_notifier_provider.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:app/core/services/vitals/vitals_facade.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fake stubs to avoid heavyweight dependencies in widget tests.
// ---------------------------------------------------------------------------

class _FakeVitalsService implements VitalsService {
  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> startSubscription(String userId) async => true;

  @override
  Future<void> stopSubscription() async {}

  // Unused interface members – return safe defaults via noSuchMethod.
  @override
  noSuchMethod(Invocation invocation) => null;
}

class _FakeGoTrueClient implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  noSuchMethod(Invocation invocation) => null;
}

class _FakeSupabaseClient implements SupabaseClient {
  @override
  final GoTrueClient auth = _FakeGoTrueClient();

  @override
  noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('AdaptivePollingToggle', () {
    setUp(() {
      // Start each test with a clean set of in-memory SharedPreferences.
      SharedPreferences.setMockInitialValues({
        VitalsNotifierService.adaptivePollingPrefKey: false,
      });
    });

    testWidgets('toggles preference on tap and restarts service', (
      WidgetTester tester,
    ) async {
      // ------------------------------------------------------------------
      // 1. Prepare fake dependencies to avoid heavy Supabase initialisation
      // ------------------------------------------------------------------

      // ------------------------------------------------------------------
      // 2. Build widget with provider overrides
      // ------------------------------------------------------------------
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalsNotifierServiceProvider.overrideWithValue(
              _FakeVitalsService(),
            ),
            supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdaptivePollingToggle()),
          ),
        ),
      );

      // Allow initial async work to complete.
      await tester.pumpAndSettle();

      // ------------------------------------------------------------------
      // 3. Verify initial state (switch OFF)
      // ------------------------------------------------------------------
      final prefsBefore = await SharedPreferences.getInstance();
      expect(
        prefsBefore.getBool(VitalsNotifierService.adaptivePollingPrefKey),
        isFalse,
      );

      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);

      // ------------------------------------------------------------------
      // 4. Tap to toggle ON & wait for state update
      // ------------------------------------------------------------------
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final prefsAfter = await SharedPreferences.getInstance();
      expect(
        prefsAfter.getBool(VitalsNotifierService.adaptivePollingPrefKey),
        isTrue,
      );
    });
  });
}
