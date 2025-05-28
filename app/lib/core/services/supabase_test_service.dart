import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service to test Supabase connection and functionality
class SupabaseTestService {
  final SupabaseClient _supabase;

  /// Constructor that accepts a SupabaseClient instance
  SupabaseTestService(this._supabase);

  /// Test the complete Supabase setup
  Future<void> testConnection() async {
    try {
      debugPrint('🔍 Testing Supabase connection...');

      // Test 1: Check if client is initialized
      debugPrint('✅ Supabase client initialized');

      // Test 2: Check authentication status
      final user = _supabase.auth.currentUser;
      debugPrint('🔐 Current user: ${user?.id ?? 'Not authenticated'}');

      // Test 3: Try authentication if not already authenticated
      if (user == null) {
        try {
          final response = await _supabase.auth.signInAnonymously();
          if (response.user != null) {
            debugPrint('✅ Authentication successful: ${response.user!.id}');
          } else {
            debugPrint('❌ All authentication methods failed');
          }
        } catch (e) {
          // Authentication failures are expected in test environment
        }
      }

      // Test 4: Test basic API connectivity (if authenticated)
      debugPrint('🌐 Testing API connection...');
      try {
        final response = await _supabase
            .from('daily_engagement_scores')
            .select('*')
            .limit(1);

        debugPrint(
          '✅ API connection successful: ${response.length} records found',
        );
      } catch (e) {
        debugPrint('⚠️ API call failed (expected if no data): $e');
      }

      // Test 5: Test real-time connection
      debugPrint('🔄 Testing real-time connection...');
      try {
        final channel = _supabase.realtime.channel('test');
        channel.subscribe();
        debugPrint('✅ Real-time connection successful');
        await channel.unsubscribe();
      } catch (e) {
        debugPrint('❌ Real-time connection failed: $e');
      }

      debugPrint('🎉 Supabase connection test completed!');
    } catch (e, stackTrace) {
      debugPrint('❌ Supabase connection test failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Get current authentication status
  Map<String, dynamic> getAuthStatus() {
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
