import 'package:flutter/material.dart';
import '../services/responsive_service.dart';

/// Displays a horizontal progress indicator with a \"current / total\" label
/// used for the multi-step onboarding flow.
///
/// The widget uses responsive spacing and theme colors – no magic numbers.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  /// 1-based index of the current step.
  final int currentStep;

  /// Total number of steps in the flow.
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    // Clamp to avoid divide-by-zero and ensure progress stays within 0-1.
    final safeTotal = totalSteps == 0 ? 1 : totalSteps;
    final displayedStep = currentStep.clamp(0, safeTotal);
    final progress = displayedStep / safeTotal;

    final spacing = ResponsiveService.getSmallSpacing(context);
    final barHeight = ResponsiveService.getTinySpacing(context) * 2;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing * 0.5),
      child: Row(
        children: [
          // Progress bar ----------------------------------------------------
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(barHeight / 2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: barHeight,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: spacing),
          // Label -----------------------------------------------------------
          Text(
            '$displayedStep/$safeTotal',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
