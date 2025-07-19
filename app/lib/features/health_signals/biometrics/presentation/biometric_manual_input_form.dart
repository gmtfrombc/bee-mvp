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
          SizedBox(height: verticalSpacing),

          // BMI display -----------------------------------------------------
          if (formState.bmi != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'BMI: ${formState.bmi!.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          SizedBox(height: verticalSpacing * 1.5),

          // A1C toggle -------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Enter A1C instead of fasting glucose',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Switch(value: formState.useA1c, onChanged: notifier.toggleUseA1c),
            ],
          ),
          SizedBox(height: verticalSpacing),

          // Conditional field ----------------------------------------------
          if (!formState.useA1c) ...[
            HealthInputField(
              label: 'Fasting Glucose',
              value: formState.fastingGlucose,
              onChanged: notifier.updateFastingGlucose,
              units: const ['mg/dL'],
              selectedUnit: 'mg/dL',
              onUnitChanged: (_) {},
              hint: 'e.g. 90',
              validator: BiometricValidators.fastingGlucose,
            ),
          ] else ...[
            HealthInputField(
              label: 'A1C',
              value: formState.a1c,
              onChanged: notifier.updateA1c,
              units: const ['%'],
              selectedUnit: '%',
              onUnitChanged: (_) {},
              hint: 'e.g. 5.4',
              validator: BiometricValidators.a1c,
            ),
          ],
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
