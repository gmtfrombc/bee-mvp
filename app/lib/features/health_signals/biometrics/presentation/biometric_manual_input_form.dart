import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/ui/widgets/widgets.dart';
import '../biometrics_form_provider.dart';
import 'package:app/core/services/responsive_service.dart';
import 'package:app/core/health_data/validators/biometric_validators.dart';

/// Form that captures user weight & height with inline unit toggles.
///
/// Task T1 implementation: basic layout & state wiring – validation and
/// repository submission will be expanded in subsequent tasks.
class BiometricManualInputForm extends ConsumerWidget {
  const BiometricManualInputForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(biometricsFormProvider);
    final notifier = ref.read(biometricsFormProvider.notifier);

    final verticalSpacing = ResponsiveService.getMediumSpacing(context);

    return Padding(
      padding: ResponsiveService.getMediumPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Weight field ----------------------------------------------------
          HealthInputField(
            label: 'Weight',
            value: formState.weight,
            onChanged: notifier.updateWeight,
            units: const ['kg', 'lbs'],
            selectedUnit: formState.weightUnit.name,
            onUnitChanged:
                (u) => notifier.updateWeightUnit(
                  u == 'kg' ? WeightUnit.kg : WeightUnit.lbs,
                ),
            hint: 'e.g. 70',
            validator:
                (v) => BiometricValidators.weight(
                  v,
                  unit: formState.weightUnit.name,
                ),
          ),
          SizedBox(height: verticalSpacing),

          // Height field ----------------------------------------------------
          HealthInputField(
            label: 'Height',
            value: formState.height,
            onChanged: notifier.updateHeight,
            units: const ['cm', 'ft'],
            selectedUnit: formState.heightUnit.name,
            onUnitChanged:
                (u) => notifier.updateHeightUnit(
                  u == 'cm' ? HeightUnit.cm : HeightUnit.ftIn,
                ),
            hint: 'e.g. 175',
            validator:
                (v) => BiometricValidators.height(
                  v,
                  unit: formState.heightUnit.name,
                ),
          ),
          SizedBox(height: verticalSpacing * 1.5),

          // Submit button ---------------------------------------------------
          BeePrimaryButton(
            label: 'Save',
            isLoading: formState.isSubmitting,
            onPressed:
                formState.isValid && !formState.isSubmitting
                    ? () async {
                      await notifier.submit();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biometrics saved')),
                        );
                      }
                    }
                    : null,
          ),
        ],
      ),
    );
  }
}
