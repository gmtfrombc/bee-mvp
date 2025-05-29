import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/error_handling_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/offline_cache_service.dart';

/// Enhanced error widget that provides context-aware error messages and actions
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
            // Error icon and title
            _buildErrorHeader(context, isOffline),

            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),

            // Error message
            _buildErrorMessage(context, isOffline),

            SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),

            // Cache info (if offline and cache available)
            if (showCacheInfo && isOffline) _buildCacheInfo(context),

            // Action buttons
            _buildActionButtons(context, isOffline),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorHeader(BuildContext context, bool isOffline) {
    IconData icon;
    Color iconColor;
    String title;

    if (isOffline) {
      icon = Icons.wifi_off;
      iconColor = AppTheme.momentumCare;
      title = 'You\'re Offline';
    } else if (error?.type == ErrorType.network) {
      icon = Icons.signal_wifi_connected_no_internet_4;
      iconColor = AppTheme.momentumCare;
      title = 'Connection Problem';
    } else if (error?.type == ErrorType.server) {
      icon = Icons.cloud_off;
      iconColor = AppTheme.momentumCare;
      title = 'Server Issue';
    } else if (error?.type == ErrorType.authentication) {
      icon = Icons.lock_outline;
      iconColor = Colors.orange;
      title = 'Authentication Required';
    } else {
      icon = Icons.error_outline;
      iconColor = AppTheme.momentumCare;
      title = 'Something Went Wrong';
    }

    return Column(
      children: [
        Icon(icon, size: 48, color: iconColor),
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context, bool isOffline) {
    String message;

    if (isOffline) {
      message =
          'No internet connection detected. You can still view your cached momentum data.';
    } else if (error?.userMessage != null) {
      message = error!.userMessage!;
    } else {
      message =
          'We\'re having trouble loading your momentum data. Please try again.';
    }

    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCacheInfo(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: OfflineCacheService.getCacheStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final stats = snapshot.data!;
        final hasCachedData = stats['hasCachedData'] as bool;
        final cacheAge = stats['cacheAge'] as int?;

        if (!hasCachedData) {
          return Container(
            padding: ResponsiveService.getSmallPadding(context),
            margin: EdgeInsets.only(
              bottom: ResponsiveService.getResponsiveSpacing(context),
            ),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveService.getBorderRadius(context),
              ),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: ResponsiveService.getSmallSpacing(context)),
                Expanded(
                  child: Text(
                    'No cached data available. Connect to internet to load your momentum.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final ageText =
            cacheAge != null
                ? cacheAge < 1
                    ? 'less than an hour ago'
                    : cacheAge == 1
                    ? '1 hour ago'
                    : '$cacheAge hours ago'
                : 'unknown';

        return Container(
          padding: ResponsiveService.getSmallPadding(context),
          margin: EdgeInsets.only(
            bottom: ResponsiveService.getResponsiveSpacing(context),
          ),
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
              Icon(Icons.cached, color: AppTheme.momentumSteady, size: 20),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              Expanded(
                child: Text(
                  'Showing cached data from $ageText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.momentumSteady,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isOffline) {
    return Column(
      children: [
        // Primary action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isOffline ? null : (onRetry ?? onRefresh),
            icon: Icon(isOffline ? Icons.wifi_off : Icons.refresh),
            label: Text(isOffline ? 'Waiting for Connection' : 'Try Again'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveService.getMediumSpacing(context),
              ),
            ),
          ),
        ),

        // Secondary actions
        if (!isOffline && error?.type == ErrorType.authentication) ...[
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          TextButton(
            onPressed: () {
              // TODO: Navigate to sign in
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sign in functionality coming soon'),
                ),
              );
            },
            child: const Text('Sign In Again'),
          ),
        ],

        if (error?.type == ErrorType.server) ...[
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          TextButton(
            onPressed: () {
              // Show error details
              _showErrorDetails(context);
            },
            child: const Text('View Details'),
          ),
        ],
      ],
    );
  }

  void _showErrorDetails(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Type: ${error?.type.name ?? 'Unknown'}'),
                  SizedBox(height: ResponsiveService.getSmallSpacing(context)),
                  Text('Severity: ${error?.severity.name ?? 'Unknown'}'),
                  SizedBox(height: ResponsiveService.getSmallSpacing(context)),
                  Text('Time: ${error?.timestamp.toString() ?? 'Unknown'}'),
                  SizedBox(height: ResponsiveService.getSmallSpacing(context)),
                  Text('Message: ${error?.message ?? 'No details available'}'),
                  if (error?.context != null) ...[
                    SizedBox(
                      height: ResponsiveService.getSmallSpacing(context),
                    ),
                    Text('Context: ${error!.context.toString()}'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
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
