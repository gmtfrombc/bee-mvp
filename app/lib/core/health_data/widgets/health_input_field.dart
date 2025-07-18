import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/ui/widgets/bee_text_field.dart';
import 'package:app/core/services/responsive_service.dart';

/// A numeric input field specialised for health metrics (weight, height, etc.)
/// that offers an inline unit toggle (e.g. kg ↔ lbs).
///
/// This widget wraps [BeeTextField] to adhere to Bee Design guidelines and
/// guarantees that only numeric values can be typed.
class HealthInputField extends ConsumerWidget {
  const HealthInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.units,
    required this.selectedUnit,
    required this.onUnitChanged,
    this.hint,
  });

  /// Label displayed before the unit toggle.
  final String label;

  /// Current string value inside the text field.
  final String value;

  /// Callback when the text changes.
  final ValueChanged<String> onChanged;

  /// Allowed unit strings (e.g. ["kg", "lbs"].
  final List<String> units;

  /// Currently selected unit.
  final String selectedUnit;

  /// Callback when the unit toggle changes.
  final ValueChanged<String?> onUnitChanged;

  /// Optional placeholder.
  final String? hint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ResponsiveService.getTinySpacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            SizedBox(width: spacing),
            DropdownButton<String>(
              value: selectedUnit,
              items:
                  units
                      .map(
                        (u) =>
                            DropdownMenuItem<String>(value: u, child: Text(u)),
                      )
                      .toList(),
              onChanged: onUnitChanged,
              underline: const SizedBox.shrink(),
            ),
          ],
        ),
        SizedBox(height: spacing),
        BeeTextField(
          label: '', // Empty label – handled above.
          initialValue: value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
          ],
          hint: hint,
        ),
      ],
    );
  }
}
