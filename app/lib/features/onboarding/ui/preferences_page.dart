import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/theme/app_theme.dart';
import 'readiness_page.dart';
import '../onboarding_controller.dart';
import '../../../core/mixins/input_validator.dart';
import '../../../core/widgets/step_progress_bar.dart';

/// Onboarding step 2 – lets users pick 1–5 lifestyle preference areas.
class PreferencesPage extends ConsumerWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onboardingControllerProvider.notifier);
    final draft = ref.watch(onboardingControllerProvider);

    final spacing = ResponsiveService.getSmallSpacing(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Preferences')),
      body: Padding(
        padding: ResponsiveService.getMediumPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepProgressBar(currentStep: 2, totalSteps: 6),
            SizedBox(height: spacing),
            _PreferenceChips(
              selectedKeys: draft.preferences,
              onToggle: controller.togglePreference,
              spacing: spacing,
            ),
            SizedBox(height: spacing),
            if (InputValidatorUtils.preferences(draft.preferences) != null)
              Text(
                InputValidatorUtils.preferences(draft.preferences)!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            SizedBox(height: spacing * 3),
            ElevatedButton(
              key: const ValueKey('continue_button'),
              onPressed:
                  draft.preferences.isNotEmpty
                      ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ReadinessPage(),
                          ),
                        );
                      }
                      : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets & helpers
// ---------------------------------------------------------------------------

class _PreferenceChips extends StatelessWidget {
  const _PreferenceChips({
    required this.selectedKeys,
    required this.onToggle,
    required this.spacing,
  });

  final List<String> selectedKeys;
  final ValueChanged<String> onToggle;
  final double spacing;

  static const _options = <_PreferenceOption>[
    _PreferenceOption(
      key: 'activity',
      icon: Icons.fitness_center,
      color: AppTheme.vitalsSteps,
      label: 'Activity',
    ),
    _PreferenceOption(
      key: 'nutrition',
      icon: Icons.restaurant,
      color: AppTheme.momentumCare,
      label: 'Nutrition',
    ),
    _PreferenceOption(
      key: 'sleep',
      icon: Icons.night_shelter,
      color: AppTheme.vitalsSleep,
      label: 'Sleep',
    ),
    _PreferenceOption(
      key: 'mindfulness',
      icon: Icons.self_improvement,
      color: AppTheme.accentPurple,
      label: 'Mindfulness',
    ),
    _PreferenceOption(
      key: 'social',
      icon: Icons.group,
      color: AppTheme.momentumSteady,
      label: 'Social',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children:
          _options.map((option) {
            final selected = selectedKeys.contains(option.key);
            return FilterChip(
              key: ValueKey('chip_${option.key}'),
              label: Text(option.label),
              avatar: Icon(
                option.icon,
                size: 18,
                color:
                    selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : option.color,
              ),
              selected: selected,
              selectedColor: option.color,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              onSelected: (_) => onToggle(option.key),
              showCheckmark: false,
              labelStyle: TextStyle(
                color:
                    selected ? Theme.of(context).colorScheme.onPrimary : null,
              ),
            );
          }).toList(),
    );
  }
}

/// Simple value class for chip metadata.
class _PreferenceOption {
  const _PreferenceOption({
    required this.key,
    required this.icon,
    required this.color,
    required this.label,
  });

  final String key;
  final IconData icon;
  final Color color;
  final String label;
}
