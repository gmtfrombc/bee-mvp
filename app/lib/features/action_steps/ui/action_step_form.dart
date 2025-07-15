import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/responsive_service.dart';
import '../state/action_step_controller.dart';
import 'widgets/action_step_frequency_selector.dart';

/// Form capturing Action Step details (category, description, frequency).
class ActionStepForm extends ConsumerStatefulWidget {
  const ActionStepForm({super.key});

  @override
  ConsumerState<ActionStepForm> createState() => _ActionStepFormState();
}

class _ActionStepFormState extends ConsumerState<ActionStepForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();

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
              validator:
                  (val) =>
                      (val == null || val.trim().isEmpty) ? 'Required' : null,
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
                  controller.isComplete
                      ? () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        // For now just show confirmation.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Action Step saved (local)!'),
                          ),
                        );
                        Navigator.of(context).maybePop();
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
