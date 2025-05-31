import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';
import 'skeleton_base_components.dart';

/// Skeleton quick stats cards
class SkeletonQuickStatsCards extends StatelessWidget {
  const SkeletonQuickStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final cardHeight = ResponsiveService.getQuickStatsCardHeight(context);
    final padding = ResponsiveService.getResponsivePadding(context);
    final spacing = ResponsiveService.getResponsiveSpacing(context);
    final borderRadius = ResponsiveService.getBorderRadius(context);

    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? spacing * 0.4 : 0),
            child: Card(
              child: Container(
                height: cardHeight,
                padding: EdgeInsets.all(
                  padding.left * 0.75,
                ), // Slightly less padding for cards
                child: ShimmerWidget(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Icon skeleton - responsive sizing
                      SkeletonContainer(
                        width: ResponsiveService.getIconSize(context),
                        height: ResponsiveService.getIconSize(context),
                        borderRadius: BorderRadius.circular(borderRadius * 0.5),
                      ),

                      SizedBox(height: spacing * 0.4),

                      // Value skeleton - flexible
                      Flexible(
                        child: SkeletonContainer(
                          width:
                              ResponsiveService.shouldUseCompactLayout(context)
                                  ? 24
                                  : 30,
                          height:
                              ResponsiveService.shouldUseCompactLayout(context)
                                  ? 16
                                  : 20,
                          borderRadius: BorderRadius.circular(
                            borderRadius * 0.5,
                          ),
                        ),
                      ),

                      SizedBox(height: spacing * 0.4),

                      // Label skeleton - responsive
                      SkeletonContainer(
                        width:
                            ResponsiveService.shouldUseCompactLayout(context)
                                ? 40
                                : 50,
                        height:
                            ResponsiveService.shouldUseCompactLayout(context)
                                ? 10
                                : 12,
                        borderRadius: BorderRadius.circular(borderRadius * 0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
