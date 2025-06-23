import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../domain/models/momentum_data.dart';
import 'individual_stat_card.dart';

/// Layout handler for stats cards supporting standard and compact layouts
/// Responsive design with proper spacing and accessibility
class StatsCardsLayout extends StatelessWidget {
  final MomentumStats stats;
  final VoidCallback? onLessonsTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onTodayTap;
  final VoidCallback? onAchievementsTap;
  final Widget Function(IndividualStatCard card) cardWrapper;

  const StatsCardsLayout({
    super.key,
    required this.stats,
    required this.cardWrapper,
    this.onLessonsTap,
    this.onStreakTap,
    this.onTodayTap,
    this.onAchievementsTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveService.getResponsiveSpacing(context) * 0.4;
    final shouldUseCompactLayout = ResponsiveService.shouldUseCompactLayout(
      context,
    );

    return shouldUseCompactLayout
        ? _buildCompactLayout(spacing)
        : _buildStandardLayout(spacing);
  }

  Widget _buildStandardLayout(double spacing) {
    return Row(
      children: [
        Expanded(child: cardWrapper(_buildReadinessCard())),
        SizedBox(width: spacing),
        Expanded(child: cardWrapper(_buildActionStepCard())),
      ],
    );
  }

  Widget _buildCompactLayout(double spacing) {
    return Row(
      children: [
        Expanded(child: cardWrapper(_buildReadinessCard())),
        SizedBox(width: spacing),
        Expanded(child: cardWrapper(_buildActionStepCard())),
      ],
    );
  }

  IndividualStatCard _buildReadinessCard() {
    return IndividualStatCard(
      icon: Icons.self_improvement_rounded,
      value: '--', // Placeholder until DNS logic is wired
      label: 'Readiness',
      color: AppTheme.momentumSteady,
      onTap: onLessonsTap, // Reuse callback slot for future DNS survey
    );
  }

  IndividualStatCard _buildActionStepCard() {
    return IndividualStatCard(
      icon: Icons.flag_circle_rounded,
      value: '--', // Placeholder until Action Step logic is wired
      label: 'Action Step',
      color: AppTheme.momentumRising,
      onTap: onStreakTap, // Reuse callback slot for future Action Step details
    );
  }
}
