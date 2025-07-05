import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/profile.dart';
import 'demo_auth_service.dart';

/// Authentication service for handling user authentication
class AuthService {
  final SupabaseClient _supabase;
  late final DemoAuthService _demoAuthService;

  /// Constructor that accepts a SupabaseClient instance
  AuthService(this._supabase) {
    _demoAuthService = DemoAuthService(_supabase);
  }

  /// Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign in anonymously for demo purposes
  Future<void> signInAnonymously() async {
    try {
      if (!isAuthenticated) {
        final user = await _demoAuthService.authenticateForDemo();
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
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'full_name': name} : null,
      emailRedirectTo:
          'https://storage.googleapis.com/bee-auth-redirect/index.html',
    );

    // Debug: surface whether Supabase returned a session immediately.
    debugPrint('🔐 signUp result – session: ${response.session}');
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

  /// Send password-reset email
  Future<void> sendResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Fetch the Supabase profile for a given user ID.
  Future<Profile?> fetchProfile(String uid) async {
    try {
      final data =
          await _supabase
              .from('profiles')
              .select('*')
              .eq('id', uid)
              .maybeSingle();

      if (data == null) return null;
      return Profile.fromMap(data);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Mark onboarding as complete for the current user.
  /// Retries twice with exponential backoff on network failure.
  Future<void> completeOnboarding() async {
    final uid = currentUser?.id;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    const maxAttempts = 3;
    int attempt = 0;
    int delayMs = 500;

    while (true) {
      try {
        await _supabase.from('profiles').upsert({
          'id': uid,
          'onboarding_complete': true,
        }, onConflict: 'id');
        return;
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          throw Exception(
            'Failed to upsert onboarding flag after $attempt attempts: $e',
          );
        }
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
      }
    }
  }
}
