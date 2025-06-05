import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'skeleton_base_components.dart';

/// Optimized skeleton momentum card with efficient shimmer effect
class SkeletonMomentumCard extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;

  const SkeletonMomentumCard({super.key, this.height, this.margin});

  @override
  Widget build(BuildContext context) {
    // Optimized: Pre-calculate all dimensions to avoid repeated calls
    final dimensions = SkeletonDimensions.fromContext(context);
    final cardHeight = height ?? dimensions.cardHeight;
    final cardMargin = margin ?? dimensions.cardMargin;

    return Container(
      margin: cardMargin,
      child: Card(
        elevation: 2,
        child: Container(
          height: cardHeight,
          padding: dimensions.padding,
          child: ShimmerWidget(
            child: _buildOptimizedSkeletonContent(context, dimensions),
          ),
        ),
      ),
    );
  }

  // Optimized: Extract skeleton content to reduce widget rebuilds
  Widget _buildOptimizedSkeletonContent(
    BuildContext context,
    SkeletonDimensions dimensions,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Header skeleton - responsive width based on screen
        SkeletonContainer(
          width: dimensions.headerWidth,
          height: dimensions.headerHeight,
          borderRadius: BorderRadius.circular(dimensions.borderRadius * 0.5),
        ),

        SizedBox(height: dimensions.spacing * 0.2),

        // Gauge skeleton (circular) - Use responsive size
        Flexible(
          flex: 4,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: dimensions.gaugeSize,
              maxHeight: dimensions.gaugeSize,
            ),
            decoration: BoxDecoration(
              color: AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),

        SizedBox(height: dimensions.spacing * 0.15),

        // State text skeleton - responsive sizing
        SkeletonContainer(
          width: dimensions.stateTextWidth,
          height: dimensions.stateTextHeight,
          borderRadius: BorderRadius.circular(dimensions.borderRadius * 0.6),
        ),

        SizedBox(height: dimensions.spacing * 0.15),

        // Message skeleton - responsive and flexible
        Flexible(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonContainer(
                width: double.infinity,
                height: dimensions.messageHeight,
                borderRadius: BorderRadius.circular(
                  dimensions.borderRadius * 0.4,
                ),
              ),
              SizedBox(height: dimensions.spacing * 0.1),
              SkeletonContainer(
                width: dimensions.messageSecondWidth,
                height: dimensions.messageHeight,
                borderRadius: BorderRadius.circular(
                  dimensions.borderRadius * 0.4,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: dimensions.spacing * 0.15),

        // Progress bar skeleton - responsive height
        SkeletonContainer(
          width: double.infinity,
          height: dimensions.progressBarHeight,
          borderRadius: BorderRadius.circular(dimensions.borderRadius * 0.25),
        ),
      ],
    );
  }
}

/// Skeleton momentum gauge (circular)
class SkeletonMomentumGauge extends StatelessWidget {
  final double? size;

  const SkeletonMomentumGauge({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final gaugeSize = size ?? ResponsiveService.getMomentumGaugeSize(context);

    return ShimmerWidget(
      child: Container(
        width: gaugeSize,
        height: gaugeSize,
        decoration: BoxDecoration(
          color: AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: gaugeSize * 0.6,
            height: gaugeSize * 0.6,
            decoration: BoxDecoration(
              color: AppTheme.getTextTertiary(context).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
