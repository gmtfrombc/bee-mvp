// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// removed go_router dependency

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/responsive_service.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';

/// Simple single-page onboarding screen.
///
/// When the user presses the "Get Started" button we:
/// 1. Mark onboarding as complete via [AuthService.completeOnboarding].
/// 2. Navigate to the app root so the normal flow (AppWrapper) resumes.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ResponsiveService.getLargeSpacing(context);

    final authServiceAsync = ref.watch(authServiceProvider);

    return authServiceAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, _) => Scaffold(
            appBar: AppBar(title: const Text('Onboarding')),
            body: Center(child: Text('Error: $error')),
          ),
      data:
          (authService) => Scaffold(
            appBar: AppBar(title: const Text('Onboarding')),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(
                  ResponsiveService.getExtraLargeSpacing(context),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome to the onboarding flow!\nTap below when you\'re ready.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing),
                    ElevatedButton(
                      onPressed: () async {
                        await authService.completeOnboarding();
                        if (context.mounted) {
                          // Navigate to the main launch route using go_router.
                          context.go(kLaunchRoute);
                        }
                      },
                      child: const Text('Get Started'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
