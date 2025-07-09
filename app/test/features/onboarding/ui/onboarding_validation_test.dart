import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';
import 'package:app/features/onboarding/ui/about_you_page.dart';
import 'package:app/features/onboarding/ui/preferences_page.dart';
import 'package:app/features/onboarding/onboarding_controller.dart';

void main() {
  group('Onboarding validation – DOB age limits', () {
    testWidgets('shows error when age < 13', (tester) async {
      final today = DateTime.now();
      final invalidDob = DateTime(today.year - 12, today.month, today.day);

      final controller = OnboardingController();
      controller.updateDateOfBirth(invalidDob);
      controller.updateGender('male');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingControllerProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(path: '/', builder: (_, __) => const AboutYouPage()),
                GoRoute(
                  path: kOnboardingStep2Route,
                  builder: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );

      // Continue button should be enabled (controller thinks step complete)
      expect(find.byKey(const ValueKey('continue_button')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('continue_button')));
      await tester.pump(); // allow validation to run

      expect(
        find.text('Please enter a valid age between 13 – 120.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when age > 120', (tester) async {
      final today2 = DateTime.now();
      final invalidDob = DateTime(today2.year - 130, today2.month, today2.day);

      final controller = OnboardingController();
      controller.updateDateOfBirth(invalidDob);
      controller.updateGender('female');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingControllerProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(path: '/', builder: (_, __) => const AboutYouPage()),
                GoRoute(
                  path: kOnboardingStep2Route,
                  builder: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('continue_button')));
      await tester.pump();

      expect(
        find.text('Please enter a valid age between 13 – 120.'),
        findsOneWidget,
      );
    });
  });

  group('Onboarding validation – Preferences count', () {
    testWidgets('shows error when selecting more than 5 preferences', (
      tester,
    ) async {
      final controller = OnboardingController();
      controller.setPreferences([
        'activity',
        'nutrition',
        'sleep',
        'mindfulness',
        'social',
        'extra',
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(home: PreferencesPage()),
        ),
      );
      await tester.pump();

      expect(
        find.text('Pick at least 1 and at most 5 preferences.'),
        findsOneWidget,
      );
    });
  });
}
