import 'dart:async';

import 'package:app_links/app_links.dart';

final _appLinks = AppLinks();

/// Centralised deep-link utilities used across the app.
///
/// Exposes:
///   • [stream]  – hot link events when the app is already running.
///   • [initialUri] – cold-start URI when the app is launched via a link.
class DeepLinkService {
  DeepLinkService._();

  /// Continuous stream of incoming URIs.
  static Stream<Uri> get stream => _appLinks.uriLinkStream
      .where((Uri? uri) => uri != null)
      .map((uri) => uri);

  /// Retrieves the URI that launched the app, if any.
  static Future<Uri?> initialUri() async {
    try {
      return await _appLinks.getInitialAppLink();
    } on FormatException {
      // Malformed URI – ignore.
      return null;
    }
  }

  /// Checks whether the uri represents a Supabase password-reset link.
  static bool isPasswordReset(Uri uri) {
    return (uri.queryParameters['type'] == 'recovery' &&
        uri.queryParameters.containsKey('access_token'));
  }

  /// Extracts the access token from a password-reset uri.
  static String? extractAccessToken(Uri uri) =>
      uri.queryParameters['access_token'];
}
