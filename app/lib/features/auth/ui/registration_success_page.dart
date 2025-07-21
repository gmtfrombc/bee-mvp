import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';

/// Shown immediately after a user confirms their email address.
///
/// Displays a friendly "Registration successful" message and a button to
/// proceed to the onboarding flow.
class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A very simple intro screen.
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Registration Successful!\n\nWelcome to Momentum Coach. Tap the button below when you\'re ready to start your journey.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to the first onboarding step using go_router.
                  context.go(kOnboardingStep1Route);
                },
                child: const Text("I'm ready"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
