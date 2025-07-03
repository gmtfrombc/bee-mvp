import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';

/// Disabled placeholder switch for upcoming Multi-factor Authentication feature.
class MfaToggleTile extends StatelessWidget {
  const MfaToggleTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Multi-factor Authentication',
      hint: 'Toggle MFA (coming soon)',
      child: SwitchListTile(
        title: Text(
          'Multi-factor Authentication',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        subtitle: Text(
          'Enhance account security with MFA – coming soon',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        value: false,
        onChanged: null, // Disabled
        activeColor: AppTheme.momentumRising,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
