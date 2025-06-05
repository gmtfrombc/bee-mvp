import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'supabase_provider.dart';

/// Provider for the authentication service
final authServiceProvider = FutureProvider<AuthService>((ref) async {
  final supabaseClient = await ref.watch(supabaseProvider.future);
  return AuthService(supabaseClient);
});

/// Provider for current user
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = await ref.watch(authServiceProvider.future);
  return authService.currentUser;
});

/// Provider for authentication state
final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final authService = await ref.watch(authServiceProvider.future);
  yield* authService.authStateChanges;
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user != null;
});

/// Auth notifier for managing authentication actions
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<User?> {
  AuthService? _authService;

  @override
  Future<User?> build() async {
    _authService = await ref.watch(authServiceProvider.future);
    return _authService!.currentUser;
  }

  /// Sign in anonymously for demo purposes
  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      await _authService!.signInAnonymously();
      state = AsyncValue.data(_authService!.currentUser);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService!.signInWithEmail(email: email, password: password);
      state = AsyncValue.data(_authService!.currentUser);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService!.signUpWithEmail(email: email, password: password);
      state = AsyncValue.data(_authService!.currentUser);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService!.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
