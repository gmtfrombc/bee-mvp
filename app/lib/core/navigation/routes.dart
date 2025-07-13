import 'package:go_router/go_router.dart';
import 'package:app/core/widgets/launch_controller.dart';
import 'package:app/features/onboarding/ui/about_you_page.dart';
import 'package:app/features/onboarding/ui/preferences_page.dart';
import 'package:app/core/providers/supabase_provider.dart';

/// Centralized route constants for the app.
const String kOnboardingStep1Route = '/onboarding/step1';
const String kOnboardingStep2Route = '/onboarding/step2';

/// Global [GoRouter] instance for the application.
const _onboardingGuard = OnboardingGuard();

final GoRouter appRouter = GoRouter(
  redirect:
      _onboardingGuard
          .call, // Ensures onboarding is complete before accessing other routes
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LaunchController()),
    // Expose an explicit "/launch" alias so other modules can navigate
    // without relying on the root path constant.
    GoRoute(
      path: '/launch',
      builder: (context, state) => const LaunchController(),
    ),
    GoRoute(
      path: kOnboardingStep1Route,
      builder: (context, state) => const AboutYouPage(),
    ),
    GoRoute(
      path: kOnboardingStep2Route,
      builder: (context, state) => const PreferencesPage(),
    ),
  ],
);
