import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/offline_cache_service.dart';

/// Displays cache information when offline
/// Shows cache status and age with appropriate styling
class ErrorCacheInfo extends StatelessWidget {
  const ErrorCacheInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: OfflineCacheService.getCacheStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final stats = snapshot.data!;
        final hasCachedData = stats['hasCachedData'] as bool;
        final cacheAge = stats['cacheAge'] as int?;

        return Container(
          margin: EdgeInsets.only(
            bottom: ResponsiveService.getResponsiveSpacing(context),
          ),
          child:
              hasCachedData
                  ? _buildCachedDataInfo(context, cacheAge)
                  : _buildNoCacheInfo(context),
        );
      },
    );
  }

  Widget _buildNoCacheInfo(BuildContext context) {
    return Container(
      padding: ResponsiveService.getSmallPadding(context),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          SizedBox(width: ResponsiveService.getSmallSpacing(context)),
          Expanded(
            child: Text(
              'No cached data available. Connect to internet to load your momentum.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCachedDataInfo(BuildContext context, int? cacheAge) {
    final ageText = _formatCacheAge(cacheAge);

    return Container(
      padding: ResponsiveService.getSmallPadding(context),
      decoration: BoxDecoration(
        color: AppTheme.momentumSteady.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(
          color: AppTheme.momentumSteady.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.cached, color: AppTheme.momentumSteady, size: 20),
          SizedBox(width: ResponsiveService.getSmallSpacing(context)),
          Expanded(
            child: Text(
              'Showing cached data from $ageText',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.momentumSteady),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCacheAge(int? cacheAge) {
    if (cacheAge == null) return 'unknown';

    if (cacheAge < 1) return 'less than an hour ago';
    if (cacheAge == 1) return '1 hour ago';
    return '$cacheAge hours ago';
  }
}
