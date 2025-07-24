import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../domain/models/momentum_data.dart';
import '../../../../action_steps/data/action_step_repository.dart';
import 'individual_stat_card.dart';

/// Layout handler for stats cards supporting standard and compact layouts
/// Responsive design with proper spacing and accessibility
class StatsCardsLayout extends StatelessWidget {
  final MomentumStats stats;
  final VoidCallback? onLessonsTap;
  final VoidCallback? onActionStepTap;
  final VoidCallback? onTodayTap;
  final VoidCallback? onAchievementsTap;
  final Widget Function(IndividualStatCard card) cardWrapper;

  const StatsCardsLayout({
    super.key,
    required this.stats,
    required this.cardWrapper,
    this.onLessonsTap,
    this.onActionStepTap,
    this.onTodayTap,
    this.onAchievementsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final actionStepAsync = ref.watch(currentActionStepProvider);
        final progress = actionStepAsync.maybeWhen(
          data:
              (current) =>
                  current == null
                      ? '--'
                      : '${current.completed}/${current.target}',
          orElse: () => '--',
        );

        final spacing = ResponsiveService.getResponsiveSpacing(context) * 0.4;
        final shouldUseCompactLayout = ResponsiveService.shouldUseCompactLayout(
          context,
        );

        return shouldUseCompactLayout
            ? _buildCompactLayout(spacing, progress)
            : _buildStandardLayout(spacing, progress);
      },
    );
  }

  Widget _buildStandardLayout(double spacing, String progress) {
    return Row(
      children: [
        Expanded(child: cardWrapper(_buildReadinessCard())),
        SizedBox(width: spacing),
        Expanded(child: cardWrapper(_buildActionStepCard(progress))),
      ],
    );
  }

  Widget _buildCompactLayout(double spacing, String progress) {
    return Row(
      children: [
        Expanded(child: cardWrapper(_buildReadinessCard())),
        SizedBox(width: spacing),
        Expanded(child: cardWrapper(_buildActionStepCard(progress))),
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

  IndividualStatCard _buildActionStepCard(String progress) {
    return IndividualStatCard(
      icon: Icons.flag_circle_rounded,
      value: progress,
      label: 'Action Step',
      color: AppTheme.momentumRising,
      onTap: onActionStepTap, // Open Action Step feature
    );
  }
}
