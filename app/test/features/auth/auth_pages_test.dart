import 'package:app/features/auth/ui/auth_page.dart';
import 'package:app/features/auth/ui/login_page.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/features/gamification/providers/gamification_providers.dart';

class _FakeUser extends Fake implements User {}

/// Stub notifier that lets tests control emitted state without touching Supabase.
class _StubAuthNotifier extends AsyncNotifier<User?> implements AuthNotifier {
  @override
  Future<User?> build() async => null;

  // Expose helpers for tests.
  void emitLoading() => state = const AsyncValue.loading();

  void emitError(Object err) =>
      state = AsyncValue.error(err, StackTrace.current);

  void emitSuccess() => state = AsyncValue.data(_FakeUser());

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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthPage', () {
    testWidgets('shows validation errors when fields are empty', (
      tester,
    ) async {
      final stub = _StubAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => stub),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(path: '/', builder: (_, __) => const AuthPage()),
                GoRoute(path: '/launch', builder: (_, __) => const Scaffold()),
              ],
            ),
          ),
        ),
      );

      // Allow initial async build to complete so button label appears.
      await tester.pumpAndSettle();

      // Tap submit immediately
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Validation messages per field
      expect(find.text('Required'), findsOneWidget); // Name field
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows Account already exists snackbar on duplicate email', (
      tester,
    ) async {
      final stub = _StubAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => stub),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(path: '/', builder: (_, __) => const AuthPage()),
                GoRoute(path: '/launch', builder: (_, __) => const Scaffold()),
              ],
            ),
          ),
        ),
      );

      // Allow initial async build to complete so button label appears.
      await tester.pumpAndSettle();

      // Fill valid fields
      // BeeTextField places the label outside the TextFormField, so we select by index.
      await tester.enterText(find.byType(TextFormField).at(0), 'Bob'); // Name
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'bob@bee.com',
      ); // Email
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'password123',
      ); // Password

      // Trigger submission
      await tester.tap(find.text('Create Account'));

      // Emit error from stub
      stub.emitError(const AuthException('User already registered'));
      await tester.pumpAndSettle();

      expect(find.text('Account already exists'), findsWidgets);
    });
  });

  group('LoginPage', () {
    testWidgets('shows validation errors when fields are empty', (
      tester,
    ) async {
      final stub = _StubAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => stub),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(path: '/', builder: (_, __) => const LoginPage()),
                GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
                GoRoute(path: '/launch', builder: (_, __) => const Scaffold()),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows incorrect credentials snackbar', (tester) async {
      final stub = _StubAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => stub),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(path: '/', builder: (_, __) => const LoginPage()),
                GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
                GoRoute(path: '/launch', builder: (_, __) => const Scaffold()),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'bob@bee.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'badpass');

      await tester.tap(find.text('Log In'));

      stub.emitError(const AuthException('Invalid login credentials'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password'), findsWidgets);
    });

    // Add navigation test from LoginPage to AuthPage.
    testWidgets('navigates to AuthPage when tapping Create one link', (
      tester,
    ) async {
      final stub = _StubAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => stub),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(path: '/', builder: (_, __) => const LoginPage()),
                GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
                GoRoute(path: '/launch', builder: (_, __) => const Scaffold()),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the TextButton that should push AuthPage.
      await tester.tap(find.text("Don't have an account? Create one"));
      await tester.pumpAndSettle();

      expect(find.byType(AuthPage), findsOneWidget);
    });
  });

  // Add navigation test from AuthPage to LoginPage.
  group('AuthPage navigation', () {
    testWidgets('navigates to LoginPage when tapping Log in link', (
      tester,
    ) async {
      final stub = _StubAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => stub),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/auth',
              routes: [
                GoRoute(path: '/', builder: (_, __) => const LoginPage()),
                GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
                GoRoute(path: '/launch', builder: (_, __) => const Scaffold()),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the TextButton that should push LoginPage.
      await tester.tap(find.text('Already have an account? Log in'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
