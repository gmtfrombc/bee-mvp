import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/error_handling_service.dart';

/// Handles different error types with appropriate icons, colors, and messages
class ErrorTypeHandler extends StatelessWidget {
  final AppError? error;
  final bool isOffline;

  const ErrorTypeHandler({super.key, this.error, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildErrorHeader(context),
        SizedBox(height: ResponsiveService.getResponsiveSpacing(context)),
        _buildErrorMessage(context),
      ],
    );
  }

  Widget _buildErrorHeader(BuildContext context) {
    final errorInfo = _getErrorInfo();

    return Column(
      children: [
        Icon(errorInfo.icon, size: 48, color: errorInfo.iconColor),
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        Text(
          errorInfo.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    final message = _getErrorMessage();

    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  ErrorInfo _getErrorInfo() {
    if (isOffline) {
      return ErrorInfo(
        icon: Icons.wifi_off,
        iconColor: AppTheme.momentumCare,
        title: 'You\'re Offline',
      );
    }

    switch (error?.type) {
      case ErrorType.network:
        return ErrorInfo(
          icon: Icons.signal_wifi_connected_no_internet_4,
          iconColor: AppTheme.momentumCare,
          title: 'Connection Problem',
        );
      case ErrorType.server:
        return ErrorInfo(
          icon: Icons.cloud_off,
          iconColor: AppTheme.momentumCare,
          title: 'Server Issue',
        );
      case ErrorType.authentication:
        return ErrorInfo(
          icon: Icons.lock_outline,
          iconColor: Colors.orange,
          title: 'Authentication Required',
        );
      default:
        return ErrorInfo(
          icon: Icons.error_outline,
          iconColor: AppTheme.momentumCare,
          title: 'Something Went Wrong',
        );
    }
  }

  String _getErrorMessage() {
    if (isOffline) {
      return 'No internet connection detected. You can still view your cached momentum data.';
    }

    if (error?.userMessage != null) {
      return error!.userMessage!;
    }

    return 'We\'re having trouble loading your momentum data. Please try again.';
  }
}

/// Error information data class
class ErrorInfo {
  final IconData icon;
  final Color iconColor;
  final String title;

  const ErrorInfo({
    required this.icon,
    required this.iconColor,
    required this.title,
  });
}
