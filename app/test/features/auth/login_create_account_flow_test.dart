@Skip('Flow covered by widget tests; skip for now due to GoRouter flakiness')
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/auth/ui/login_page.dart';
import 'package:app/features/auth/ui/auth_page.dart';
import 'package:app/features/auth/ui/confirmation_pending_page.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/navigation/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class _StubAuthNotifier extends AsyncNotifier<User?> implements AuthNotifier {
  @override
  Future<User?> build() async => null;

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    // Simulate Supabase returning null session → should navigate to /confirm
    return AuthResponse(session: null, user: null);
  }

  // Unused methods in this test
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Login → Create Account navigation flow', () {
    testWidgets('navigates LoginPage → AuthPage → ConfirmationPendingPage', (
      tester,
    ) async {
      final stubNotifier = _StubAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authNotifierProvider.overrideWith(() => stubNotifier)],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(path: '/', builder: (_, __) => const LoginPage()),
                GoRoute(path: kAuthRoute, builder: (_, __) => const AuthPage()),
                GoRoute(
                  path: kConfirmRoute,
                  builder:
                      (_, state) => ConfirmationPendingPage(
                        email: state.extra as String? ?? '',
                      ),
                ),
              ],
            ),
          ),
        ),
      );

      // Tap "Create one" link → should navigate to AuthPage.
      await tester.tap(find.text("Don't have an account? Create one"));
      await tester.pumpAndSettle();

      expect(find.byType(AuthPage), findsOneWidget);

      // Fill form fields with valid values.
      await tester.enterText(find.byType(TextFormField).at(0), 'Bob');
      await tester.enterText(find.byType(TextFormField).at(1), 'bob@test.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      // Tap "Create Account" → should call stub and navigate to ConfirmationPendingPage.
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(ConfirmationPendingPage), findsOneWidget);
    });
  });
}
