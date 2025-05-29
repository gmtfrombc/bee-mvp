import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for the BEE app
///
/// SECURITY NOTE: Environment variables are loaded from .env file which should
/// be in .gitignore. Never commit real credentials to source control.
class Environment {
  // Private constructor to prevent instantiation
  Environment._();

  // Flag to track if dotenv has been loaded
  static bool _isLoaded = false;

  /// Initialize the environment configuration
  static Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      await dotenv.load(fileName: '.env');
      _isLoaded = true;
      debugPrint('✅ Environment configuration loaded from .env');
    } catch (e) {
      debugPrint('⚠️ Failed to load .env file: $e');
      debugPrint('   Using default values for development');
      _isLoaded = true; // Mark as loaded to prevent retry
    }
  }

  // Environment type
  static String get environment {
    if (_isLoaded && dotenv.isEveryDefined(['ENVIRONMENT'])) {
      return dotenv.env['ENVIRONMENT'] ?? 'development';
    }
    return 'development';
  }

  // Supabase configuration
  static String get supabaseUrl {
    if (_isLoaded && dotenv.isEveryDefined(['SUPABASE_URL'])) {
      return dotenv.env['SUPABASE_URL'] ?? '';
    }
    return '';
  }

  static String get supabaseAnonKey {
    if (_isLoaded && dotenv.isEveryDefined(['SUPABASE_ANON_KEY'])) {
      return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    }
    return '';
  }

  // Monitoring configuration
  static String get sentryDsn {
    if (_isLoaded && dotenv.isEveryDefined(['SENTRY_DSN'])) {
      return dotenv.env['SENTRY_DSN'] ?? '';
    }
    return '';
  }

  // App version (can be overridden by build system)
  static String get appVersion {
    if (_isLoaded && dotenv.isEveryDefined(['APP_VERSION'])) {
      return dotenv.env['APP_VERSION'] ?? '1.0.0';
    }
    return '1.0.0';
  }

  // User ID for monitoring context (will be set by auth service)
  static String? _userId;
  static String? get userId => _userId;
  static void setUserId(String? id) => _userId = id;

  // Helper getters
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isTest => environment == 'test';

  // Validation method to check if required environment variables are set
  static bool get hasValidConfiguration {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  // Debug information (safe for logging)
  static void printConfig() {
    debugPrint('=== Environment Configuration ===');
    debugPrint('Environment: $environment');
    debugPrint('Supabase URL: ${_maskUrl(supabaseUrl)}');
    debugPrint('Supabase Anon Key: ${_maskKey(supabaseAnonKey)}');
    debugPrint('Valid Config: $hasValidConfiguration');
    debugPrint('Source: .env file');
    debugPrint('================================');
  }

  // Helper method to safely mask URL for logging
  static String _maskUrl(String url) {
    if (url.isEmpty) {
      return '[NOT_SET]';
    }
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://*****.supabase.co';
    } catch (e) {
      return '[INVALID_URL]';
    }
  }

  // Helper method to safely mask key for logging
  static String _maskKey(String key) {
    if (key.isEmpty) {
      return '[NOT_SET]';
    }
    if (key.length > 10) {
      return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
    }
    return '[MASKED]';
  }
}
