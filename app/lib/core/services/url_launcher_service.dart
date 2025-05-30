import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for handling URL launching with in-app browser and external app support
/// Provides basic error handling for Today Feed external links
class UrlLauncherService {
  static const UrlLauncherService _instance = UrlLauncherService._internal();
  factory UrlLauncherService() => _instance;
  const UrlLauncherService._internal();

  /// Launch URL with in-app browser for health content links
  /// Uses Safari View Controller on iOS and Custom Chrome Tabs on Android
  Future<bool> launchHealthContentUrl(
    String url, {
    String? linkText,
    String? sourceContext,
  }) async {
    debugPrint('UrlLauncherService: Launching health content URL: $url');

    if (!_isValidUrl(url)) {
      debugPrint('UrlLauncherService: Invalid URL format: $url');
      return false;
    }

    try {
      final uri = Uri.parse(url);

      // Use in-app browser for external health content
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );

      if (launched) {
        debugPrint(
          'UrlLauncherService: Successfully launched URL in in-app browser',
        );
        return true;
      } else {
        debugPrint('UrlLauncherService: Failed to launch URL: $url');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('UrlLauncherService: Error launching URL: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Launch URL in external browser as fallback
  Future<bool> launchInExternalBrowser(
    String url, {
    String? linkText,
    String? sourceContext,
  }) async {
    debugPrint('UrlLauncherService: Launching URL in external browser: $url');

    if (!_isValidUrl(url)) {
      debugPrint('UrlLauncherService: Invalid URL format: $url');
      return false;
    }

    try {
      final uri = Uri.parse(url);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        debugPrint(
          'UrlLauncherService: Successfully launched URL in external browser',
        );
        return true;
      } else {
        debugPrint(
          'UrlLauncherService: Failed to launch URL in external browser: $url',
        );
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint(
        'UrlLauncherService: Error launching URL in external browser: $e',
      );
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Check if URL can be launched
  Future<bool> canLaunchHealthUrl(String url) async {
    if (!_isValidUrl(url)) return false;

    try {
      final uri = Uri.parse(url);
      return await canLaunchUrl(uri);
    } catch (e) {
      debugPrint(
        'UrlLauncherService: Error checking if URL can be launched: $e',
      );
      return false;
    }
  }

  /// Show URL in a preview dialog for user confirmation
  Future<bool> showUrlPreviewDialog(
    BuildContext context,
    String url, {
    String? linkText,
    String? description,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Open External Link'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description != null) ...[
                      Text(description),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Link: ${linkText ?? 'External content'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      url,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This will open in a secure browser view within the app.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Open Link'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  /// Copy URL to clipboard as alternative action
  Future<void> copyUrlToClipboard(String url, {String? linkText}) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      debugPrint('UrlLauncherService: URL copied to clipboard');
    } catch (e) {
      debugPrint('UrlLauncherService: Error copying URL to clipboard: $e');
    }
  }

  /// Validate URL format and security
  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);

      // Must have valid scheme
      if (!uri.hasScheme) return false;

      // Only allow HTTP/HTTPS for health content
      if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return false;
      }

      // Must have valid host
      if (!uri.hasAuthority || uri.host.isEmpty) return false;

      return true;
    } catch (e) {
      return false;
    }
  }
}
