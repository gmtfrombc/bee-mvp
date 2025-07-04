// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/middleware/onboarding_redirect.dart';
import 'package:app/core/services/auth_service.dart';
import 'package:app/core/models/profile.dart';

class MockAuthService extends Mock implements AuthService {}

class MockGoRouter extends Mock implements GoRouter {}

class FakeUser extends Fake implements User {
  @override
  String get id => 'user-123';
}

void main() {
  setUpAll(() {});

  group('OnboardingRedirect', () {
    late MockAuthService authService;
    late MockGoRouter router;
    late OnboardingRedirect redirect;
    late User user;

    setUp(() {
      authService = MockAuthService();
      router = MockGoRouter();
      redirect = OnboardingRedirect(router, authService);
      user = FakeUser();

      // Allow go() to be called without side-effects
      when(() => router.go(any())).thenReturn(null);
    });

    test('redirects to /onboarding when onboarding incomplete', () async {
      when(() => authService.fetchProfile(user.id)).thenAnswer(
        (_) async => Profile(
          id: user.id,
          onboardingComplete: false,
          createdAt: DateTime.now(),
        ),
      );

      await redirect.maybeRedirect(user);

      verify(() => router.go('/onboarding')).called(1);
    });

    test('does not redirect when onboarding already complete', () async {
      when(() => authService.fetchProfile(user.id)).thenAnswer(
        (_) async => Profile(
          id: user.id,
          onboardingComplete: true,
          createdAt: DateTime.now(),
        ),
      );

      await redirect.maybeRedirect(user);

      verifyNever(() => router.go('/onboarding'));
    });

    test('redirects when profile is null', () async {
      when(
        () => authService.fetchProfile(user.id),
      ).thenAnswer((_) async => null);

      await redirect.maybeRedirect(user);

      verify(() => router.go('/onboarding')).called(1);
    });

    test('redirects when fetchProfile throws', () async {
      when(
        () => authService.fetchProfile(user.id),
      ).thenThrow(Exception('db error'));

      await redirect.maybeRedirect(user);

      verify(() => router.go('/onboarding')).called(1);
    });
  });
}
