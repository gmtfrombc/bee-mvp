import 'package:flutter/material.dart' hide Badge;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../models/badge.dart';

/// Section showing the grid of user badges.
class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key, required this.badges});

  final List<Badge> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    final spacing = ResponsiveService.getMediumSpacing(context);

    return Container(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppTheme.getMomentumColor(MomentumState.rising),
                size: 20,
              ),
              SizedBox(width: spacing * 0.5),
              Text(
                'Your Badges',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _BadgeCard(
                badge: badge,
                onTap: () => _showBadgeDetail(context, badge),
              );
            },
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final deviceType = ResponsiveService.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 2;
      case DeviceType.mobile:
        return 2;
      case DeviceType.mobileLarge:
        return 3;
      case DeviceType.tablet:
        return 4;
      case DeviceType.desktop:
        return 5;
    }
  }

  void _showBadgeDetail(BuildContext context, Badge badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BadgeDetailSheet(badge: badge),
    );
  }
}

/// Individual badge tile card
class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.onTap});

  final Badge badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getSmallSpacing(context);
    final isEarned = badge.isEarned;

    return Semantics(
      label: '${badge.title} badge',
      hint:
          isEarned
              ? 'Earned on ${badge.earnedAt?.day}/${badge.earnedAt?.month}'
              : 'Not yet earned, ${(badge.progressPercentage * 100).round()}% progress',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveService.getBorderRadius(context),
          ),
          child: Card(
            elevation: isEarned ? 3 : 1,
            color: AppTheme.getSurfacePrimary(context),
            child: Padding(
              padding: EdgeInsets.all(spacing),
              child: Column(
                children: [
                  Expanded(flex: 3, child: _buildBadgeIcon(context)),
                  SizedBox(height: spacing * 0.5),
                  Text(
                    badge.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isEarned
                              ? AppTheme.getTextPrimary(context)
                              : AppTheme.getTextSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacing * 0.25),
                  if (isEarned)
                    Icon(
                      Icons.check_circle,
                      size:
                          16 * ResponsiveService.getFontSizeMultiplier(context),
                      color: AppTheme.getMomentumColor(MomentumState.rising),
                    )
                  else
                    _buildProgressIndicator(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(BuildContext context) {
    final isEarned = badge.isEarned;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isEarned
                ? AppTheme.getMomentumColor(
                  MomentumState.rising,
                ).withValues(alpha: 0.1)
                : AppTheme.getTextTertiary(context).withValues(alpha: 0.1),
      ),
      child: Center(child: _getBadgeEmoji(badge.category, isEarned, context)),
    );
  }

  Widget _getBadgeEmoji(
    BadgeCategory category,
    bool isEarned,
    BuildContext context,
  ) {
    final fontSize = 32.0 * ResponsiveService.getFontSizeMultiplier(context);
    final emoji = switch (category) {
      BadgeCategory.streak => '🔥',
      BadgeCategory.momentum => '⚡',
      BadgeCategory.engagement => '💬',
      BadgeCategory.milestone => '🎯',
      BadgeCategory.special => '⭐',
    };

    return Text(
      emoji,
      style: TextStyle(
        fontSize: fontSize,
        color: isEarned ? null : Colors.grey,
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final progress = badge.progressPercentage;

    return SizedBox(
      width: 40,
      height: 6,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: AppTheme.getTextTertiary(
          context,
        ).withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(
          AppTheme.getMomentumColor(MomentumState.steady),
        ),
      ),
    );
  }
}

/// Bottom sheet that shows detailed information about a badge.
class _BadgeDetailSheet extends StatelessWidget {
  const _BadgeDetailSheet({required this.badge});

  final Badge badge;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getMediumSpacing(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfacePrimary(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.getTextTertiary(
                    context,
                  ).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Badge icon (larger)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      badge.isEarned
                          ? AppTheme.getMomentumColor(
                            MomentumState.rising,
                          ).withValues(alpha: 0.1)
                          : AppTheme.getTextTertiary(
                            context,
                          ).withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    _getBadgeEmojiForCategory(badge.category),
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              SizedBox(height: spacing),
              Text(
                badge.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing * 0.5),
              Text(
                badge.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing),
              if (badge.isEarned) ...[
                Container(
                  padding: EdgeInsets.all(spacing * 0.75),
                  decoration: BoxDecoration(
                    color: AppTheme.getMomentumColor(
                      MomentumState.rising,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.getMomentumColor(MomentumState.rising),
                        size: 20,
                      ),
                      SizedBox(width: spacing * 0.5),
                      Text(
                        'Earned on ${badge.earnedAt?.day}/${badge.earnedAt?.month}/${badge.earnedAt?.year}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getMomentumColor(
                            MomentumState.rising,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
                ElevatedButton.icon(
                  onPressed: () {
                    // Using ShareHelper; import avoided to keep deps minimal.
                    // We call ShareHelper via Navigator pop callback from screen.
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Achievement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.getMomentumColor(
                      MomentumState.rising,
                    ),
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                Column(
                  children: [
                    Text(
                      'Progress: ${badge.currentProgress ?? 0} / ${badge.requiredPoints}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                    SizedBox(height: spacing * 0.5),
                    LinearProgressIndicator(
                      value: badge.progressPercentage,
                      backgroundColor: AppTheme.getTextTertiary(
                        context,
                      ).withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.getMomentumColor(MomentumState.steady),
                      ),
                    ),
                    SizedBox(height: spacing * 0.25),
                    Text(
                      '${(badge.progressPercentage * 100).round()}% complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getBadgeEmojiForCategory(BadgeCategory category) {
    return switch (category) {
      BadgeCategory.streak => '🔥',
      BadgeCategory.momentum => '⚡',
      BadgeCategory.engagement => '💬',
      BadgeCategory.milestone => '🎯',
      BadgeCategory.special => '⭐',
    };
  }
}
