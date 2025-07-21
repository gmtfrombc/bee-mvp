import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'supabase_provider.dart';

/// Provider for the authentication service
final authServiceProvider = FutureProvider<AuthService>((ref) async {
  final supabaseClient = await ref.watch(supabaseProvider.future);
  return AuthService(supabaseClient);
});

/// Stream provider that emits the current signed-in [User] and automatically
/// updates whenever Supabase fires an [AuthChangeEvent]. This guarantees that
/// UI listeners (e.g. `LaunchController`) rebuild immediately after e-mail
/// confirmation, sign-in, sign-out, or token refresh events.
// This FutureProvider depends on [authStateProvider] so it automatically
// re-evaluates whenever Supabase emits an auth event (signed in, signed out,
// token refreshed, etc.). That keeps downstream listeners like
// `LaunchController` in sync without changing the provider’s original type,
// preserving test overrides.
final currentUserProvider = FutureProvider<User?>((ref) async {
  // Listen to auth state changes – returned value is ignored but establishes
  // a dependency so this provider refreshes whenever the auth state updates.
  ref.watch(authStateProvider);

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

  /// Sign up with email and password.
  ///
  /// Returns the raw [AuthResponse] so UI code can determine whether the
  /// backend created a session or the user still needs to confirm e-mail.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService!.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      state = AsyncValue.data(_authService!.currentUser);
      return response;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
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

  /// Send password reset email
  Future<void> sendResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService!.sendResetEmail(email: email, redirectTo: redirectTo);
      // keep current state unchanged; typically we may show snackbar in UI layer
      state = AsyncValue.data(_authService!.currentUser);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
