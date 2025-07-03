import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_session_service.dart';

/// Provides a shared instance of [AuthSessionService] across the app.
///
/// The provider creates the service lazily on first use and keeps a single
/// instance alive for the entire lifetime of the application.
final authSessionServiceProvider = Provider<AuthSessionService>((ref) {
  // Using a single instance avoids duplicate listeners to Supabase events.
  return AuthSessionService();
});
