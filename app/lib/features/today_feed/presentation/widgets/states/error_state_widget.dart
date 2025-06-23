import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../../../core/services/connectivity_service.dart';

/// Enhanced error state widget for Today Feed tile
/// Displays categorized error messages with intelligent retry functionality
class TodayFeedErrorStateWidget extends StatefulWidget {
  const TodayFeedErrorStateWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.enableNetworkRetry = true,
  });

  final String errorMessage;
  final VoidCallback? onRetry;
  final bool enableNetworkRetry;

  @override
  State<TodayFeedErrorStateWidget> createState() =>
      _TodayFeedErrorStateWidgetState();
}

class _TodayFeedErrorStateWidgetState extends State<TodayFeedErrorStateWidget> {
  bool _isRetrying = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildErrorHeader(context),
        Expanded(child: _buildErrorContent(context)),
        _buildErrorActionSection(context),
      ],
    );
  }

  Widget _buildErrorHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Health Insight",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.getTextSecondary(context),
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  fontSize:
                      Theme.of(context).textTheme.labelMedium!.fontSize! *
                      ResponsiveService.getFontSizeMultiplier(context) *
                      1.1,
                ),
                maxLines: 2,
              ),
              SizedBox(height: ResponsiveService.getTinySpacing(context) / 2),
              Text(
                _formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getTextTertiary(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: ResponsiveService.getTinySpacing(context)),
        Flexible(child: _buildStatusBadge(context)),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final spacing = ResponsiveService.getTinySpacing(context);
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 12);
    final (statusText, statusIcon, statusColor) = _getErrorStatus();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing * 2, vertical: spacing),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context) / 2,
        ),
        border: Border.all(
          color: AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: iconSize, color: statusColor),
          SizedBox(width: spacing),
          Text(
            statusText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    final (errorTitle, errorIcon, suggestions) = _getErrorDetails();

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            errorIcon,
            size: ResponsiveService.getIconSize(context, baseSize: 40),
            color: _getErrorColor(),
          ),
          SizedBox(height: ResponsiveService.getSmallSpacing(context)),
          Text(
            errorTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.getTextPrimary(context),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ResponsiveService.getTinySpacing(context)),
          Text(
            widget.errorMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (_retryCount > 0) ...[
            SizedBox(height: ResponsiveService.getTinySpacing(context)),
            _buildRetryIndicator(context),
          ],
          if (suggestions.isNotEmpty) ...[
            SizedBox(height: ResponsiveService.getSmallSpacing(context)),
            _buildInlineSuggestions(context, suggestions),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineSuggestions(
    BuildContext context,
    List<String> suggestions,
  ) {
    return Container(
      padding: ResponsiveService.getSmallPadding(context),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceSecondary(context),
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(
          color: AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: ResponsiveService.getIconSize(context, baseSize: 14),
                color: AppTheme.momentumSteady,
              ),
              SizedBox(width: ResponsiveService.getTinySpacing(context)),
              Text(
                'Tips:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.momentumSteady,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveService.getTinySpacing(context)),
          ...suggestions
              .take(2)
              .map(
                (suggestion) => Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveService.getTinySpacing(context) / 2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.getTextSecondary(context),
                          fontSize: 10,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getTextSecondary(context),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildRetryIndicator(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.refresh,
          size: ResponsiveService.getIconSize(context, baseSize: 14),
          color: AppTheme.getTextTertiary(context),
        ),
        SizedBox(width: ResponsiveService.getTinySpacing(context)),
        Text(
          'Retry attempt $_retryCount of $_maxRetries',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.getTextTertiary(context),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorActionSection(BuildContext context) {
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);
    final buttonHeight =
        ResponsiveService.shouldUseCompactLayout(context)
            ? AccessibilityService.minimumTouchTarget - 12
            : AccessibilityService.minimumTouchTarget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Connection status on top
        _buildConnectionStatus(context),
        SizedBox(height: ResponsiveService.getTinySpacing(context)),

        // Action buttons below
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_shouldShowNetworkSettings()) ...[
              Flexible(
                child: TextButton.icon(
                  onPressed: _openNetworkSettings,
                  icon: Icon(Icons.settings, size: iconSize),
                  label: const Text("Settings"),
                  style: TextButton.styleFrom(
                    minimumSize: Size(80, buttonHeight),
                    padding: ResponsiveService.getHorizontalPadding(
                      context,
                      multiplier: 0.4,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            ],
            Flexible(
              child: ElevatedButton.icon(
                onPressed:
                    _isRetrying || _retryCount >= _maxRetries
                        ? null
                        : _handleRetry,
                icon:
                    _isRetrying
                        ? SizedBox(
                          width: iconSize,
                          height: iconSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                        : Icon(Icons.refresh, size: iconSize),
                label: Text(_isRetrying ? "Retrying..." : "Retry"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(100, buttonHeight),
                  padding: ResponsiveService.getHorizontalPadding(
                    context,
                    multiplier: 0.6,
                  ),
                  textStyle: _getButtonTextStyle(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    final isConnected = ConnectivityService.isOnline;
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 14);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isConnected ? Icons.wifi : Icons.wifi_off,
          size: iconSize,
          color: isConnected ? Colors.green : Colors.red,
        ),
        SizedBox(width: ResponsiveService.getTinySpacing(context)),
        Text(
          isConnected ? 'Connected' : 'Offline',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color:
                isConnected ? Colors.green : AppTheme.getTextTertiary(context),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Helper methods for error categorization

  (String, IconData, Color) _getErrorStatus() {
    if (!ConnectivityService.isOnline) {
      return ("OFFLINE", Icons.wifi_off, Colors.red);
    } else if (_isNetworkError()) {
      return ("NETWORK", Icons.network_check, Colors.orange);
    } else if (_isServerError()) {
      return ("SERVER", Icons.cloud_off, Colors.red);
    } else {
      return ("ERROR", Icons.error_outline, Colors.red);
    }
  }

  (String, IconData, List<String>) _getErrorDetails() {
    if (!ConnectivityService.isOnline) {
      return (
        "You're offline",
        Icons.wifi_off,
        [
          "Check your internet connection",
          "Try switching between WiFi and mobile data",
          "Move to an area with better signal",
        ],
      );
    } else if (_isNetworkError()) {
      return (
        "Connection problem",
        Icons.network_check,
        [
          "Check your internet connection",
          "Try again in a few moments",
          "Contact support if this persists",
        ],
      );
    } else if (_isServerError()) {
      return (
        "Service temporarily unavailable",
        Icons.cloud_off,
        [
          "Our servers are experiencing issues",
          "Please try again in a few minutes",
          "We're working to resolve this quickly",
        ],
      );
    } else {
      return (
        "Something went wrong",
        Icons.error_outline,
        [
          "Please try again",
          "Restart the app if this continues",
          "Contact support for help",
        ],
      );
    }
  }

  Color _getErrorColor() {
    if (!ConnectivityService.isOnline) {
      return Colors.orange;
    } else if (_isNetworkError()) {
      return Colors.amber;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }

  bool _isNetworkError() {
    final message = widget.errorMessage.toLowerCase();
    return message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('unreachable');
  }

  bool _isServerError() {
    final message = widget.errorMessage.toLowerCase();
    return message.contains('server') ||
        message.contains('503') ||
        message.contains('502') ||
        message.contains('500');
  }

  bool _shouldShowNetworkSettings() {
    return !ConnectivityService.isOnline || _isNetworkError();
  }

  // Action handlers

  Future<void> _handleRetry() async {
    if (_isRetrying || _retryCount >= _maxRetries) return;

    setState(() {
      _isRetrying = true;
      _retryCount++;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Add intelligent delay based on retry count
    final delay = Duration(seconds: _retryCount);
    await Future.delayed(delay);

    try {
      widget.onRetry?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  void _openNetworkSettings() {
    // Haptic feedback
    HapticFeedback.selectionClick();

    // TODO: Open network settings - implementation depends on platform
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('Please check your network settings manually'),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Utility methods

  TextStyle _getButtonTextStyle(BuildContext context) {
    final baseSize =
        ResponsiveService.shouldUseCompactLayout(context) ? 14.0 : 16.0;
    return TextStyle(
      fontSize: _getResponsiveFontSize(context, baseFontSize: baseSize),
      fontWeight: FontWeight.w600,
    );
  }

  double _getResponsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
  }) {
    final accessibleScale = AccessibilityService.getAccessibleTextScale(
      context,
    );
    final responsiveMultiplier = ResponsiveService.getFontSizeMultiplier(
      context,
    );
    return baseFontSize * responsiveMultiplier * accessibleScale;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
