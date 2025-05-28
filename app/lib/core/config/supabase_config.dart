/// Supabase configuration for BEE Momentum Meter
class SupabaseConfig {
  // TODO: Replace with actual Supabase URL from environment variables
  static const String url = 'https://your-project.supabase.co';

  // TODO: Replace with actual Supabase anon key from environment variables
  static const String anonKey = 'your-anon-key-here';

  // API endpoints for momentum meter
  static const String momentumEndpoint = '/rest/v1/momentum';
  static const String engagementEndpoint = '/rest/v1/daily_engagement_scores';
  static const String notificationsEndpoint = '/rest/v1/momentum_notifications';
}
