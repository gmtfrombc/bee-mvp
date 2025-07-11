import 'package:flutter/material.dart';
import 'package:app/features/onboarding/ui/about_you_page.dart';

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
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AboutYouPage()),
                  );
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
