import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';
import 'skeleton_base_components.dart';

/// Skeleton action buttons
class SkeletonActionButtons extends StatelessWidget {
  final double? height;

  const SkeletonActionButtons({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final buttonHeight =
        height ?? (ResponsiveService.shouldUseCompactLayout(context) ? 50 : 60);
    final padding = ResponsiveService.getResponsivePadding(context);
    final spacing = ResponsiveService.getResponsiveSpacing(context);
    final borderRadius = ResponsiveService.getBorderRadius(context);

    return Card(
      child: Container(
        height: buttonHeight,
        padding: padding,
        child: ShimmerWidget(
          child: Row(
            children: [
              Expanded(
                child: SkeletonContainer(
                  width: double.infinity,
                  height:
                      ResponsiveService.shouldUseCompactLayout(context)
                          ? 32
                          : 36,
                  borderRadius: BorderRadius.circular(borderRadius * 1.5),
                ),
              ),
              SizedBox(width: spacing * 0.6),
              Expanded(
                child: SkeletonContainer(
                  width: double.infinity,
                  height:
                      ResponsiveService.shouldUseCompactLayout(context)
                          ? 32
                          : 36,
                  borderRadius: BorderRadius.circular(borderRadius * 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
