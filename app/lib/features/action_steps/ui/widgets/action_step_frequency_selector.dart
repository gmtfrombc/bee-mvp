import 'package:flutter/material.dart';
import 'package:app/core/services/responsive_service.dart';

/// Horizontal chip selector for picking target days per week (3–7).
class ActionStepFrequencySelector extends StatelessWidget {
  const ActionStepFrequencySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getSmallSpacing(context);

    return Wrap(
      spacing: spacing,
      children: List.generate(5, (index) {
        final value = index + 3; // 3,4,5,6,7
        final bool isSelected = value == selected;

        return ChoiceChip(
          label: Text('$value d/wk'),
          selected: isSelected,
          onSelected: (_) => onChanged(value),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }),
    );
  }
}
