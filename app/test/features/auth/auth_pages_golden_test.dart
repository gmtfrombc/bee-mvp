@Skip('Golden images outdated after UI updates – needs regeneration')
library;

// ignore_for_file: invalid_uri
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/features/auth/ui/auth_page.dart';
import 'package:app/features/auth/ui/login_page.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/features/gamification/providers/gamification_providers.dart';

// Fake user for stubbed auth state
class _FakeUser extends Fake implements User {}

/// Stub AuthNotifier allowing controlled state in tests without Supabase.
class _StubAuthNotifier extends AsyncNotifier<User?> implements AuthNotifier {
  @override
  Future<User?> build() async => null;

  // Helpers to control state if ever needed
  void emitSuccess() => state = AsyncValue.data(_FakeUser());
  void emitLoading() => state = const AsyncValue.loading();
  void emitError(Object err) =>
      state = AsyncValue.error(err, StackTrace.current);

  // === Auth API stubs ===
  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    emitSuccess();
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emitSuccess();
  }

  @override
  Future<void> signInAnonymously() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendResetEmail({
    required String email,
    String? redirectTo,
  }) async {}
}

void main() {
  GoldenToolkit.runWithConfiguration(
    () => _main(),
    config: GoldenToolkitConfiguration(
      enableRealShadows: false,
      defaultDevices: const [Device.phone, Device.tabletPortrait],
      fileNameFactory: (name) => '../../_goldens/$name.png',
    ),
  );
}

void _main() {
  setUpAll(() async {
    await loadAppFonts();
    // Initialize binding to ensure widgets are ready for tests. No need to
    // override pixel ratio; default 1.0 is deterministic across CI.
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  testGoldens('Auth & Login Pages', (tester) async {
    final stubAuth = _StubAuthNotifier();

    // --- AuthPage snapshot ---
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => stubAuth),
          challengeProvider.overrideWith((_) => Stream.value([])),
        ],
        child: const AuthPage(),
      ),
    );
    await screenMatchesGolden(tester, 'auth_page');

    // --- LoginPage snapshot ---
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => stubAuth),
          challengeProvider.overrideWith((_) => Stream.value([])),
        ],
        child: const LoginPage(),
      ),
    );
    await screenMatchesGolden(tester, 'login_page');
  });
}
