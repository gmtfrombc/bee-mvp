import 'package:go_router/go_router.dart';
import 'package:app/core/widgets/launch_controller.dart';
import 'package:app/features/onboarding/ui/about_you_page.dart';
import 'package:app/features/onboarding/ui/preferences_page.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:app/features/onboarding/ui/readiness_page.dart';
import 'package:app/features/onboarding/ui/mindset_page.dart';
import 'package:app/features/onboarding/ui/goal_setup_page.dart';
import 'package:app/features/onboarding/ui/medical_history_page.dart';
import 'package:app/features/onboarding/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:app/features/action_steps/ui/action_step_setup_page.dart';

/// Centralized route constants for the app.
const String kOnboardingStep1Route = '/onboarding/step1';
const String kOnboardingStep2Route = '/onboarding/step2';
const String kOnboardingStep3Route = '/onboarding/step3';
const String kOnboardingStep4Route = '/onboarding/step4';
const String kOnboardingStep5Route = '/onboarding/step5';
const String kOnboardingStep6Route = '/onboarding/step6';
const String kActionStepSetupRoute = '/action-step/setup';

/// Global [GoRouter] instance for the application.
const _onboardingGuard = OnboardingGuard();

String? _onboardingStepGuard(BuildContext context, int step) {
  final controller = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(onboardingControllerProvider.notifier);

  if (step >= 1 && !controller.isStep1Complete) {
    return kOnboardingStep1Route;
  }

  if (step >= 2 && !controller.isStep2Complete) {
    return kOnboardingStep2Route;
  }

  if (step >= 3 && !controller.isReadinessComplete) {
    return kOnboardingStep3Route;
  }

  if (step >= 4 && !controller.isMindsetComplete) {
    return kOnboardingStep4Route;
  }

  if (step >= 5 && !controller.isGoalSetupComplete) {
    return kOnboardingStep5Route;
  }
  return null;
}

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
    GoRoute(
      path: kOnboardingStep3Route,
      redirect: (ctx, state) => _onboardingStepGuard(ctx, 3),
      builder: (context, state) => const ReadinessPage(),
    ),
    GoRoute(
      path: kOnboardingStep4Route,
      redirect: (ctx, state) => _onboardingStepGuard(ctx, 4),
      builder: (context, state) => const MindsetPage(),
    ),
    GoRoute(
      path: kOnboardingStep5Route,
      redirect: (ctx, state) => _onboardingStepGuard(ctx, 5),
      builder: (context, state) => const GoalSetupPage(),
    ),
    GoRoute(
      path: kOnboardingStep6Route,
      redirect: (ctx, state) => _onboardingStepGuard(ctx, 6),
      builder: (context, state) => const MedicalHistoryPage(),
    ),
    GoRoute(
      path: kActionStepSetupRoute,
      builder: (context, state) => const ActionStepSetupPage(),
    ),
  ],
);
