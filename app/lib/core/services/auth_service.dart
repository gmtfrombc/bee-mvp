import 'package:supabase_flutter/supabase_flutter.dart';
import 'demo_auth_service.dart';

/// Authentication service for handling user authentication
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign in anonymously for demo purposes
  Future<void> signInAnonymously() async {
    try {
      if (!isAuthenticated) {
        final user = await DemoAuthService.authenticateForDemo();
        if (user == null) {
          throw Exception('Failed to authenticate with any method');
        }
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
