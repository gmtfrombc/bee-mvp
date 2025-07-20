import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/accessibility_service.dart';
import '../../../../../core/services/connectivity_service.dart';
import '../../../../../core/theme/app_theme.dart';
import 'error_utils.dart';

class RetryCta extends StatefulWidget {
  const RetryCta({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.enableNetworkRetry = true,
  });

  final String errorMessage;
  final VoidCallback? onRetry;
  final bool enableNetworkRetry;

  @override
  State<RetryCta> createState() => _RetryCtaState();
}

class _RetryCtaState extends State<RetryCta> {
  bool _isRetrying = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildConnectionStatus(context),
        SizedBox(height: ResponsiveService.getTinySpacing(context)),
        _buildButtons(context),
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

  Widget _buildButtons(BuildContext context) {
    final iconSize = ResponsiveService.getIconSize(context, baseSize: 16);
    final buttonHeight =
        ResponsiveService.shouldUseCompactLayout(context)
            ? AccessibilityService.minimumTouchTarget - 12
            : AccessibilityService.minimumTouchTarget;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_shouldShowNetworkSettings()) ...[
          Flexible(
            child: TextButton.icon(
              onPressed: _openNetworkSettings,
              icon: Icon(Icons.settings, size: iconSize),
              label: const Text('Settings'),
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
                _isRetrying || _retryCount >= _maxRetries ? null : _handleRetry,
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
            label: Text(_isRetrying ? 'Retrying...' : 'Retry'),
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
    );
  }

  Future<void> _handleRetry() async {
    if (_isRetrying || _retryCount >= _maxRetries) return;

    setState(() {
      _isRetrying = true;
      _retryCount++;
    });

    HapticFeedback.lightImpact();

    await Future.delayed(Duration(seconds: _retryCount));

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
    HapticFeedback.selectionClick();

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

  bool _shouldShowNetworkSettings() {
    return !ConnectivityService.isOnline || isNetworkError(widget.errorMessage);
  }

  TextStyle _getButtonTextStyle(BuildContext context) {
    final baseSize =
        ResponsiveService.shouldUseCompactLayout(context) ? 14.0 : 16.0;
    final accessibleScale = AccessibilityService.getAccessibleTextScale(
      context,
    );
    final responsiveMultiplier = ResponsiveService.getFontSizeMultiplier(
      context,
    );
    return TextStyle(
      fontSize: baseSize * responsiveMultiplier * accessibleScale,
      fontWeight: FontWeight.w600,
    );
  }
}
