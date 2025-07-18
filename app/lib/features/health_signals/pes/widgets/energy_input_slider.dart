import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/responsive_service.dart';

import '../pes_providers.dart';

/// A horizontal selection control that lets users choose how energized they
/// feel today using 1–5 emoji faces.
///
/// Emits the selected score via [onScoreSelected] and updates
/// [energyScoreProvider].
class EnergyInputSlider extends ConsumerWidget {
  const EnergyInputSlider({super.key, this.onScoreSelected});

  /// Callback invoked when the user selects a score.
  final ValueChanged<int>? onScoreSelected;

  // Emoji faces for energy levels 1-5 (tired → energised).
  static const _emojiMap = <int, String>{
    1: '😫', // exhausted
    2: '😕', // low
    3: '😐', // neutral
    4: '🙂', // good
    5: '😄', // great
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(energyScoreProvider);

    // Responsive spacing between emoji.
    final spacing = ResponsiveService.getSmallSpacing(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          _emojiMap.entries.map((entry) {
            final score = entry.key;
            final emoji = entry.value;
            final bool isSelected = selected == score;

            return GestureDetector(
              onTap: () {
                ref.read(energyScoreProvider.notifier).state = score;
                onScoreSelected?.call(score);
              },
              child: Semantics(
                label: 'Energy level $score of 5',
                selected: isSelected,
                button: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.all(spacing),
                  decoration: BoxDecoration(
                    // Highlight selected emoji with subtle background using surface variant.
                    color:
                        isSelected
                            ? Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest
                            : Colors.transparent,
                    border: Border.all(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize:
                          28 * ResponsiveService.getFontSizeMultiplier(context),
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
