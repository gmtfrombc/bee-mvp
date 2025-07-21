// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/ui/registration_success_page.dart';
import 'package:app/features/onboarding/ui/about_you_page.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/services/auth_service.dart';
import 'package:app/core/navigation/routes.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping “I\'m ready” navigates to AboutYouPage', (
    WidgetTester tester,
  ) async {
    final mockAuth = _MockAuthService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWith((_) async => mockAuth)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const RegistrationSuccessPage(),
              ),
              GoRoute(
                path: kOnboardingStep1Route,
                builder: (_, __) => const AboutYouPage(),
              ),
            ],
          ),
        ),
      ),
    );

    // Verify initial state
    expect(find.byType(RegistrationSuccessPage), findsOneWidget);

    // Tap the button
    await tester.tap(find.text("I'm ready"));
    await tester.pumpAndSettle();

    // Should navigate to onboarding step 1 (AboutYouPage)
    expect(find.byType(AboutYouPage), findsOneWidget);
  });
}
