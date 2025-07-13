import 'package:flutter/material.dart';

/// A simple wrapper that disables back navigation (system or app-bar) so users
/// can’t accidentally leave a multi-step flow. Used by onboarding pages.
class CanPopScope extends StatelessWidget {
  const CanPopScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, child: child);
  }
}
