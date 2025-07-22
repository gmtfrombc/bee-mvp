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
import 'package:flutter/material.dart';
import 'package:app/features/action_steps/ui/action_step_setup_page.dart';
import 'package:app/features/auth/ui/confirmation_pending_page.dart';
import 'package:app/features/auth/ui/auth_page.dart';
import 'package:app/features/auth/ui/login_page.dart';
import 'package:app/features/momentum/presentation/screens/notification_settings_screen.dart';
import 'package:app/features/momentum/presentation/screens/profile_settings_screen.dart';
import 'package:app/features/gamification/ui/achievements_screen.dart';
import 'package:app/features/gamification/ui/progress_dashboard.dart';
import 'package:app/features/today_feed/presentation/screens/today_feed_article_screen.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';
import 'package:app/features/ai_coach/ui/coach_chat_screen.dart';
import 'package:app/features/wearable/ui/live_vitals_developer_screen.dart';
import 'package:app/features/auth/ui/password_reset_page.dart';

/// Simple observer that logs push/pop events for diagnostics only.
class LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('NAV_PUSH: ${route.settings.name ?? route.settings}');
    _dumpPageStack('AFTER_PUSH');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('NAV_POP: ${route.settings.name ?? route.settings}');
    _dumpPageStack('AFTER_POP');
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint(
      'NAV_REPLACE: old=${oldRoute?.settings.name ?? oldRoute?.settings} -> new=${newRoute?.settings.name ?? newRoute?.settings}',
    );
    _dumpPageStack('AFTER_REPLACE');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('NAV_REMOVE: ${route.settings.name ?? route.settings}');
    _dumpPageStack('AFTER_REMOVE');
    super.didRemove(route, previousRoute);
  }

  void _dumpPageStack(String context) {
    if (navigator != null) {
      final pages = <String>[];
      for (final route in navigator!.widget.pages) {
        if (route is MaterialPage) {
          pages.add(
            'MaterialPage(key=${route.key}, child=${route.child.runtimeType})',
          );
        } else {
          pages.add(route.toString());
        }
      }
      debugPrint('PAGE_STACK_$context: [${pages.join(', ')}]');
    }
  }
}

/// Centralized route constants for the app.
const String kOnboardingStep1Route = '/onboarding/step1';
const String kOnboardingStep2Route = '/onboarding/step2';
const String kOnboardingStep3Route = '/onboarding/step3';
const String kOnboardingStep4Route = '/onboarding/step4';
const String kOnboardingStep5Route = '/onboarding/step5';
const String kOnboardingStep6Route = '/onboarding/step6';
const String kActionStepSetupRoute = '/action-step/setup';
// Route constants
const String kConfirmRoute = '/confirm';
const String kAuthRoute = '/auth';
const String kLoginRoute = '/login';

// NEW ROUTE CONSTANTS
const String kNotificationsRoute = '/notifications';
const String kProfileSettingsRoute = '/profile-settings';
const String kAchievementsRoute = '/achievements';
const String kProgressDashboardRoute = '/progress-dashboard';
const String kTodayFeedArticleRoute = '/today-feed/article';
const String kCoachChatRoute = '/coach-chat';
const String kPasswordResetRoute = '/password-reset';
const String kLiveVitalsDebugRoute = '/debug/live-vitals';
const String kLaunchRoute = '/launch';

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
  debugLogDiagnostics: true,
  observers: [LoggingNavigatorObserver()],
  navigatorKey: GlobalKey<NavigatorState>(),
  redirect: (context, state) {
    debugPrint(
      'REDIRECT_CALLED: for ${state.uri} (path=${state.path}, fullPath=${state.fullPath})',
    );
    final result = _onboardingGuard.call(context, state);
    debugPrint('REDIRECT_RESULT: $result');
    return result;
  },
  routes: [
    // --- Absolute paths (placed before other routes) ---
    GoRoute(
      path: kLoginRoute,
      pageBuilder: (context, state) {
        debugPrint('BUILDING_LOGIN_PAGE for ${state.uri}');
        return const MaterialPage<void>(
          key: ValueKey('LoginPage'),
          child: LoginPage(),
        );
      },
    ),
    GoRoute(
      path: kAuthRoute,
      pageBuilder: (context, state) {
        debugPrint('BUILDING_AUTH_PAGE for ${state.uri}');
        return const MaterialPage<void>(
          key: ValueKey('AuthPage'),
          child: AuthPage(),
        );
      },
    ),
    GoRoute(
      path: kConfirmRoute,
      builder: (_, state) {
        final email = state.extra as String? ?? '';
        return ConfirmationPendingPage(email: email);
      },
    ),
    GoRoute(path: kLaunchRoute, builder: (_, __) => const LaunchController()),

    // Onboarding and other feature routes
    // -----------------------------------------------------
    // Specific absolute paths (keep onboarding, action-step, etc.)
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
    // NEW ROUTES
    GoRoute(
      path: kNotificationsRoute,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: kProfileSettingsRoute,
      builder: (context, state) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: kAchievementsRoute,
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: kProgressDashboardRoute,
      builder: (context, state) => const ProgressDashboard(),
    ),
    GoRoute(
      path: kTodayFeedArticleRoute,
      builder: (context, state) {
        final content = state.extra as TodayFeedContent;
        return TodayFeedArticleScreen(content: content);
      },
    ),
    GoRoute(
      path: kCoachChatRoute,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CoachChatScreen(
          articleId: extra?['articleId'],
          articleSummary: extra?['articleSummary'],
          articleTitle: extra?['articleTitle'],
          showBackButton: true,
        );
      },
    ),
    GoRoute(
      path: kLiveVitalsDebugRoute,
      builder: (context, state) => const LiveVitalsDeveloperScreen(),
    ),
    GoRoute(
      path: kPasswordResetRoute,
      builder: (context, state) {
        final token = state.extra as String;
        return PasswordResetPage(accessToken: token);
      },
    ),

    // Root route LAST (acts as splash/login branch)
    GoRoute(
      path: '/',
      pageBuilder:
          (_, __) => const MaterialPage<void>(
            key: ValueKey('LaunchPage'),
            child: LaunchController(),
          ),
    ),
  ],
);

/// Sets up debugging listeners for GoRouter to diagnose navigation issues
void setupRouterDebugging() {
  // Dump all routes for debugging
  debugPrint('ROUTER_SETUP: Available routes:');
  try {
    for (int i = 0; i < appRouter.configuration.routes.length; i++) {
      final route = appRouter.configuration.routes[i];
      if (route is GoRoute) {
        debugPrint('  Route $i: path="${route.path}", name="${route.name}"');
      }
    }
  } catch (e) {
    debugPrint('ROUTER_SETUP: Error accessing routes: $e');
  }

  appRouter.routerDelegate.addListener(() {
    try {
      debugPrint(
        'ROUTER_DELEGATE changed: current=${appRouter.routerDelegate.currentConfiguration.uri}',
      );
      final config = appRouter.routerDelegate.currentConfiguration;
      debugPrint(
        'MATCHES: ${config.matches.map((m) => '${m.matchedLocation}(${m.route.runtimeType})').toList()}',
      );
    } catch (e) {
      debugPrint('ROUTER_DELEGATE: Error accessing config: $e');
    }
  });

  appRouter.routeInformationProvider.addListener(() {
    try {
      debugPrint(
        'ROUTE_INFO changed: ${appRouter.routeInformationProvider.value.uri}',
      );
    } catch (e) {
      debugPrint('ROUTE_INFO: Error accessing value: $e');
    }
  });
}
