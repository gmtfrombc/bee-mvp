import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/supabase_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/widgets/splash_screen.dart';
import 'package:app/features/auth/ui/login_page.dart';
import 'package:app/main.dart';
import 'package:app/core/models/profile.dart';
import 'package:app/features/auth/ui/registration_success_page.dart';
import 'package:go_router/go_router.dart';

// Human-visible splash: show for ~1.5 s (UX best-practice is 1-2 s)
const Duration _minSplashDuration = Duration(milliseconds: 1500);

final _delayProvider = FutureProvider<void>((_) async {
  await Future.delayed(_minSplashDuration);
});

// Fetches the signed-in user's profile to determine onboarding status.
final _profileProvider = FutureProvider<Profile?>((ref) async {
  final authService = await ref.watch(authServiceProvider.future);
  final uid = authService.currentUser?.id;
  if (uid == null) return null;
  return authService.fetchProfile(uid);
});

/// LaunchController decides which top-level screen to show on cold-start.
///
/// 1. Shows [SplashScreen] while waiting for Supabase initialization
///    and session restoration.
/// 2. If no authenticated session exists, shows [LoginPage] (which contains
///    navigation to registration).
/// 3. If a session exists, navigates directly to [AppWrapper].
class LaunchController extends ConsumerWidget {
  const LaunchController({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wait for Supabase init and minimum splash duration.
    final supabaseAsync = ref.watch(supabaseProvider);
    final delayAsync = ref.watch(_delayProvider);

    if (supabaseAsync.isLoading || delayAsync.isLoading) {
      debugPrint(
        '🌀 LaunchController: waiting – supabase=${supabaseAsync.isLoading} delay=${delayAsync.isLoading}',
      );
      return const SplashScreen();
    }

    if (supabaseAsync.hasError) {
      // In case initialization fails, show a basic error screen with retry.
      return _ErrorScreen(
        error: supabaseAsync.error!,
        onRetry: () {
          ref.invalidate(supabaseProvider);
        },
      );
    }

    // Once Supabase is ready, determine auth state.
    final userAsync = ref.watch(currentUserProvider);
    debugPrint(
      '👤 LaunchController: currentUserProvider state = ${userAsync.runtimeType}',
    );

    return userAsync.when(
      loading: () {
        debugPrint('⏳ LaunchController: userAsync loading');
        return const SplashScreen();
      },
      error:
          (err, _) => _ErrorScreen(
            error: err,
            onRetry: () {
              ref.invalidate(currentUserProvider);
            },
          ),
      data: (user) {
        debugPrint('📊 LaunchController: user data resolved = $user');
        if (user == null) {
          // No session → redirect to /login so routing stays flat.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/login');
            }
          });
          // While redirection happens, keep showing splash.
          debugPrint('🔀 LaunchController: redirecting to /login');
          return const SplashScreen();
        }

        // Authenticated – decide onboarding.
        final profileAsync = ref.watch(_profileProvider);

        return profileAsync.when(
          loading: () => const SplashScreen(),
          error: (err, _) {
            // If profile fetch fails (e.g., user deleted – stale session),
            // automatically purge local session and redirect to /login.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            });
            debugPrint(
              '🔀 LaunchController: stale session redirecting to /login',
            );
            return const SplashScreen();
          },
          data: (profile) {
            final needsOnboarding =
                profile == null || profile.onboardingComplete == false;
            if (needsOnboarding) {
              return const RegistrationSuccessPage();
            }
            return const AppWrapper();
          },
        );
      },
    );
  }
}

/// Simple error screen shown when initialization fails.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Initialization failed:\n$error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
