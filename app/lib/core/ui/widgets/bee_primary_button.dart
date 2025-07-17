import 'package:flutter/material.dart';
import '../../services/responsive_service.dart';

/// A primary action button that follows Bee Design guidelines.
///
/// Features:
/// • Primary colour background from the active Theme.
/// • Optional loading state that disables the button and shows a spinner.
/// • Optional leading icon.
/// • Consistent paddings and rounded corners.
class BeePrimaryButton extends StatelessWidget {
  const BeePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.minWidth,
  });

  /// Text label for the button.
  final String label;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether to show a loading spinner instead of the label.
  final bool isLoading;

  /// Optional leading icon.
  final Widget? icon;

  /// Minimum width for the button (useful for wide layouts).
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final spinnerSize = ResponsiveService.getSmallSpacing(context) * 2;

    final child =
        isLoading
            ? SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
            : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon!,
                  SizedBox(width: ResponsiveService.getTinySpacing(context)),
                ],
                Text(label),
              ],
            );

    return SizedBox(
      width: minWidth,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveService.getSmallSpacing(context),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: child,
      ),
    );
  }
}
