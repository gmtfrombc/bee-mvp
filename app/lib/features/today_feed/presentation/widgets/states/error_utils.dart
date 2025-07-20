// Utility helpers for error classification & messaging in Today Feed widgets.
// Separated out to keep individual widget files small and reusable.

import 'package:flutter/material.dart';
import '../../../../../core/services/connectivity_service.dart';

/// Returns true when [message] indicates a network-level failure.
bool isNetworkError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('network') ||
      lower.contains('connection') ||
      lower.contains('timeout') ||
      lower.contains('unreachable');
}

/// Returns true when [message] indicates a server-side (5xx) error.
bool isServerError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('server') ||
      lower.contains('503') ||
      lower.contains('502') ||
      lower.contains('500');
}

/// Small tuple describing a status badge.
(String statusText, IconData statusIcon, Color statusColor) getErrorStatus(
  String message,
) {
  if (!ConnectivityService.isOnline) {
    return ('OFFLINE', Icons.wifi_off, Colors.red);
  } else if (isNetworkError(message)) {
    return ('NETWORK', Icons.network_check, Colors.orange);
  } else if (isServerError(message)) {
    return ('SERVER', Icons.cloud_off, Colors.red);
  } else {
    return ('ERROR', Icons.error_outline, Colors.red);
  }
}

/// Detailed title, icon and inline suggestions for a given [message].
(String title, IconData icon, List<String> suggestions) getErrorDetails(
  String message,
) {
  if (!ConnectivityService.isOnline) {
    return (
      "You're offline",
      Icons.wifi_off,
      [
        'Check your internet connection',
        'Try switching between WiFi and mobile data',
        'Move to an area with better signal',
      ],
    );
  } else if (isNetworkError(message)) {
    return (
      'Connection problem',
      Icons.network_check,
      [
        'Check your internet connection',
        'Try again in a few moments',
        'Contact support if this persists',
      ],
    );
  } else if (isServerError(message)) {
    return (
      'Service temporarily unavailable',
      Icons.cloud_off,
      [
        'Our servers are experiencing issues',
        'Please try again in a few minutes',
        "We're working to resolve this quickly",
      ],
    );
  } else {
    return (
      'Something went wrong',
      Icons.error_outline,
      [
        'Please try again',
        'Restart the app if this continues',
        'Contact support for help',
      ],
    );
  }
}

/// Chooses a colour for the large icon displayed in the error card.
Color getErrorColor(String message, BuildContext context) {
  if (!ConnectivityService.isOnline || isNetworkError(message)) {
    return Colors.orange;
  }
  return Theme.of(context).colorScheme.error;
}
