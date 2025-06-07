import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/responsive_service.dart';
import '../providers/gamification_providers.dart';
import '../models/badge.dart';
import '../services/share_helper.dart';

/// Progress dashboard showing weekly points chart and badge timeline
class ProgressDashboard extends ConsumerWidget {
  const ProgressDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressDataAsync = ref.watch(progressProvider);
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: AppTheme.getSurfaceSecondary(context),
      appBar: AppBar(
        title: const Text('Progress Dashboard'),
        backgroundColor: AppTheme.getSurfacePrimary(context),
        foregroundColor: AppTheme.getTextPrimary(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProgress(context, ref),
            tooltip: 'Share Progress',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Weekly points chart
              _buildWeeklyPointsChart(context, progressDataAsync),

              const SizedBox(height: 24),

              // Badge timeline
              _buildBadgeTimeline(context, achievementsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyPointsChart(
    BuildContext context,
    AsyncValue<List<ProgressData>> progressDataAsync,
  ) {
    final spacing = ResponsiveService.getMediumSpacing(context);

    return Container(
      margin: EdgeInsets.all(spacing),
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: AppTheme.getSurfacePrimary(context),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),

          const SizedBox(height: 8),

          progressDataAsync.when(
            loading:
                () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (error, stack) => const SizedBox(
                  height: 200,
                  child: Center(child: Text('Error loading chart data')),
                ),
            data: (progressData) => _buildChart(context, progressData),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<ProgressData> progressData) {
    if (progressData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final maxY =
        progressData
            .map((e) => e.points)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.getTextTertiary(context).withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < progressData.length) {
                    final date = progressData[index].date;
                    return Text(
                      '${date.day}/${date.month}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.getTextSecondary(context),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (progressData.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots:
                  progressData.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.points.toDouble(),
                    );
                  }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.getMomentumColor(MomentumState.rising),
                  AppTheme.getMomentumColor(MomentumState.steady),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.getMomentumColor(MomentumState.rising),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.getMomentumColor(
                      MomentumState.rising,
                    ).withValues(alpha: 0.3),
                    AppTheme.getMomentumColor(
                      MomentumState.rising,
                    ).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeTimeline(
    BuildContext context,
    AsyncValue<List<Badge>> achievementsAsync,
  ) {
    final spacing = ResponsiveService.getMediumSpacing(context);

    return Container(
      margin: EdgeInsets.all(spacing),
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: AppTheme.getSurfacePrimary(context),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievement Timeline',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),

          const SizedBox(height: 16),

          achievementsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stack) =>
                    const Center(child: Text('Error loading achievements')),
            data: (badges) => _buildTimelineList(context, badges),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(BuildContext context, List<Badge> badges) {
    final earnedBadges = badges.where((badge) => badge.isEarned).toList();

    if (earnedBadges.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No achievements earned yet. Keep going!'),
        ),
      );
    }

    // Sort by earned date
    earnedBadges.sort(
      (a, b) => (b.earnedAt ?? DateTime.now()).compareTo(
        a.earnedAt ?? DateTime.now(),
      ),
    );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: earnedBadges.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final badge = earnedBadges[index];
        return _buildTimelineItem(context, badge);
      },
    );
  }

  Widget _buildTimelineItem(BuildContext context, Badge badge) {
    final spacing = ResponsiveService.getSmallSpacing(context);

    return Row(
      children: [
        // Badge icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.getMomentumColor(
              MomentumState.rising,
            ).withValues(alpha: 0.1),
            border: Border.all(
              color: AppTheme.getMomentumColor(
                MomentumState.rising,
              ).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              _getBadgeEmoji(badge.category),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),

        SizedBox(width: spacing),

        // Badge info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),

              const SizedBox(height: 2),

              Text(
                badge.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getTextSecondary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        SizedBox(width: spacing),

        // Earned date
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(badge.earnedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.getTextSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 2),

            Icon(
              Icons.check_circle,
              size: 16,
              color: AppTheme.getMomentumColor(MomentumState.rising),
            ),
          ],
        ),
      ],
    );
  }

  String _getBadgeEmoji(BadgeCategory category) {
    return switch (category) {
      BadgeCategory.streak => '🔥',
      BadgeCategory.momentum => '⚡',
      BadgeCategory.engagement => '💬',
      BadgeCategory.milestone => '🎯',
      BadgeCategory.special => '⭐',
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _shareProgress(BuildContext context, WidgetRef ref) async {
    try {
      final earnedCount = await ref.read(earnedBadgesCountProvider.future);
      final totalPoints = await ref.read(totalPointsProvider.future);
      final streak = await ref.read(currentStreakProvider.future);

      await ShareHelper.shareProgress(
        totalPoints: totalPoints,
        streakDays: streak,
        badgesEarned: earnedCount,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error sharing progress')));
      }
    }
  }
}
