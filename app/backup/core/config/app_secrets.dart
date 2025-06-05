// Environment-based secrets management for BEE Momentum Meter
// This file uses the ENVied package approach for secure secret management
// See: https://pub.dev/packages/envied

import 'package:flutter/foundation.dart';

/// Centralized secrets management for the BEE app
/// Uses --dart-define for secure injection during build time
class AppSecrets {
  /// Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder-key',
  );

  /// Development environment flag
  static const String environment = String.fromEnvironment(
    'FLUTTER_ENV',
    defaultValue: 'development',
  );

  /// Check if running in development mode
  static bool get isDevelopment => environment == 'development' || kDebugMode;

  /// Check if secrets are properly configured
  static bool get hasValidSecrets =>
      supabaseUrl != 'https://placeholder.supabase.co' &&
      supabaseAnonKey != 'placeholder-key' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  /// Get configuration status for debugging
  static Map<String, dynamic> get configStatus => {
    'environment': environment,
    'hasValidSecrets': hasValidSecrets,
    'supabaseConfigured': supabaseUrl != 'https://placeholder.supabase.co',
    'isDevelopment': isDevelopment,
  };

  /// Log configuration status (development only)
  static void logStatus() {
    if (kDebugMode) {
      debugPrint('🔧 App Secrets Configuration:');
      configStatus.forEach((key, value) {
        debugPrint('   $key: $value');
      });

      if (!hasValidSecrets) {
        debugPrint('⚠️  Missing secrets! Use:');
        debugPrint(
          '   flutter run --dart-define="SUPABASE_URL=your_url" --dart-define="SUPABASE_ANON_KEY=your_key"',
        );
      }
    }
  }
}
