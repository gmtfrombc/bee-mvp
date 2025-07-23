import 'package:flutter/material.dart';

/// A simple wrapper that disables back navigation (system or app-bar) so users
/// can’t accidentally leave a multi-step flow. Used by onboarding pages.
class CanPopScope extends StatelessWidget {
  /// Wraps a subtree in a [PopScope] to control whether the user can navigate
  /// back (using the system gesture or the AppBar back button).
  ///
  /// [canPop] defaults to `true`, enabling back navigation. Pass `false` for
  /// screens where exiting the flow must be prevented.
  const CanPopScope({super.key, required this.child, this.canPop = true});

  final Widget child;

  /// Whether this subtree should allow the user to pop the current route.
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: canPop, child: child);
  }
}
