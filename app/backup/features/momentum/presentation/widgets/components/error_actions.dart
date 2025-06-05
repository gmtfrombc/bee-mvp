import 'package:flutter/material.dart';
import '../../../../../core/services/responsive_service.dart';
import '../../../../../core/services/error_handling_service.dart';

/// Handles error actions including retry buttons and error details
class ErrorActions extends StatelessWidget {
  final AppError? error;
  final bool isOffline;
  final VoidCallback? onRetry;
  final VoidCallback? onRefresh;

  const ErrorActions({
    super.key,
    this.error,
    required this.isOffline,
    this.onRetry,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary action button
        _buildPrimaryAction(context),

        // Secondary actions based on error type
        ..._buildSecondaryActions(context),
      ],
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    return SizedBox(
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
    );
  }

  List<Widget> _buildSecondaryActions(BuildContext context) {
    final actions = <Widget>[];

    if (!isOffline && error?.type == ErrorType.authentication) {
      actions.addAll([
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        TextButton(
          onPressed: () => _handleSignIn(context),
          child: const Text('Sign In Again'),
        ),
      ]);
    }

    if (error?.type == ErrorType.server) {
      actions.addAll([
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        TextButton(
          onPressed: () => _showErrorDetails(context),
          child: const Text('View Details'),
        ),
      ]);
    }

    return actions;
  }

  void _handleSignIn(BuildContext context) {
    // TODO: Navigate to sign in
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in functionality coming soon')),
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
