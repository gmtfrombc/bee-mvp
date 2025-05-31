import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../domain/models/momentum_data.dart';

/// Actions and header component for the momentum detail modal
/// Handles header display, close action, and any additional action buttons
class MomentumDetailActions extends StatelessWidget {
  final MomentumData momentumData;
  final VoidCallback onClose;

  const MomentumDetailActions({
    super.key,
    required this.momentumData,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveService.getLargePadding(context),
      decoration: BoxDecoration(
        color: AppTheme.getMomentumColor(
          momentumData.state,
        ).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Momentum Details',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.getMomentumColor(momentumData.state),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: ResponsiveService.getTinySpacing(context)),
                Text(
                  'Last updated ${_formatLastUpdated()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.getSurfaceSecondary(context),
              foregroundColor: AppTheme.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  void _handleClose() {
    HapticFeedback.lightImpact();
    onClose();
  }

  String _formatLastUpdated() {
    final now = DateTime.now();
    final difference = now.difference(momentumData.lastUpdated);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
