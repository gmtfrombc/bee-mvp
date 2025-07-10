import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/widgets/likert_selector.dart';
import '../../../l10n/s.dart';
import '../models/onboarding_draft.dart';
import '../onboarding_controller.dart';
import 'mindset_page.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Readiness & Priorities')),
      body: SingleChildScrollView(
        padding: ResponsiveService.getMediumPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                return FilterChip(
                  key: ValueKey('priority_$priority'),
                  label: Text(
                    _getPriorityLabel(priority),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    controller.togglePriority(priority);
                  },
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  checkmarkColor: theme.colorScheme.primary,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Readiness assessment saved!')),
                );
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const MindsetPage()));
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
