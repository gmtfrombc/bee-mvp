import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/responsive_service.dart';

/// Card component for coaching suggestions and actions
/// Features momentum accent bar and tap interaction
class CoachingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final MomentumState? momentumState;

  const CoachingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.momentumState,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getMediumSpacing(context);
    final accentColor =
        momentumState != null
            ? AppTheme.getMomentumColor(momentumState!)
            : AppTheme.getMomentumColor(MomentumState.steady);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: ResponsiveService.getSmallSpacing(context),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(top: BorderSide(color: accentColor, width: 3)),
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: EdgeInsets.all(
                      ResponsiveService.getSmallSpacing(context),
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  SizedBox(width: spacing),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: ResponsiveService.getTinySpacing(context),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getTextSecondary(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.getTextTertiary(context),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact version of coaching card for smaller spaces
class CompactCoachingCard extends StatelessWidget {
  final String title;
  final String emoji;
  final VoidCallback onTap;
  final MomentumState? momentumState;

  const CompactCoachingCard({
    super.key,
    required this.title,
    required this.emoji,
    required this.onTap,
    this.momentumState,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getSmallSpacing(context);
    final accentColor =
        momentumState != null
            ? AppTheme.getMomentumColor(momentumState!)
            : AppTheme.getMomentumColor(MomentumState.steady);

    return Card(
      margin: EdgeInsets.all(ResponsiveService.getTinySpacing(context)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(spacing),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: accentColor, width: 3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              SizedBox(width: spacing),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
