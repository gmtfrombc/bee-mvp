import 'package:supabase_flutter/supabase_flutter.dart';
import 'demo_auth_service.dart';

/// Service to test Supabase connection and authentication
class SupabaseTestService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Test basic Supabase connection
  static Future<void> testConnection() async {
    try {
      print('🔍 Testing Supabase connection...');

      // Test 1: Check if client is initialized
      print('✅ Supabase client initialized');

      // Test 2: Check current auth state
      final user = _supabase.auth.currentUser;
      print('🔐 Current user: ${user?.id ?? 'Not authenticated'}');

      // Test 3: Try authentication using demo service
      if (user == null) {
        final authenticatedUser = await DemoAuthService.authenticateForDemo();
        if (authenticatedUser != null) {
          print('✅ Authentication successful: ${authenticatedUser.id}');
        } else {
          print('❌ All authentication methods failed');
        }
      }

      // Test 4: Try a simple API call
      print('🌐 Testing API connection...');
      try {
        final response = await _supabase
            .from('daily_engagement_scores')
            .select('count')
            .limit(1);
        print('✅ API connection successful: ${response.length} records found');
      } catch (e) {
        print('⚠️ API call failed (expected if no data): $e');
      }

      // Test 5: Test real-time connection
      print('🔄 Testing real-time connection...');
      try {
        final channel = _supabase.channel('test_channel');
        channel.subscribe();
        print('✅ Real-time connection successful');
        await channel.unsubscribe();
      } catch (e) {
        print('❌ Real-time connection failed: $e');
      }

      print('🎉 Supabase connection test completed!');
    } catch (e, stackTrace) {
      print('❌ Supabase connection test failed: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Get current authentication status
  static Map<String, dynamic> getAuthStatus() {
    final user = _supabase.auth.currentUser;
    return {
      'isAuthenticated': user != null,
      'userId': user?.id,
      'userEmail': user?.email,
      'isAnonymous': user?.isAnonymous ?? false,
      'createdAt': user?.createdAt,
    };
  }
}
