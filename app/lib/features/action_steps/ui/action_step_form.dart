import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/responsive_service.dart';
import '../state/action_step_controller.dart';
import 'widgets/action_step_frequency_selector.dart';
import '../validators/action_step_validators.dart';

/// Form capturing Action Step details (category, description, frequency).
class ActionStepForm extends ConsumerStatefulWidget {
  const ActionStepForm({super.key});

  @override
  ConsumerState<ActionStepForm> createState() => _ActionStepFormState();
}

class _ActionStepFormState extends ConsumerState<ActionStepForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();

  bool _isSubmitting = false;

  static const _categories = <String>[
    'exercise',
    'nutrition',
    'sleep',
    'stress',
    'mindfulness',
  ];

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
                      ? () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        setState(() => _isSubmitting = true);
                        controller
                            .submit()
                            .then((_) {
                              navigator.maybePop();
                            })
                            .catchError((e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed to save: $e')),
                              );
                            })
                            .whenComplete(() {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                              }
                            });
                      }
                      : null,
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
