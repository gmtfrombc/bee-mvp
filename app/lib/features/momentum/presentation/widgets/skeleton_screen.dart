import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';
import 'skeleton_base_components.dart';
import 'skeleton_momentum_card.dart';
import 'skeleton_weekly_trend_chart.dart';
import 'skeleton_quick_stats_cards.dart';
import 'skeleton_action_buttons.dart';

/// Skeleton loading state for the entire momentum screen
class SkeletonMomentumScreen extends StatelessWidget {
  const SkeletonMomentumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveService.getResponsivePadding(context);
    final spacing = ResponsiveService.getResponsiveSpacing(context);
    final borderRadius = ResponsiveService.getBorderRadius(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Momentum card skeleton
          const SkeletonMomentumCard(),

          SizedBox(height: spacing),

          // Weekly trend chart skeleton
          const SkeletonWeeklyTrendChart(),

          SizedBox(height: spacing),

          // Quick stats cards skeleton
          const SkeletonQuickStatsCards(),

          SizedBox(height: spacing),

          // Action buttons skeleton
          const SkeletonActionButtons(),

          SizedBox(height: spacing),

          // Demo section skeleton - responsive
          Card(
            margin: ResponsiveService.getResponsiveMargin(context),
            child: Container(
              padding: padding,
              child: ShimmerWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonText(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height:
                          ResponsiveService.shouldUseCompactLayout(context)
                              ? 16
                              : 18,
                    ),
                    SizedBox(height: spacing * 0.8),
                    Center(
                      child: SkeletonMomentumGauge(
                        size: ResponsiveService.getMomentumGaugeSize(context),
                      ),
                    ),
                    SizedBox(height: spacing * 0.8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: spacing * 0.2,
                            ),
                            child: SkeletonContainer(
                              width: double.infinity,
                              height:
                                  ResponsiveService.shouldUseCompactLayout(
                                        context,
                                      )
                                      ? 28
                                      : 32,
                              borderRadius: BorderRadius.circular(
                                borderRadius * 1.3,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: spacing * 0.6),
                    Center(
                      child: SkeletonText(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height:
                            ResponsiveService.shouldUseCompactLayout(context)
                                ? 12
                                : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
