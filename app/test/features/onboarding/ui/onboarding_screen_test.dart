// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/features/onboarding/ui/onboarding_screen.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/services/auth_service.dart';
import 'package:app/core/widgets/launch_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/auth/ui/login_page.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping Get Started completes onboarding and navigates home', (
    WidgetTester tester,
  ) async {
    // Arrange
    final mockAuth = MockAuthService();
    when(() => mockAuth.completeOnboarding()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWith((ref) async => mockAuth)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/onboarding',
            routes: [
              GoRoute(
                path: '/onboarding',
                builder: (_, __) => const OnboardingScreen(),
              ),
              GoRoute(path: '/', builder: (_, __) => const LaunchController()),
              GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => mockAuth.completeOnboarding()).called(1);
    expect(find.byType(LaunchController), findsOneWidget);
  });
}
