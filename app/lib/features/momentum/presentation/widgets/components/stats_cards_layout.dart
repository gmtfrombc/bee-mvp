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
  final Widget Function(IndividualStatCard card) cardWrapper;

  const StatsCardsLayout({
    super.key,
    required this.stats,
    required this.cardWrapper,
    this.onLessonsTap,
    this.onStreakTap,
    this.onTodayTap,
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
        Expanded(child: cardWrapper(_buildLessonsCard())),
        SizedBox(width: spacing),
        Expanded(child: cardWrapper(_buildStreakCard())),
        SizedBox(width: spacing),
        Expanded(child: cardWrapper(_buildTodayCard())),
      ],
    );
  }

  Widget _buildCompactLayout(double spacing) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cardWrapper(_buildLessonsCard())),
            SizedBox(width: spacing),
            Expanded(child: cardWrapper(_buildStreakCard())),
          ],
        ),
        SizedBox(height: spacing),
        SizedBox(width: double.infinity, child: cardWrapper(_buildTodayCard())),
      ],
    );
  }

  IndividualStatCard _buildLessonsCard() {
    return IndividualStatCard(
      icon: Icons.menu_book_rounded,
      value: stats.lessonsRatio,
      label: 'Lessons',
      color: AppTheme.momentumRising,
      onTap: onLessonsTap,
    );
  }

  IndividualStatCard _buildStreakCard() {
    return IndividualStatCard(
      icon: Icons.local_fire_department_rounded,
      value: stats.streakText,
      label: 'Streak',
      color: AppTheme.momentumCare,
      onTap: onStreakTap,
    );
  }

  IndividualStatCard _buildTodayCard() {
    return IndividualStatCard(
      icon: Icons.schedule_rounded,
      value: stats.todayText,
      label: 'Today',
      color: AppTheme.momentumSteady,
      onTap: onTodayTap,
    );
  }
}
