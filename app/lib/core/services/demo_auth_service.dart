import 'package:supabase_flutter/supabase_flutter.dart';

/// Demo authentication service for testing purposes
class DemoAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Demo user credentials
  static const String demoEmail = 'demo@bee-momentum.com';
  static const String demoPassword = 'demo123456';

  /// Try to authenticate using various methods
  static Future<User?> authenticateForDemo() async {
    try {
      // Check if already authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        print('✅ Already authenticated: ${currentUser.id}');
        return currentUser;
      }

      // Try anonymous authentication first
      try {
        print('🔐 Attempting anonymous sign-in...');
        final response = await _supabase.auth.signInAnonymously();
        if (response.user != null) {
          print('✅ Anonymous sign-in successful: ${response.user!.id}');
          return response.user;
        }
      } catch (e) {
        print('⚠️ Anonymous sign-in failed: $e');
      }

      // Try demo user sign-in
      try {
        print('🔐 Attempting demo user sign-in...');
        final response = await _supabase.auth.signInWithPassword(
          email: demoEmail,
          password: demoPassword,
        );
        if (response.user != null) {
          print('✅ Demo user sign-in successful: ${response.user!.id}');
          return response.user;
        }
      } catch (e) {
        print('⚠️ Demo user sign-in failed: $e');

        // Try to create demo user
        try {
          print('🔐 Creating demo user...');
          final signUpResponse = await _supabase.auth.signUp(
            email: demoEmail,
            password: demoPassword,
          );
          if (signUpResponse.user != null) {
            print('✅ Demo user created: ${signUpResponse.user!.id}');
            return signUpResponse.user;
          }
        } catch (signUpError) {
          print('⚠️ Demo user creation failed: $signUpError');
        }
      }

      print('❌ All authentication methods failed');
      return null;
    } catch (e) {
      print('❌ Authentication error: $e');
      return null;
    }
  }

  /// Get current user status
  static Map<String, dynamic> getAuthStatus() {
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
