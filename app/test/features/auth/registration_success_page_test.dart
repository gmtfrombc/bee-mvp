// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/features/auth/ui/registration_success_page.dart';
import 'package:app/features/onboarding/ui/onboarding_screen.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/services/auth_service.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping “I\'m ready” navigates to OnboardingScreen', (
    WidgetTester tester,
  ) async {
    final mockAuth = _MockAuthService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWith((_) async => mockAuth)],
        child: const MaterialApp(home: RegistrationSuccessPage()),
      ),
    );

    // Verify initial state
    expect(find.byType(RegistrationSuccessPage), findsOneWidget);

    // Tap the button
    await tester.tap(find.text("I'm ready"));
    await tester.pumpAndSettle();

    // Should navigate to onboarding
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
