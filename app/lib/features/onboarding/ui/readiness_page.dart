import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/widgets/likert_selector.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../../../l10n/s.dart';
import '../models/onboarding_draft.dart';
import '../onboarding_controller.dart';
import 'package:app/core/widgets/can_pop_scope.dart';
import '../../../core/widgets/onboarding_logout_button.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/routes.dart';

/// Onboarding step for readiness and confidence assessment (Q10-12).
///
/// Captures user priorities, readiness level, and confidence level
/// using validated Likert-scale and multi-choice components.
class ReadinessPage extends ConsumerWidget {
  const ReadinessPage({super.key});

  static const List<String> _priorityOptions = [
    'nutrition',
    'exercise',
    'sleep',
    'stress',
    'weight',
    'energy',
    'mental_health',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onboardingControllerProvider.notifier);
    final draft = ref.watch(onboardingControllerProvider);
    final spacing = ResponsiveService.getMediumSpacing(context);
    final theme = Theme.of(context);

    return CanPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Readiness & Priorities'),
          actions: const [OnboardingLogoutButton()],
        ),
        body: SingleChildScrollView(
          padding: ResponsiveService.getMediumPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepProgressBar(currentStep: 3, totalSteps: 6),
              SizedBox(height: spacing),
              // Q10: Priority Selection
              _buildPrioritySection(context, controller, draft, spacing, theme),

              SizedBox(height: spacing * 2),

              // Q11: Readiness Level
              _buildReadinessSection(context, controller, draft, spacing),

              SizedBox(height: spacing * 2),

              // Q12: Confidence Level
              _buildConfidenceSection(context, controller, draft, spacing),

              SizedBox(height: spacing * 3),

              // Continue Button
              _buildContinueButton(context, controller, draft),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySection(
    BuildContext context,
    OnboardingController controller,
    OnboardingDraft draft,
    double spacing,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).onboarding_q10_prompt,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your top 1-2 priorities:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing),
        Wrap(
          spacing: spacing * 0.5,
          runSpacing: spacing * 0.5,
          children:
              _priorityOptions.map((priority) {
                final isSelected = draft.priorities.contains(priority);
                return _PriorityChip(
                  key: ValueKey('priority_$priority'),
                  label: _getPriorityLabel(priority),
                  selected: isSelected,
                  onTap: () => controller.togglePriority(priority),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildReadinessSection(
    BuildContext context,
    OnboardingController controller,
    OnboardingDraft draft,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).onboarding_q11_prompt,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: spacing),
        LikertSelector(
          value: draft.readinessLevel,
          onChanged: controller.updateReadinessLevel,
          semanticLabel: S.of(context).onboarding_q11_prompt,
        ),
      ],
    );
  }

  Widget _buildConfidenceSection(
    BuildContext context,
    OnboardingController controller,
    OnboardingDraft draft,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).onboarding_q12_prompt,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: spacing),
        LikertSelector(
          value: draft.confidenceLevel,
          onChanged: controller.updateConfidenceLevel,
          semanticLabel: S.of(context).onboarding_q12_prompt,
        ),
      ],
    );
  }

  Widget _buildContinueButton(
    BuildContext context,
    OnboardingController controller,
    OnboardingDraft draft,
  ) {
    return ElevatedButton(
      key: const ValueKey('continue_button'),
      onPressed:
          controller.isReadinessComplete
              ? () {
                final router = GoRouter.maybeOf(context);
                if (router != null) {
                  router.push(kOnboardingStep4Route);
                }
              }
              : null,
      child: const Text('Continue'),
    );
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'nutrition':
        return 'Nutrition';
      case 'exercise':
        return 'Exercise';
      case 'sleep':
        return 'Sleep';
      case 'stress':
        return 'Stress';
      case 'weight':
        return 'Weight';
      case 'energy':
        return 'Energy';
      case 'mental_health':
        return 'Mental Health';
      default:
        return priority;
    }
  }
}

// ---------------------------------------------------------------------------
// Private reusable PriorityChip widget (high-contrast guaranteed)
// ---------------------------------------------------------------------------
class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final background =
        selected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest;

    final textColor = selected ? colorScheme.onPrimary : colorScheme.onSurface;

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colorScheme.primary : background,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
