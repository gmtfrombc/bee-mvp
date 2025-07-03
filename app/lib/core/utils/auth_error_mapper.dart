import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps Supabase authentication exceptions to user-friendly copy that can be
/// surfaced via SnackBar.
String mapAuthError(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();

    if (msg.contains('already registered') || msg.contains('exists')) {
      return 'Account already exists';
    }

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password') ||
        msg.contains('invalid credentials')) {
      return 'Incorrect email or password';
    }

    // Add more mappings here as needed.
    return error.message;
  }

  // Fallback for unexpected errors.
  return 'Something went wrong. Please try again.';
}
