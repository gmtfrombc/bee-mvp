import 'package:flutter/material.dart';
import '../services/responsive_service.dart';

/// Types of Bee Toasts that map to common message intents.
enum BeeToastType { success, error, info }

/// Shows a styled SnackBar (Toast) using Bee design system colours.
///
/// Usage:
/// ```dart
/// showBeeToast(context, 'Profile saved', type: BeeToastType.success);
/// ```
void showBeeToast(
  BuildContext context,
  String message, {
  BeeToastType type = BeeToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final background = switch (type) {
    BeeToastType.success => colorScheme.primary.withAlpha((0.9 * 255).round()),
    BeeToastType.error => colorScheme.error.withAlpha((0.9 * 255).round()),
    BeeToastType.info => colorScheme.surfaceContainerHighest.withAlpha(
      (0.9 * 255).round(),
    ),
  };

  final textColor = colorScheme.onPrimary;

  final snackBar = SnackBar(
    content: Text(message, style: TextStyle(color: textColor)),
    backgroundColor: background,
    duration: duration,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.fromLTRB(
      ResponsiveService.getSmallSpacing(context),
      ResponsiveService.getSmallSpacing(context),
      ResponsiveService.getSmallSpacing(context),
      ResponsiveService.getSmallSpacing(context),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
