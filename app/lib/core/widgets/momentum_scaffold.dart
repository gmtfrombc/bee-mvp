import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standardized scaffold wrapper for BEE app
/// Provides consistent background color, app bar styling, and layout structure
class MomentumScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;

  const MomentumScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.centerTitle = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getSurfaceSecondary(context),
      appBar: MomentumAppBar(
        title: title,
        actions: actions,
        centerTitle: centerTitle,
        leading: leading,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Standardized app bar for BEE app
class MomentumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;

  const MomentumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      centerTitle: centerTitle,
      leading: leading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
