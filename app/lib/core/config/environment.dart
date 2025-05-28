/// Environment configuration for the BEE app
class Environment {
  // Environment type
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Supabase configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://okptsizouuanwnpqjfui.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9rcHRzaXpvdXVhbnducHFqZnVpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgyOTI1NTEsImV4cCI6MjA2Mzg2ODU1MX0.8BX_qzXATqkN25HSuxgmAhQuIIStoJzy7Mc74EC-pDI',
  );

  // Helper getters
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isTest => environment == 'test';

  // Debug information
  static void printConfig() {
    print('=== Environment Configuration ===');
    print('Environment: $environment');
    print('Supabase URL: $supabaseUrl');
    print('Supabase Anon Key: ${supabaseAnonKey.substring(0, 20)}...');
    print('================================');
  }
}
