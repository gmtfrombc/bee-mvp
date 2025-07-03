import 'package:app/features/auth/ui/auth_page.dart';
import 'package:app/features/auth/ui/login_page.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
          child: const MaterialApp(home: AuthPage()),
        ),
      );

      // Allow initial async build to complete so button label appears.
      await tester.pumpAndSettle();

      // Tap submit immediately
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      // Required error should appear three times (Name, Email, Password)
      expect(find.text('Required'), findsNWidgets(3));
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
          child: const MaterialApp(home: AuthPage()),
        ),
      );

      // Allow initial async build to complete so button label appears.
      await tester.pumpAndSettle();

      // Fill valid fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Bob');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bob@bee.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // Trigger submission
      await tester.tap(find.text('Create Account'));

      // Emit error from stub
      stub.emitError(const AuthException('User already registered'));
      await tester.pump();

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
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('shows incorrect credentials snackbar', (tester) async {
      final stub = _StubAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => stub),
            challengeProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bob@bee.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'badpass',
      );

      await tester.tap(find.text('Log In'));

      stub.emitError(const AuthException('Invalid login credentials'));
      await tester.pump();

      expect(find.text('Incorrect email or password'), findsWidgets);
    });
  });
}
