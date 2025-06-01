import 'environment.dart';

/// Supabase configuration for BEE Momentum Meter
class SupabaseConfig {
  // Supabase project URL and keys from environment
  static String get url => Environment.supabaseUrl;
  static String get anonKey => Environment.supabaseAnonKey;

  // API endpoints for momentum meter
  static const String momentumEndpoint = '/rest/v1/daily_engagement_scores';
  static const String engagementEndpoint = '/rest/v1/engagement_events';
  static const String notificationsEndpoint = '/rest/v1/momentum_notifications';

  // Edge Functions endpoints
  static const String momentumCalculatorFunction =
      '/functions/v1/momentum-score-calculator';
}
