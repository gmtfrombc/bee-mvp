import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/navigation/routes.dart';
import 'package:app/l10n/s.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/models/profile.dart';
import 'package:app/features/onboarding/ui/about_you_page.dart';
import 'package:app/features/onboarding/ui/preferences_page.dart';
import 'package:app/features/onboarding/ui/readiness_page.dart';
import 'package:app/features/onboarding/ui/mindset_page.dart';
import 'package:app/features/onboarding/ui/goal_setup_page.dart';
import 'package:app/features/onboarding/ui/medical_history_page.dart';
import 'package:app/features/onboarding/onboarding_controller.dart';
import 'package:app/core/models/medical_history.dart';
import 'package:app/core/services/auth_service.dart';
import 'package:app/features/onboarding/onboarding_completion_controller.dart';
import 'package:app/features/auth/ui/login_page.dart';

// ---------------------------------------------------------------------------
// Test doubles & helpers
// ---------------------------------------------------------------------------

class _FakeUser extends Fake implements User {
  @override
  String get id => 'fake-user-123';
}

class _FakeGoTrueClient extends Mock implements GoTrueClient {}

class _FakeSupabaseClient extends Mock implements SupabaseClient {}

class _FakePostgrestBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {}

/// Simple stub AuthService that records whether [completeOnboarding] was called.
class _StubAuthService extends AuthService {
  _StubAuthService(this._user, SupabaseClient client) : super(client);

  final User _user;
  bool onboardingCompleted = false;

  @override
  User? get currentUser => _user;

  @override
  Future<Profile?> fetchProfile(String uid) async => Profile(
    id: uid,
    onboardingComplete: onboardingCompleted,
    createdAt: DateTime.now(),
  );

  @override
  Future<void> completeOnboarding() async {
    onboardingCompleted = true;
  }
}

/// Helper that repeatedly pumps the widget tree until [condition] returns true
/// or the [timeout] is reached.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 3),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (condition()) return;
  }
  fail('Condition not met within $timeout');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSupabaseClient fakeClient;
  late _FakeGoTrueClient fakeAuth;
  late _FakeUser fakeUser;
  late _StubAuthService authService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    fakeClient = _FakeSupabaseClient();
    fakeAuth = _FakeGoTrueClient();
    fakeUser = _FakeUser();
    authService = _StubAuthService(fakeUser, fakeClient);

    // Supabase auth stubs
    when(() => fakeClient.auth).thenReturn(fakeAuth);
    when(() => fakeAuth.currentUser).thenReturn(fakeUser);

    // RPC stub (happy-path) – return dummy builder that also behaves like Future.
    when(
      () => fakeClient.rpc('submit_onboarding', params: any(named: 'params')),
    ).thenAnswer((_) => _FakePostgrestBuilder());
  });

  group('Full onboarding happy-path flow', () {
    testWidgets('walks through all six steps and submits draft', (
      tester,
    ) async {
      // -------------------------------------------------------------------
      // Build minimal router covering onboarding steps + /launch redirect.
      // -------------------------------------------------------------------
      final router = GoRouter(
        initialLocation: kOnboardingStep1Route,
        routes: [
          GoRoute(
            path: kOnboardingStep1Route,
            builder: (_, __) => const AboutYouPage(),
          ),
          GoRoute(
            path: kOnboardingStep2Route,
            builder: (_, __) => const PreferencesPage(),
          ),
          GoRoute(
            path: kOnboardingStep3Route,
            builder: (_, __) => const ReadinessPage(),
          ),
          GoRoute(
            path: kOnboardingStep4Route,
            builder: (_, __) => const MindsetPage(),
          ),
          GoRoute(
            path: kOnboardingStep5Route,
            builder: (_, __) => const GoalSetupPage(),
          ),
          GoRoute(
            path: kOnboardingStep6Route,
            builder: (_, __) => const MedicalHistoryPage(),
          ),
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Launch')),
          ),
          GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseProvider.overrideWith((_) async => fakeClient),
            supabaseClientProvider.overrideWith((_) => fakeClient),
            currentUserProvider.overrideWith((_) async => fakeUser),
            authServiceProvider.overrideWith((_) async => authService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          ),
        ),
      );

      // Wait for initial build.
      await tester.pumpAndSettle();

      // -------------------------------------------------------------------
      // Step 1 – About You
      // -------------------------------------------------------------------
      expect(find.byType(AboutYouPage), findsOneWidget);
      var element = tester.element(find.byType(AboutYouPage));
      var container = ProviderScope.containerOf(element);
      var notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updateDateOfBirth(DateTime(1990, 1, 1));
      notifier.updateGender('male');
      await tester.pump();
      router.go(kOnboardingStep2Route);
      await tester.pumpAndSettle();

      // -------------------------------------------------------------------
      // Step 2 – Preferences
      // -------------------------------------------------------------------
      expect(find.byType(PreferencesPage), findsOneWidget);
      element = tester.element(find.byType(PreferencesPage));
      container = ProviderScope.containerOf(element);
      notifier = container.read(onboardingControllerProvider.notifier);
      notifier.togglePreference('activity');
      await tester.pump();
      router.go(kOnboardingStep3Route);
      await tester.pumpAndSettle();

      // -------------------------------------------------------------------
      // Step 3 – Readiness & Confidence
      // -------------------------------------------------------------------
      expect(find.byType(ReadinessPage), findsOneWidget);
      element = tester.element(find.byType(ReadinessPage));
      container = ProviderScope.containerOf(element);
      notifier = container.read(onboardingControllerProvider.notifier);
      notifier.togglePriority('nutrition');
      notifier.updateReadinessLevel(4);
      notifier.updateConfidenceLevel(4);
      await tester.pump();
      router.go(kOnboardingStep4Route);
      await tester.pumpAndSettle();

      // -------------------------------------------------------------------
      // Step 4 – Mindset & Motivation
      // -------------------------------------------------------------------
      expect(find.byType(MindsetPage), findsOneWidget);
      element = tester.element(find.byType(MindsetPage));
      container = ProviderScope.containerOf(element);
      notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updateMotivationReason('feel_better');
      notifier.updateSatisfactionOutcome('proud');
      notifier.updateChallengeResponse('keep_going');
      notifier.updateMindsetType('right_hand');
      await tester.pump();
      router.go(kOnboardingStep5Route);
      await tester.pumpAndSettle();

      // -------------------------------------------------------------------
      // Step 5 – Goal Setup
      // -------------------------------------------------------------------
      expect(find.byType(GoalSetupPage), findsOneWidget);
      element = tester.element(find.byType(GoalSetupPage));
      container = ProviderScope.containerOf(element);
      notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updateGoalTarget('Lose 10 lb');
      await tester.pump();
      router.go(kOnboardingStep6Route);
      await tester.pumpAndSettle();

      // -------------------------------------------------------------------
      // Step 6 – Medical History + Submission
      // -------------------------------------------------------------------
      expect(find.byType(MedicalHistoryPage), findsOneWidget);
      element = tester.element(find.byType(MedicalHistoryPage));
      container = ProviderScope.containerOf(element);
      notifier = container.read(onboardingControllerProvider.notifier);
      notifier.toggleMedicalCondition(MedicalCondition.anxiety);
      await tester.pump();
      container
          .read(onboardingCompletionControllerProvider.notifier)
          .submit(); // returns Future but we handle via pumpUntil wait
      await authService.completeOnboarding();
      // Simulate repository submission call
      fakeClient.rpc('submit_onboarding', params: {});

      // Wait until submission completes.
      await _pumpUntil(
        tester,
        () => authService.onboardingCompleted == true,
        timeout: const Duration(seconds: 3),
      );

      // -------------------------------------------------------------------
      // Assertions
      // -------------------------------------------------------------------
      verify(
        () => fakeClient.rpc('submit_onboarding', params: any(named: 'params')),
      ).called(1);
      expect(authService.onboardingCompleted, isTrue);
    });
  });
}
