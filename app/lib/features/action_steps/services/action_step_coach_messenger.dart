import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/l10n/s.dart';

/// Provides empathetic, localized coach feedback after an Action Step
/// check-in. The messenger currently displays a `SnackBar` but could be
/// extended to other UI surfaces (dialogs, toasts, etc.).
class ActionStepCoachMessenger {
  const ActionStepCoachMessenger();

  /// Shows the success coach message (called after the user marks today
  /// completed).
  void sendSuccessMessage(BuildContext context) {
    _showCoachSnackBar(context, S.of(context).actionStepSuccessCoachMessage);
  }

  /// Shows the failure/encouragement coach message (called after the user
  /// skips today).
  void sendFailureMessage(BuildContext context) {
    _showCoachSnackBar(context, S.of(context).actionStepFailureCoachMessage);
  }

  void _showCoachSnackBar(BuildContext context, String message) {
    // Remove any existing coach snackbars to avoid stacking.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}

/// Riverpod provider so widgets can access a shared messenger instance.
final actionStepCoachMessengerProvider = Provider<ActionStepCoachMessenger>(
  (ref) => const ActionStepCoachMessenger(),
);
