// NOTE (T19): Upon successful Action Step submission this form now shows
// a confirmation snackbar *and* navigates home via GoRouter (kLaunchRoute).
// Keeping this comment ensures a diff so CI runs when the branch PR is opened.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/responsive_service.dart';
import '../state/action_step_controller.dart';
import 'widgets/action_step_frequency_selector.dart';
import '../validators/action_step_validators.dart';
// Added for navigation after successful save
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';
import 'package:app/features/action_steps/models/action_step.dart';
import 'package:app/features/action_steps/data/action_step_repository.dart';
import 'package:app/features/action_steps/services/action_step_analytics.dart';

/// Form capturing Action Step details (category, description, frequency).
class ActionStepForm extends ConsumerStatefulWidget {
  const ActionStepForm({super.key, this.initialStep});

  /// When non-null the form is in "edit" mode and pre-filled with the given
  /// [ActionStep]. Submission will update the existing row instead of insert.
  final ActionStep? initialStep;

  @override
  ConsumerState<ActionStepForm> createState() => _ActionStepFormState();
}

class _ActionStepFormState extends ConsumerState<ActionStepForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();

  bool _isSubmitting = false;

  bool get _isEditing => widget.initialStep != null;

  static const _categories = <String>[
    'exercise',
    'nutrition',
    'sleep',
    'stress',
    'mindfulness',
  ];

  @override
  void initState() {
    super.initState();

    // Pre-fill draft when editing an existing Action Step.
    if (widget.initialStep != null) {
      final step = widget.initialStep!;
      _descriptionCtrl.text = step.description;

      final controller = ref.read(actionStepControllerProvider.notifier);
      controller.updateCategory(step.category);
      controller.updateDescription(step.description);
      controller.updateFrequency(step.frequency);
    }
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(actionStepControllerProvider.notifier);
    final draft = ref.watch(actionStepControllerProvider);

    final spacing = ResponsiveService.getMediumSpacing(context);

    return SingleChildScrollView(
      padding: ResponsiveService.getMediumPadding(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category dropdown
            DropdownButtonFormField<String>(
              value: draft.category,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(labelText: 'Category'),
              items:
                  _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
              onChanged: controller.updateCategory,
              validator:
                  (val) => (val == null || val.isEmpty) ? 'Required' : null,
            ),
            SizedBox(height: spacing),

            // Description field
            TextFormField(
              controller: _descriptionCtrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLength: 80,
              onChanged: controller.updateDescription,
              validator: positivePhraseValidator,
            ),
            SizedBox(height: spacing),

            // Frequency selector
            Text(
              'Frequency (days per week)',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            SizedBox(height: spacing * 0.5),
            ActionStepFrequencySelector(
              selected: draft.frequency,
              onChanged: controller.updateFrequency,
            ),
            SizedBox(height: spacing * 2),

            // Primary button
            ElevatedButton(
              onPressed:
                  (controller.isComplete && !_isSubmitting)
                      ? () async {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isSubmitting = true);

                        try {
                          if (_isEditing) {
                            // Update existing row.
                            final repo = ref.read(actionStepRepositoryProvider);
                            final old = widget.initialStep!;
                            final updated = ActionStep(
                              id: old.id,
                              category: draft.category ?? old.category,
                              description: draft.description,
                              frequency: draft.frequency,
                              weekStart: old.weekStart,
                              createdAt: old.createdAt,
                              updatedAt: DateTime.now().toUtc(),
                            );

                            await repo.updateActionStep(updated);

                            // Log analytics
                            final analytics =
                                ref.read(actionStepAnalyticsProvider);
                            await analytics.logEdit(
                              actionStepId: updated.id,
                              category: updated.category,
                              description: updated.description,
                              frequency: updated.frequency,
                            );

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Action Step updated!'),
                              ),
                            );

                            if (context.mounted) {
                              context.go(kActionStepCurrentRoute);
                            }
                          } else {
                            // Create new row.
                            await controller.submit();

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Action Step saved!'),
                              ),
                            );

                            if (context.mounted) {
                              context.go(kLaunchRoute);
                            }
                          }
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to save: $e')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isSubmitting = false);
                          }
                        }
                      }
                      : null,
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(_isEditing ? 'Save' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
