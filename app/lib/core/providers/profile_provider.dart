import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import 'auth_provider.dart';

/// Provides the user's [Profile] fetched from Supabase.
///
/// Depends on [authServiceProvider] for making the network request and on
/// [currentUserProvider] to obtain the authenticated user ID.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final authService = await ref.watch(authServiceProvider.future);
  final user = authService.currentUser;
  if (user == null) return null;
  return await authService.fetchProfile(user.id);
});

/// Convenience provider that exposes the `onboardingComplete` flag as a bool.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  return profile?.onboardingComplete ?? false;
});
