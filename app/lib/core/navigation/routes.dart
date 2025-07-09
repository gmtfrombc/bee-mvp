import 'package:go_router/go_router.dart';
import 'package:app/core/widgets/launch_controller.dart';
import 'package:app/features/onboarding/ui/about_you_page.dart';
import 'package:app/features/onboarding/ui/preferences_page.dart';

/// Centralized route constants for the app.
const String kOnboardingStep1Route = '/onboarding/step1';
const String kOnboardingStep2Route = '/onboarding/step2';

/// Global [GoRouter] instance for the application.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LaunchController()),
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
