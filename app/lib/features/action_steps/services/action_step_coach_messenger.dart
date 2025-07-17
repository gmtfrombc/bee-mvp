import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/l10n/s.dart';

/// Provides empathetic, localized coach feedback after an Action Step
/// check-in. The messenger currently displays a `SnackBar` but can be
/// extended to other UI surfaces (dialogs, toasts, etc.).
class ActionStepCoachMessenger {
  const ActionStepCoachMessenger();

  /// Shows the success coach message (called after the user marks today
  /// completed).
  void sendSuccessMessage(BuildContext context) {
    final message =
        Localizations.of<S>(context, S)?.actionStepSuccessCoachMessage ??
        'Great job! You completed your Action Step—keep building momentum!';
    _showCoachSnackBar(context, message);
  }

  /// Shows the failure/encouragement coach message (called after the user
  /// skips today).
  void sendFailureMessage(BuildContext context) {
    final message =
        Localizations.of<S>(context, S)?.actionStepFailureCoachMessage ??
        "Don't worry, tomorrow is a new opportunity. You've got this!";
    _showCoachSnackBar(context, message);
  }

  void _showCoachSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return; // In tests without Scaffold.
    if (Scaffold.maybeOf(context) == null) {
      // No Scaffold in context tree, skip showing.
      return;
    }

    messenger
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
