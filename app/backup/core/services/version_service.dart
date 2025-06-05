import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for managing app version information
class VersionService {
  static PackageInfo? _packageInfo;
  static bool _initialized = false;

  /// Initialize the version service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _initialized = true;
      debugPrint('✅ Version Service initialized: ${_packageInfo?.version}');
    } catch (e) {
      debugPrint('❌ Failed to initialize version service: $e');
      _initialized = true; // Don't block app startup
    }
  }

  /// Get the app version (e.g., "1.0.0")
  static String get appVersion {
    return _packageInfo?.version ?? '1.0.0';
  }

  /// Get the build number (e.g., "1")
  static String get buildNumber {
    return _packageInfo?.buildNumber ?? '1';
  }

  /// Get the full version string (e.g., "1.0.0+1")
  static String get fullVersion {
    return '$appVersion+$buildNumber';
  }

  /// Get the app name
  static String get appName {
    return _packageInfo?.appName ?? 'BEE Momentum Meter';
  }

  /// Get the package name (bundle identifier)
  static String get packageName {
    return _packageInfo?.packageName ?? 'com.momentumhealth.beemvp';
  }

  /// Get version info for analytics and debugging
  static Map<String, String> get versionInfo {
    return {
      'app_version': appVersion,
      'build_number': buildNumber,
      'full_version': fullVersion,
      'app_name': appName,
      'package_name': packageName,
    };
  }

  /// Check if version service is properly initialized
  static bool get isInitialized => _initialized && _packageInfo != null;
}
