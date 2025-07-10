import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../onboarding_controller.dart';
import 'medical_history_page.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Goal Setup')),
      body: SingleChildScrollView(
        padding: ResponsiveService.getMediumPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: 'Outcome Goal',
                  hintText: 'e.g. Lose 10 lb in 3 months',
                ),
                maxLength: 120,
                onChanged: controller.updateGoalTarget,
                validator:
                    (val) =>
                        (val == null || val.trim().isEmpty) ? 'Required' : null,
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Goal saved!')),
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MedicalHistoryPage(),
                            ),
                          );
                        }
                        : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
