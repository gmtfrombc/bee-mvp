import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/routes.dart';

import '../../../core/services/responsive_service.dart';
import '../onboarding_controller.dart';
import 'preferences_page.dart';
import '../../../core/mixins/input_validator.dart';

/// First onboarding page collecting basic demographic information.
class AboutYouPage extends ConsumerStatefulWidget {
  const AboutYouPage({super.key});

  @override
  ConsumerState<AboutYouPage> createState() => _AboutYouPageState();
}

class _AboutYouPageState extends ConsumerState<AboutYouPage> {
  final _formKey = GlobalKey<FormState>();
  final _dobTextController = TextEditingController();

  @override
  void dispose() {
    _dobTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getLargeSpacing(context);

    // Watch state & notifier separately so the UI updates reactively but we can
    // still call mutation methods.
    final controller = ref.watch(onboardingControllerProvider.notifier);
    final draft = ref.watch(onboardingControllerProvider);

    // Ensure DOB text stays in sync with state when Riverpod rebuilds.
    if (draft.dateOfBirth != null) {
      _dobTextController.text = DateFormat.yMd().format(draft.dateOfBirth!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tell us about you')),
      body: SingleChildScrollView(
        padding: ResponsiveService.getMediumPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date of Birth -------------------------------------------------
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _selectDob(context, controller.updateDateOfBirth),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dobTextController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      hintText: 'Select your birth date',
                    ),
                    validator: (_) => _dobValidator(draft.dateOfBirth),
                    readOnly: true,
                  ),
                ),
              ),
              SizedBox(height: spacing),

              // Gender -------------------------------------------------------
              DropdownButtonFormField<String>(
                value: draft.gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(
                    value: 'non_binary',
                    child: Text('Non-binary'),
                  ),
                  DropdownMenuItem(
                    value: 'prefer_not_to_say',
                    child: Text('Prefer not to say'),
                  ),
                ],
                onChanged: controller.updateGender,
                validator:
                    (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: spacing),

              // Culture ------------------------------------------------------
              TextFormField(
                initialValue: draft.culture,
                decoration: const InputDecoration(
                  labelText: 'Culture',
                  hintText: 'e.g. Colombian-American',
                ),
                maxLength: 64,
                onChanged: controller.updateCulture,
              ),
              SizedBox(height: spacing * 2),

              // Continue button ---------------------------------------------
              ElevatedButton(
                key: const ValueKey('continue_button'),
                onPressed:
                    controller.isStep1Complete
                        ? () {
                          if (_formKey.currentState?.validate() ?? false) {
                            context.push(kOnboardingStep2Route);
                          }
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

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Future<void> _selectDob(
    BuildContext context,
    ValueChanged<DateTime?> onSave,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year - 13),
    );
    if (picked != null) {
      onSave(picked);
    }
  }

  String? _dobValidator(DateTime? dob) {
    return InputValidatorUtils.dateOfBirth(dob);
  }
}
