import 'package:flutter/material.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Header widget displaying the circular point indicator with glow
class MomentumPointIndicator extends StatelessWidget {
  const MomentumPointIndicator({
    super.key,
    required this.pointsAwarded,
    required this.scaleAnimation,
    required this.glowAnimation,
  });

  /// Number of points awarded to the user
  final int pointsAwarded;

  /// Animation that scales the indicator in/out
  final Animation<double> scaleAnimation;

  /// Animation that drives the ambient glow around the indicator
  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    final pointSize = ResponsiveService.getIconSize(context, baseSize: 48);
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 24);

    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Container(
            width: pointSize,
            height: pointSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.momentumRising,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow pulse
                AnimatedBuilder(
                  animation: glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: pointSize * (1 + glowAnimation.value * 0.2),
                      height: pointSize * (1 + glowAnimation.value * 0.2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.momentumRising.withValues(
                          alpha: 0.3 * (1 - glowAnimation.value),
                        ),
                      ),
                    );
                  },
                ),
                // Main icon
                Icon(Icons.add_circle, size: iconSize, color: Colors.white),
                // Text overlay with +points awarded
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '+$pointsAwarded',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.momentumRising,
                        fontWeight: FontWeight.w800,
                        fontSize:
                            ResponsiveService.getFontSizeMultiplier(context) *
                            10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
