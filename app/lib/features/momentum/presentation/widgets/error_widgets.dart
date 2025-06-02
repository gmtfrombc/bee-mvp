import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/error_handling_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/offline_cache_service.dart';
import 'components/error_type_handler.dart';
import 'components/error_cache_info.dart';
import 'components/error_actions.dart';

/// Enhanced error widget that provides context-aware error messages and actions
/// Refactored to use extracted components for better maintainability
class MomentumErrorWidget extends ConsumerWidget {
  final AppError? error;
  final VoidCallback? onRetry;
  final VoidCallback? onRefresh;
  final bool showCacheInfo;

  const MomentumErrorWidget({
    super.key,
    this.error,
    this.onRetry,
    this.onRefresh,
    this.showCacheInfo = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    return Card(
      margin: ResponsiveService.getResponsivePadding(context),
      child: Padding(
        padding: ResponsiveService.getResponsivePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error type handling (icon, title, message)
            ErrorTypeHandler(error: error, isOffline: isOffline),

            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),

            // Cache info (if offline and cache available)
            if (showCacheInfo && isOffline) const ErrorCacheInfo(),

            // Action buttons
            ErrorActions(
              error: error,
              isOffline: isOffline,
              onRetry: onRetry,
              onRefresh: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact error widget for smaller spaces
class CompactErrorWidget extends ConsumerWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const CompactErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    return Container(
      padding: ResponsiveService.getSmallPadding(context),
      decoration: BoxDecoration(
        color: AppTheme.momentumCare.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(color: AppTheme.momentumCare.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.error_outline,
            color: AppTheme.momentumCare,
            size: 20,
          ),
          SizedBox(width: ResponsiveService.getSmallSpacing(context)),
          Expanded(
            child: Text(
              message ??
                  (isOffline
                      ? 'Offline - showing cached data'
                      : 'Unable to load data'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.momentumCare),
            ),
          ),
          if (showRetryButton && !isOffline) ...[
            SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              iconSize: 20,
              constraints: BoxConstraints(
                minWidth: ResponsiveService.getResponsiveSpacing(context) * 1.6,
                minHeight:
                    ResponsiveService.getResponsiveSpacing(context) * 1.6,
              ),
              padding: EdgeInsets.all(
                ResponsiveService.getSmallSpacing(context) * 0.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Offline banner widget to show at the top of the screen
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveService.getResponsiveSpacing(context),
        vertical: ResponsiveService.getSmallSpacing(context),
      ),
      color: AppTheme.momentumCare,
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: AppTheme.getSurfacePrimary(context),
            size: 16,
          ),
          SizedBox(width: ResponsiveService.getSmallSpacing(context)),
          Expanded(
            child: Text(
              'You\'re offline. Showing cached data.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.getSurfacePrimary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: OfflineCacheService.getCacheStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final stats = snapshot.data!;
              final cacheAge = stats['cacheAge'] as int?;

              if (cacheAge == null) return const SizedBox.shrink();

              return Text(
                cacheAge < 1 ? 'Recent' : '${cacheAge}h old',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getSurfacePrimary(
                    context,
                  ).withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
