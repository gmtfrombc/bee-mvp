import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'skeleton_base_components.dart';

/// Skeleton weekly trend chart
class SkeletonWeeklyTrendChart extends StatelessWidget {
  final double? height;

  const SkeletonWeeklyTrendChart({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final chartHeight =
        height ?? ResponsiveService.getWeeklyChartHeight(context);
    final padding = ResponsiveService.getResponsivePadding(context);
    final spacing = ResponsiveService.getResponsiveSpacing(context);
    final borderRadius = ResponsiveService.getBorderRadius(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        height: chartHeight,
        padding: padding,
        child: ShimmerWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton - responsive sizing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonContainer(
                    width: MediaQuery.of(context).size.width * 0.35,
                    height:
                        ResponsiveService.shouldUseCompactLayout(context)
                            ? 16
                            : 18,
                    borderRadius: BorderRadius.circular(borderRadius * 0.5),
                  ),
                  SkeletonContainer(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height:
                        ResponsiveService.shouldUseCompactLayout(context)
                            ? 12
                            : 14,
                    borderRadius: BorderRadius.circular(borderRadius * 0.4),
                  ),
                ],
              ),

              SizedBox(height: spacing * 0.6),

              // Chart area skeleton - fully responsive
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    // Make heights responsive to available space
                    final baseHeights = [0.5, 0.7, 0.6, 0.85, 0.65, 0.8, 0.6];
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            flex: (baseHeights[index] * 10).round(),
                            child: Container(
                              width:
                                  ResponsiveService.shouldUseCompactLayout(
                                        context,
                                      )
                                      ? 12
                                      : 16,
                              decoration: BoxDecoration(
                                color: AppTheme.getTextTertiary(
                                  context,
                                ).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(
                                  borderRadius * 0.5,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacing * 0.2),
                          SkeletonContainer(
                            width:
                                ResponsiveService.shouldUseCompactLayout(
                                      context,
                                    )
                                    ? 10
                                    : 12,
                            height:
                                ResponsiveService.shouldUseCompactLayout(
                                      context,
                                    )
                                    ? 6
                                    : 8,
                            borderRadius: BorderRadius.circular(
                              borderRadius * 0.25,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
