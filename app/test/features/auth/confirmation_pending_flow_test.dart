import 'package:app/features/auth/ui/auth_page.dart';
import 'package:app/features/auth/ui/confirmation_pending_page.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/features/gamification/providers/gamification_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:go_router/go_router.dart';

class _StubAuthNotifier extends AsyncNotifier<User?> implements AuthNotifier {
  // Helper fake user & state emitters
  void emitSuccess() => state = AsyncValue.data(_FakeUser());

  @override
  Future<User?> build() async => null;

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    emitSuccess();
    return AuthResponse(session: null, user: _FakeUser());
  }

  // Other methods unused in this test
  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}
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

// Simple fake Supabase user for tests
class _FakeUser extends Fake implements User {}

class _FakeClient extends Mock implements SupabaseClient {}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 2),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget not found: $finder');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Navigates to ConfirmationPendingPage when sign-up returns no session',
    (tester) async {
      final stub = _StubAuthNotifier();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const AuthPage()),
          GoRoute(
            path: '/confirm',
            builder: (context, state) {
              final email = state.extra as String? ?? '';
              return ConfirmationPendingPage(email: email);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => stub),
            challengeProvider.overrideWith((_) => Stream.value([])),
            supabaseProvider.overrideWith((ref) async => _FakeClient()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();
      // Allow navigation animation frames
      await tester.pumpAndSettle();

      // Fill valid fields
      await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'alice@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      // Submit form and allow one frame. Spinner animation means we avoid
      // pumpAndSettle which would wait forever.
      await tester.tap(find.text('Create Account'));
      // Wait until ConfirmationPendingPage appears.
      await _pumpUntilFound(tester, find.byType(ConfirmationPendingPage));

      expect(find.textContaining('alice@example.com'), findsAtLeastNWidgets(1));
    },
  );
}
