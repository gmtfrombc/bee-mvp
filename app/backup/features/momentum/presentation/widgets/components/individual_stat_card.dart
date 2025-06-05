import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';

/// Individual stat card component with tap animations
/// Displays icon, value, and label with responsive design and accessibility support
class IndividualStatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const IndividualStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<IndividualStatCard> createState() => _IndividualStatCardState();
}

class _IndividualStatCardState extends State<IndividualStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _scaleController.forward().then((_) {
        if (mounted) {
          _scaleController.reverse();
        }
      });
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap != null ? _handleTap : null,
              borderRadius: BorderRadius.circular(
                ResponsiveService.getBorderRadius(context),
              ),
              child: Semantics(
                label: AccessibilityService.getQuickStatsLabel(
                  widget.label,
                  widget.value,
                  'Quick stat',
                ),
                hint: widget.onTap != null ? 'Tap for more details' : null,
                button: widget.onTap != null,
                child: Card(
                  elevation: 1,
                  shadowColor: widget.color.withValues(alpha: 0.1),
                  child: Container(
                    height: ResponsiveService.getQuickStatsCardHeight(context),
                    padding: EdgeInsets.all(
                      ResponsiveService.getResponsivePadding(context).left *
                          0.6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ResponsiveService.getBorderRadius(context),
                      ),
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          color: widget.color,
                          size: ResponsiveService.getIconSize(
                            context,
                            baseSize: 18,
                          ),
                        ),
                        SizedBox(
                          height:
                              ResponsiveService.getResponsiveSpacing(context) *
                              0.1,
                        ),
                        Flexible(
                          child: Text(
                            widget.value,
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              color: widget.color,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          height:
                              ResponsiveService.getResponsiveSpacing(context) *
                              0.05,
                        ),
                        Flexible(
                          child: Text(
                            widget.label,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: AppTheme.getTextSecondary(context),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
