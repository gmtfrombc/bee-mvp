import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/responsive_service.dart';

/// A reusable widget for capturing user responses on a 1-5 Likert scale.
///
/// Features:
/// - Full keyboard navigation with arrow keys and space/enter
/// - Screen reader support with proper semantics
/// - WCAG 2.2 compliance with radiogroup pattern
/// - Responsive design using app's responsive service
/// - Animated selection feedback
/// - Customizable question prompt and value change callback
///
/// Example usage:
/// ```dart
/// LikertSelector(
///   value: selectedValue,
///   onChanged: (value) => setState(() => selectedValue = value),
///   semanticLabel: S.of(context).onboarding_q11_prompt,
/// )
/// ```
class LikertSelector extends StatefulWidget {
  /// Current selected value (1-5), null if no selection
  final int? value;

  /// Callback when user selects a value
  final ValueChanged<int>? onChanged;

  /// Accessible label for screen readers (should be the question prompt)
  final String semanticLabel;

  /// Whether the selector is enabled
  final bool enabled;

  /// Custom labels for each option (defaults to "1", "2", "3", "4", "5")
  final List<String>? optionLabels;

  const LikertSelector({
    super.key,
    this.value,
    this.onChanged,
    required this.semanticLabel,
    this.enabled = true,
    this.optionLabels,
  });

  @override
  State<LikertSelector> createState() => _LikertSelectorState();
}

class _LikertSelectorState extends State<LikertSelector> {
  /// Currently focused option index (0-4)
  int _focusedIndex = 0;

  /// Focus node for the entire group
  final FocusNode _groupFocusNode = FocusNode();

  /// Track whether we have keyboard focus
  bool _hasKeyboardFocus = false;

  @override
  void initState() {
    super.initState();
    _groupFocusNode.addListener(_onFocusChange);

    // Set initial focus to selected value if any
    if (widget.value != null) {
      _focusedIndex = widget.value! - 1;
    }
  }

  @override
  void dispose() {
    _groupFocusNode.removeListener(_onFocusChange);
    _groupFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasKeyboardFocus = _groupFocusNode.hasFocus;
    });
  }

  /// Handle keyboard navigation
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          _moveFocus(-1);
          break;
        case LogicalKeyboardKey.arrowRight:
          _moveFocus(1);
          break;
        case LogicalKeyboardKey.space:
        case LogicalKeyboardKey.enter:
          _selectCurrentOption();
          break;
        case LogicalKeyboardKey.escape:
          _groupFocusNode.unfocus();
          break;
      }
    }
  }

  /// Move focus to adjacent option
  void _moveFocus(int direction) {
    setState(() {
      _focusedIndex = (_focusedIndex + direction).clamp(0, 4);
    });
  }

  /// Select the currently focused option
  void _selectCurrentOption() {
    if (widget.enabled && widget.onChanged != null) {
      widget.onChanged!(_focusedIndex + 1);
    }
  }

  /// Handle tap selection
  void _handleTap(int index) {
    if (!widget.enabled || widget.onChanged == null) return;

    setState(() {
      _focusedIndex = index;
    });

    // Simulate radio-choice latency < 50ms requirement
    widget.onChanged!(index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ResponsiveService.getSmallSpacing(context);

    return Semantics(
      label: widget.semanticLabel,
      hint:
          'Select a value from 1 to 5. Use arrow keys to navigate, space to select.',
      child: Focus(
        focusNode: _groupFocusNode,
        onKeyEvent: (node, event) {
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveService.getSmallSpacing(context),
          ),
          decoration:
              _hasKeyboardFocus
                  ? BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  )
                  : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final value = index + 1;
              final isSelected = widget.value == value;
              final isFocused = _hasKeyboardFocus && _focusedIndex == index;
              final label = widget.optionLabels?[index] ?? value.toString();

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing * 0.5),
                  child: _LikertOption(
                    value: value,
                    label: label,
                    isSelected: isSelected,
                    isFocused: isFocused,
                    enabled: widget.enabled,
                    onTap: () => _handleTap(index),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Individual option chip in the Likert selector
class _LikertOption extends StatelessWidget {
  final int value;
  final String label;
  final bool isSelected;
  final bool isFocused;
  final bool enabled;
  final VoidCallback? onTap;

  const _LikertOption({
    required this.value,
    required this.label,
    required this.isSelected,
    required this.isFocused,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use surfaceVariant for neutral backgrounds as specified
    final backgroundColor =
        isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest;

    final textColor =
        isSelected ? colorScheme.onPrimary : colorScheme.onSurface;

    return Semantics(
      label: 'Rating $value of 5',
      value: isSelected ? 'Selected' : 'Not selected',
      button: true,
      selected: isSelected,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          key: ValueKey('option_$value'),
          onTap: enabled ? onTap : null,
          child: Container(
            height: ResponsiveService.getIconSize(context, baseSize: 48),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFocused ? colorScheme.primary : backgroundColor,
                width: 2,
              ),
              boxShadow:
                  isFocused
                      ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
