// ignore_for_file: unused_import, unused_element
import 'package:app/core/models/profile.dart';
import 'package:app/core/widgets/launch_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/auth/ui/login_page.dart';
import 'package:app/features/auth/ui/registration_success_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/providers/supabase_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/connectivity_service.dart';

/// Pumps the tester periodically until [matcher] finds a widget or [timeout]
/// is reached.
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder matcher, {
  Duration timeout = const Duration(seconds: 5),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (matcher.evaluate().isNotEmpty) return;
  }
  fail('Widget not found: $matcher');
}

class _FakeClient extends Mock implements SupabaseClient {}

class _FakeUser extends Fake implements User {
  @override
  String get id => 'fake-id';
}

class _FakeAuthService extends Mock implements AuthService {
  _FakeAuthService({required this.user, required this.profile});

  final User? user;
  final Profile? profile;

  @override
  User? get currentUser => user;

  @override
  Future<Profile?> fetchProfile(String uid) async => profile;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Provide a dummy Supabase initialization so widgets that rely on
  // Supabase.instance.client don’t assert during tests. The URL/key values
  // are never used because network is mocked.
  setUpAll(() async {
    // Ensure SharedPreferences has a test implementation to satisfy
    // Supabase initialize which uses it for local session storage.
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://dummy.supabase.co',
        anonKey: 'public-anon-key',
      );
    }
    ConnectivityService.setTestEnvironment(true);
  });

  group('LaunchController flow', () {
    testWidgets('Unauthenticated → shows LoginPage', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseProvider.overrideWith((ref) async => _FakeClient()),
            currentUserProvider.overrideWith((ref) async => null),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const LaunchController(),
                ),
                GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Authenticated but needs onboarding → shows success page', (
      tester,
    ) async {
      final fakeUser = _FakeUser();
      final fakeProfile = Profile(
        id: fakeUser.id,
        onboardingComplete: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseProvider.overrideWith((ref) async => _FakeClient()),
            currentUserProvider.overrideWith((ref) async => fakeUser),
            authServiceProvider.overrideWith(
              (ref) async =>
                  _FakeAuthService(user: fakeUser, profile: fakeProfile),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const LaunchController(),
                ),
                GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(RegistrationSuccessPage), findsOneWidget);
    });

    // Note: The "authenticated + onboarding complete" scenario is verified
    // in a dedicated unit test for LaunchController that stubs AppWrapper to
    // avoid heavyweight dependencies. That test lives in
    // `core/widgets/launch_controller_test.dart`.
  });
}
