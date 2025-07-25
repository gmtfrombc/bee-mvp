import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../onboarding_controller.dart';
import '../../../core/widgets/step_progress_bar.dart';
import 'package:app/core/widgets/can_pop_scope.dart';
import '../../../core/ui/widgets/bee_text_field.dart';
import '../../../core/ui/bee_toast.dart';
import '../../../core/widgets/onboarding_logout_button.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/routes.dart';

/// Onboarding step for users to specify their main outcome goal.
///
/// This simple form captures a free-text goal description for now.
/// Validation ensures the field is non-empty. Future tasks will
/// extend this UI with dynamic numeric inputs when relevant.
class GoalSetupPage extends ConsumerStatefulWidget {
  const GoalSetupPage({super.key});

  @override
  ConsumerState<GoalSetupPage> createState() => _GoalSetupPageState();
}

class _GoalSetupPageState extends ConsumerState<GoalSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(onboardingControllerProvider.notifier);
    final draft = ref.watch(onboardingControllerProvider);

    // Keep TextEditingController in sync with provider state on rebuild.
    if (_goalController.text != (draft.goalTarget ?? '')) {
      _goalController.text = draft.goalTarget ?? '';
      _goalController.selection = TextSelection.fromPosition(
        TextPosition(offset: _goalController.text.length),
      );
    }

    final spacing = ResponsiveService.getMediumSpacing(context);

    return CanPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Goal Setup'),
          actions: const [OnboardingLogoutButton()],
        ),
        body: SingleChildScrollView(
          padding: ResponsiveService.getMediumPadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StepProgressBar(currentStep: 5, totalSteps: 6),
                SizedBox(height: spacing * 2),
                BeeTextField(
                  controller: _goalController,
                  label: 'Outcome Goal',
                  hint: 'e.g. Lose 10 lb in 3 months',
                  maxLength: 120,
                  onChanged: controller.updateGoalTarget,
                  validator:
                      (val) =>
                          (val == null || val.trim().isEmpty)
                              ? 'Required'
                              : null,
                ),
                SizedBox(height: spacing * 2),
                ElevatedButton(
                  key: const ValueKey('continue_button'),
                  onPressed:
                      controller.isGoalSetupComplete
                          ? () {
                            if (!(_formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            showBeeToast(
                              context,
                              'Goal saved!',
                              type: BeeToastType.success,
                            );
                            context.push(kOnboardingStep6Route);
                          }
                          : null,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
