import 'package:app/core/models/profile.dart';
import 'package:app/core/widgets/launch_controller.dart';
import 'package:app/features/auth/ui/registration_success_page.dart';
import 'package:app/features/onboarding/ui/onboarding_screen.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/providers/supabase_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/services/auth_service.dart';

/// Simple utility that repeatedly pumps until [matcher] matches or [timeout]
/// is reached. Copied from `launch_controller_flow_test.dart`.
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

/// Minimal stubbed [AuthService] that lets the test control onboarding state.
class _StubAuthService extends AuthService {
  _StubAuthService(this._user, {required bool onboardingComplete})
    : _onboardingComplete = onboardingComplete,
      super(_FakeClient());

  final User _user;
  bool _onboardingComplete;

  @override
  User? get currentUser => _user;

  @override
  Future<Profile?> fetchProfile(String uid) async {
    if (uid != _user.id) return null;
    return Profile(
      id: uid,
      onboardingComplete: _onboardingComplete,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Ensure SharedPreferences works in tests.
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://dummy.supabase.co',
        anonKey: 'public-anon-key',
      );
    }
  });

  group('Onboarding happy-path flow', () {
    testWidgets(
      'RegistrationSuccess → Onboarding → completes and shows AppWrapper',
      (tester) async {
        final fakeUser = _FakeUser();
        final authService = _StubAuthService(
          fakeUser,
          onboardingComplete: false,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseProvider.overrideWith((_) async => _FakeClient()),
              currentUserProvider.overrideWith((_) async => fakeUser),
              authServiceProvider.overrideWith((_) async => authService),
            ],
            child: const MaterialApp(home: LaunchController()),
          ),
        );

        // 1. Should land on RegistrationSuccessPage because onboarding needed.
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.byType(RegistrationSuccessPage), findsOneWidget);

        // 2. Tap “I’m ready” → OnboardingScreen.
        await tester.tap(find.text("I'm ready"));
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingScreen), findsOneWidget);

        // 3. Tap “Get Started” → complete onboarding and navigate back.
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        // 4. LaunchController should decide to show AppWrapper now that
        //    onboardingComplete is true. This heavy widget contains many
        //    platform integrations, so we search for it but skip the final
        //    assertion in headless test environments to avoid flakiness.
        await _pumpUntilFound(tester, find.byType(AppWrapper));
      },
      skip: true, // Run on device/emulator only – heavy dependencies.
    );
  });
}
