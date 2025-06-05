import 'package:flutter/material.dart';
import '../../../../../core/services/responsive_service.dart';

/// A reusable stat card widget for the coach dashboard that displays
/// a metric with an icon, value, and title in a consistent card layout.
///
/// This widget is used throughout the coach dashboard to display various
/// statistics like active interventions, scheduled items, success rates, etc.
class CoachDashboardStatCard extends StatelessWidget {
  /// Creates a coach dashboard stat card.
  const CoachDashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  /// The title/label displayed at the bottom of the card
  final String title;

  /// The main value/metric displayed prominently in the card
  final String value;

  /// The icon displayed in the top-left of the card
  final IconData icon;

  /// The primary color used for the icon and value background
  final Color color;

  /// Optional callback when the card is tapped (for future analytics drill-down)
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = ResponsiveService.getMediumPadding(context);
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 24.0);
    final borderRadius = ResponsiveService.getBorderRadius(context);
    final fontSizeMultiplier = ResponsiveService.getFontSizeMultiplier(context);
    final smallSpacing = ResponsiveService.getSmallSpacing(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: responsivePadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: iconSize),
                SizedBox(width: smallSpacing),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: smallSpacing,
                        vertical: smallSpacing * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18 * fontSizeMultiplier,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: smallSpacing),
            Text(
              title,
              style: TextStyle(
                fontSize: 14 * fontSizeMultiplier,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
