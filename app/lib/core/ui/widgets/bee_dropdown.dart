import 'package:flutter/material.dart';
import '../../services/responsive_service.dart';

/// A reusable dropdown form field that follows Bee Design guidelines.
///
/// It mimics the layout of [BeeTextField] – a label followed by an input
/// control – and applies consistent paddings, rounded borders, and theming.
class BeeDropdown<T> extends StatelessWidget {
  const BeeDropdown({
    super.key,
    required this.label,
    required this.items,
    this.value,
    required this.onChanged,
    this.hint,
    this.validator,
    this.enabled = true,
  });

  /// Label displayed above the field.
  final String label;

  /// Dropdown menu items to display.
  final List<DropdownMenuItem<T>> items;

  /// Currently selected value.
  final T? value;

  /// Callback when selection changes. Set to `null` to make the field read-only.
  final ValueChanged<T?>? onChanged;

  /// Optional hint text shown when no value is selected.
  final String? hint;

  /// Optional form validator returning `null` when valid.
  final String? Function(T?)? validator;

  /// Whether the dropdown is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyLarge;
    final inputPadding = EdgeInsets.symmetric(
      horizontal: ResponsiveService.getSmallSpacing(context),
      vertical: ResponsiveService.getTinySpacing(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        SizedBox(height: ResponsiveService.getTinySpacing(context)),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: inputPadding,
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
