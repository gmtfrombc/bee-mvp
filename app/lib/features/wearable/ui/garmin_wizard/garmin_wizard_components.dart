/// Garmin Wizard UI Components
///
/// Reusable UI components for the Garmin→Apple Health enablement wizard,
/// including individual step widgets, progress indicators, and action buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/responsive_service.dart';
import 'garmin_wizard_models.dart';
import 'garmin_wizard_provider.dart';

/// Individual wizard step widget
class GarminWizardStepWidget extends StatelessWidget {
  final GarminWizardStep step;
  final int stepNumber;
  final bool isExpanded;
  final VoidCallback onToggleComplete;

  const GarminWizardStepWidget({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.isExpanded,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveService.getSmallSpacing(context),
      ),
      decoration: BoxDecoration(
        color: step.isCompleted ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(
          color: step.isCompleted ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          leading: _buildStepIndicator(context),
          title: Text(
            step.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: step.isCompleted ? Colors.green[800] : Colors.grey[800],
            ),
          ),
          subtitle: Text(
            step.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: step.isCompleted ? Colors.green[600] : Colors.grey[600],
            ),
          ),
          trailing: Checkbox(
            value: step.isCompleted,
            onChanged: (_) => onToggleComplete(),
            activeColor: Colors.green,
          ),
          children: [
            Padding(
              padding: ResponsiveService.getMediumPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  SizedBox(height: ResponsiveService.getSmallSpacing(context)),
                  ...step.instructions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final instruction = entry.value;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: ResponsiveService.getSmallSpacing(context),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: EdgeInsets.only(
                              right: ResponsiveService.getSmallSpacing(context),
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              instruction,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color:
            step.isCompleted
                ? Colors.green
                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child:
          step.isCompleted
              ? const Icon(
                CupertinoIcons.checkmark,
                color: Colors.white,
                size: 20,
              )
              : Icon(
                step.icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
    );
  }
}

/// Wizard header with title and description
class GarminWizardHeader extends StatelessWidget {
  const GarminWizardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.device_phone_portrait,
              color: Theme.of(context).primaryColor,
              size: ResponsiveService.getIconSize(context, baseSize: 24),
            ),
            SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            Icon(
              CupertinoIcons.arrow_right,
              color: Colors.grey[400],
              size: ResponsiveService.getIconSize(context, baseSize: 16),
            ),
            SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            Icon(
              CupertinoIcons.heart_fill,
              color: Colors.red,
              size: ResponsiveService.getIconSize(context, baseSize: 24),
            ),
          ],
        ),
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        Text(
          'Connect Garmin to Apple Health',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        Text(
          'Follow these steps to enable your Garmin device data to flow into Apple Health for the BEE app to use.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Progress indicator showing completion status
class GarminWizardProgressIndicator extends StatelessWidget {
  final GarminWizardState state;

  const GarminWizardProgressIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final completedSteps = state.steps.where((step) => step.isCompleted).length;
    final totalSteps = state.steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '$completedSteps / $totalSteps',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        LinearProgressIndicator(
          value: totalSteps > 0 ? completedSteps / totalSteps : 0.0,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}

/// Action buttons for wizard completion and dismissal
class GarminWizardActions extends ConsumerWidget {
  final GarminWizardState state;
  final VoidCallback? onCompleted;
  final VoidCallback? onDismissed;

  const GarminWizardActions({
    super.key,
    required this.state,
    this.onCompleted,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (state.isCompleted) ...[
          Container(
            padding: ResponsiveService.getMediumPadding(context),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(
                ResponsiveService.getBorderRadius(context),
              ),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Colors.green[700],
                  size: 20,
                ),
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                Expanded(
                  child: Text(
                    'Setup complete! Your Garmin data should now sync to Apple Health.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.green[800]),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(garminWizardProvider.notifier).dismissWizard();
                  onDismissed?.call();
                },
                child: const Text('Skip for Now'),
              ),
            ),
            SizedBox(width: ResponsiveService.getMediumSpacing(context)),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    state.isCompleted
                        ? () {
                          onCompleted?.call();
                          ref
                              .read(garminWizardProvider.notifier)
                              .dismissWizard();
                        }
                        : null,
                child: Text(state.isCompleted ? 'Done' : 'Complete Steps'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Steps content area that displays all wizard steps
class GarminWizardStepsContent extends ConsumerWidget {
  final GarminWizardState state;

  const GarminWizardStepsContent({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children:
          state.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;

            return GarminWizardStepWidget(
              step: step,
              stepNumber: index + 1,
              isExpanded: index == state.currentStepIndex || step.isCompleted,
              onToggleComplete: () {
                if (step.isCompleted) {
                  ref.read(garminWizardProvider.notifier).uncompleteStep(index);
                } else {
                  ref.read(garminWizardProvider.notifier).completeStep(index);
                }
              },
            );
          }).toList(),
    );
  }
}
