import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Provider for the authentication service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for current user
final currentUserProvider = StateProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

/// Provider for authentication state
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Auth notifier for managing authentication actions
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return AuthNotifier(authService, ref);
    });

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref)
    : super(AsyncValue.data(_authService.currentUser)) {
    // Listen to auth state changes
    _authService.authStateChanges.listen((authState) {
      state = AsyncValue.data(authState.session?.user);
      // Update the current user provider
      _ref.read(currentUserProvider.notifier).state = authState.session?.user;
    });
  }

  /// Sign in anonymously for demo purposes
  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInAnonymously();
      state = AsyncValue.data(_authService.currentUser);
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
      await _authService.signInWithEmail(email: email, password: password);
      state = AsyncValue.data(_authService.currentUser);
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
      await _authService.signUpWithEmail(email: email, password: password);
      state = AsyncValue.data(_authService.currentUser);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
