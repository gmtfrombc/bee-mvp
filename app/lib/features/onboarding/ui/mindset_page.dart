import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../l10n/s.dart';
import '../onboarding_controller.dart';
import 'goal_setup_page.dart';
import '../../../core/widgets/step_progress_bar.dart';
import 'package:app/core/widgets/can_pop_scope.dart';

/// Onboarding step for mindset & motivation assessment (Q13–16).
///
/// Captures user motivation reason, satisfaction outcome, challenge response,
/// and preferred coach style using single-choice components.
class MindsetPage extends ConsumerWidget {
  const MindsetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onboardingControllerProvider.notifier);
    final draft = ref.watch(onboardingControllerProvider);
    final spacing = ResponsiveService.getMediumSpacing(context);

    return CanPopScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Mindset & Motivation')),
        body: SingleChildScrollView(
          padding: ResponsiveService.getMediumPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepProgressBar(currentStep: 4, totalSteps: 6),
              SizedBox(height: spacing),
              // Q13 Motivation Reason
              _SingleChoiceSection<String>(
                title: S.of(context).onboarding_q13_prompt,
                options: const {
                  'feel_better': 'I want to improve how I feel',
                  'look_better': 'I want to look better',
                  'social_pressure': 'I feel social pressure from others',
                  'take_care': 'I want to take better care of myself',
                  'someone_else': 'I’m doing this for someone else',
                },
                groupValue: draft.motivationReason,
                onChanged: controller.updateMotivationReason,
              ),
              SizedBox(height: spacing * 2),

              // Q14 Satisfaction Outcome
              _SingleChoiceSection<String>(
                title: S.of(context).onboarding_q14_prompt,
                options: const {
                  'proud': 'Feeling proud of myself',
                  'seen_differently': 'Being seen differently by others',
                  'prove': 'Proving I can do it',
                  'avoid_health_problems': 'Avoiding health problems',
                },
                groupValue: draft.satisfactionOutcome,
                onChanged: controller.updateSatisfactionOutcome,
              ),
              SizedBox(height: spacing * 2),

              // Q15 Challenge Response
              _SingleChoiceSection<String>(
                title: S.of(context).onboarding_q15_prompt,
                options: const {
                  'keep_going': 'Keep going',
                  'new_approach': 'Look for a new approach',
                  'pause': 'Pause or back off',
                  'overwhelmed': 'Feel overwhelmed',
                },
                groupValue: draft.challengeResponse,
                onChanged: controller.updateChallengeResponse,
              ),
              SizedBox(height: spacing * 2),

              // Q16 Coach Style (mindsetType)
              _SingleChoiceSection<String>(
                title: S.of(context).onboarding_q16_prompt,
                options: const {
                  'right_hand': 'Right Hand – Listens and checks in',
                  'cheerleader': 'Cheerleader – Encourages me',
                  'drill_sergeant': 'Drill Sergeant – Holds me to goals',
                  'not_sure': 'I’m not sure yet',
                },
                groupValue: draft.mindsetType,
                onChanged: controller.updateMindsetType,
              ),
              SizedBox(height: spacing * 3),

              ElevatedButton(
                key: const ValueKey('continue_button'),
                onPressed:
                    controller.isMindsetComplete
                        ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mindset saved!')),
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const GoalSetupPage(),
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

// ---------------------------------------------------------------------------
// Reusable single-choice section widget
// ---------------------------------------------------------------------------
class _SingleChoiceSection<T> extends StatelessWidget {
  const _SingleChoiceSection({
    required this.title,
    required this.options,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final Map<String, String> options; // key → label
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getSmallSpacing(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing),
        ...options.entries.map(
          (entry) => RadioListTile<String>(
            key: ValueKey('${entry.key}_radio'),
            title: Text(entry.value),
            value: entry.key,
            groupValue: groupValue,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
