import 'dart:async';

import 'package:app/core/models/profile.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/supabase_provider.dart';
// LaunchController is navigated to internally; no direct reference needed.
import 'package:app/features/auth/ui/confirmation_pending_page.dart';
import 'package:app/features/onboarding/ui/onboarding_screen.dart';
import 'package:app/features/auth/ui/registration_success_page.dart';
import 'package:app/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeClient extends Mock implements SupabaseClient {}

class _FakeUser extends Fake implements User {
  @override
  String get id => 'fake-id';
}

class _FakeAuthService extends Mock implements AuthService {
  _FakeAuthService();

  final _user = _FakeUser();

  @override
  User? get currentUser => _user;

  @override
  Future<Profile?> fetchProfile(String uid) async => null; // No profile yet
}

class _FakeSession extends Fake implements Session {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Deep-link happy path shows success then onboarding', (
    tester,
  ) async {
    final controller = StreamController<AuthState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => controller.stream),
          currentUserProvider.overrideWith((ref) async => _FakeUser()),
          authServiceProvider.overrideWith((ref) async => _FakeAuthService()),
          supabaseProvider.overrideWith((ref) async => _FakeClient()),
        ],
        child: const MaterialApp(
          home: ConfirmationPendingPage(email: 'happy@test.com'),
        ),
      ),
    );

    await tester.pump(); // initial build

    // Emit signedIn + non-null session event to simulate deep-link callback.
    controller.add(AuthState(AuthChangeEvent.signedIn, _FakeSession()));

    // Wait until success page appears.
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(RegistrationSuccessPage), findsOneWidget);

    // Tap the "I'm ready" button to proceed to onboarding.
    await tester.tap(find.text("I'm ready"));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);

    await controller.close();
  });
}
