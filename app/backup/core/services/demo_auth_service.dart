import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Demo authentication service for testing purposes
class DemoAuthService {
  final SupabaseClient _supabase;

  /// Constructor that accepts a SupabaseClient instance
  DemoAuthService(this._supabase);

  // Demo user credentials
  static const String demoEmail = 'demo@bee-momentum.com';
  static const String demoPassword = 'demo123456';

  /// Try to authenticate using various methods
  Future<User?> authenticateForDemo() async {
    try {
      // Check if already authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        debugPrint('✅ Already authenticated: ${currentUser.id}');
        return currentUser;
      }

      // Try anonymous authentication first
      try {
        debugPrint('🔐 Attempting anonymous sign-in...');
        final response = await _supabase.auth.signInAnonymously();
        if (response.user != null) {
          debugPrint('✅ Anonymous sign-in successful: ${response.user!.id}');
          return response.user;
        }
      } catch (e) {
        debugPrint('⚠️ Anonymous sign-in failed: $e');
      }

      // Try demo user sign-in
      try {
        debugPrint('🔐 Attempting demo user sign-in...');
        final response = await _supabase.auth.signInWithPassword(
          email: demoEmail,
          password: demoPassword,
        );
        if (response.user != null) {
          debugPrint('✅ Demo user sign-in successful: ${response.user!.id}');
          return response.user;
        }
      } catch (e) {
        debugPrint('⚠️ Demo user sign-in failed: $e');

        // Try to create demo user
        try {
          debugPrint('🔐 Creating demo user...');
          final signUpResponse = await _supabase.auth.signUp(
            email: demoEmail,
            password: demoPassword,
          );
          if (signUpResponse.user != null) {
            debugPrint('✅ Demo user created: ${signUpResponse.user!.id}');
            return signUpResponse.user;
          }
        } catch (signUpError) {
          debugPrint('⚠️ Demo user creation failed: $signUpError');
        }
      }

      debugPrint('❌ All authentication methods failed');
      return null;
    } catch (e) {
      debugPrint('❌ Authentication error: $e');
      return null;
    }
  }

  /// Get current user status
  Map<String, dynamic> getAuthStatus() {
    final user = _supabase.auth.currentUser;
    return {
      'isAuthenticated': user != null,
      'userId': user?.id,
      'email': user?.email,
      'isAnonymous': user?.isAnonymous ?? false,
      'authMethod':
          user?.isAnonymous == true
              ? 'anonymous'
              : user?.email == demoEmail
              ? 'demo_user'
              : 'other',
    };
  }
}
