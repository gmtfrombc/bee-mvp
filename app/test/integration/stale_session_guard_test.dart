import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:app/features/auth/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/services/auth_service.dart';
import 'package:app/core/models/profile.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/widgets/launch_controller.dart';

class _FakeClient extends Mock implements SupabaseClient {}

class _FakeUser extends Fake implements User {
  @override
  String get id => 'deleted-user-id';
}

class _StubAuthNotifier extends AsyncNotifier<User?> implements AuthNotifier {
  @override
  Future<User?> build() async => _FakeUser();

  @override
  Future<void> signOut() async {
    // Instant sign-out in tests
    state = const AsyncValue.data(null);
  }

  // Unused methods
  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}
  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    return AuthResponse(session: null, user: _FakeUser());
  }

  @override
  Future<void> signInAnonymously() async {}
  @override
  Future<void> sendResetEmail({
    required String email,
    String? redirectTo,
  }) async {}
}

class _AuthServiceError extends Mock implements AuthService {
  @override
  User? get currentUser => _FakeUser();

  @override
  Future<Profile?> fetchProfile(String uid) async {
    throw const PostgrestException(message: 'Row not found');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LaunchController purges stale session and shows LoginPage', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseProvider.overrideWith((ref) async => _FakeClient()),
          currentUserProvider.overrideWith((ref) async => _FakeUser()),
          authServiceProvider.overrideWith((ref) async => _AuthServiceError()),
          authNotifierProvider.overrideWith(() => _StubAuthNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(path: '/', builder: (_, __) => const LaunchController()),
              GoRoute(path: '/launch', builder: (_, __) => const LoginPage()),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Allow splash delay & async signOut to complete.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // No additional assertions needed; LoginPage should be rendered.

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
