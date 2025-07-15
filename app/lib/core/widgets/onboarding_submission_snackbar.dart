import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/onboarding_completion_controller.dart';
import 'package:app/core/services/action_step_status_service.dart';
import 'package:app/core/navigation/routes.dart';

/// Listens to [onboardingCompletionControllerProvider] and shows contextual
/// snackbars during the submission pipeline. It also redirects to the
/// "/launch" route once the submission succeeds.
///
/// Usage: simply place this widget anywhere inside a [Scaffold] so it has
/// access to the surrounding [BuildContext]. The widget does not render any
/// visual element itself.
class OnboardingSubmissionSnackbar extends ConsumerWidget {
  const OnboardingSubmissionSnackbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(onboardingCompletionControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        loading: () {
          // Hide an existing snackbar before showing a new one.
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(days: 1), // effectively indefinite
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Submitting your answers…'),
                ],
              ),
            ),
          );
        },
        error: (err, _) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.error,
              content: const Text('Submission failed. Please try again.'),
            ),
          );
        },
        data: (_) {
          // Only act if previous state was loading (avoid showing success on init)
          if (previous?.isLoading ?? false) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                content: const Text('Onboarding complete!'),
              ),
            );
            // Decide next navigation: if user has not yet set an Action Step,
            // offer them the chance via a modal prompt; otherwise go to launch.

            () async {
              // Wait briefly so the success snackbar is visible.
              await Future.delayed(const Duration(milliseconds: 500));

              if (!context.mounted) return;

              final statusService = ActionStepStatusService();
              final hasSetActionStep = await statusService.hasSetActionStep();

              if (!context.mounted) return;

              if (!hasSetActionStep) {
                // Show modal dialog prompting to set the first Action Step.
                final proceed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Set your first Action Step?'),
                        content: const Text(
                          'You can track weekly goals to build momentum. Would you like to set your first Action Step now?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Later'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Set Now'),
                          ),
                        ],
                      ),
                );

                // If user cancelled dialog (back button) treat as Later.
                final wantsActionStep = proceed == true;

                if (!context.mounted) return;

                if (wantsActionStep) {
                  context.go(kActionStepSetupRoute);
                } else {
                  context.go('/launch');
                }
              } else {
                context.go('/launch');
              }
            }();
          }
        },
      );
    });

    // Widget renders nothing.
    return const SizedBox.shrink();
  }
}
