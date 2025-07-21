import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed explicit mail-app launcher for a simpler, more robust flow.

import '../../../core/services/responsive_service.dart';
import '../../../core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shown immediately after a user signs up but before they have confirmed
/// their email. Listens to Supabase auth events and navigates once the user
/// returns authenticated via deep-link.
class ConfirmationPendingPage extends ConsumerStatefulWidget {
  const ConfirmationPendingPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ConfirmationPendingPage> createState() =>
      _ConfirmationPendingPageState();
}

class _ConfirmationPendingPageState
    extends ConsumerState<ConfirmationPendingPage> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    // Listen to auth-state changes and act once we receive a proper session.
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((state) async {
        // Safe UTF-8 log for every change.
        debugPrint(
          '🔔 authStateListener – event: ${state.event}, '
          'session: ${state.session}',
        );

        if (_navigated) return;

        final signedIn =
            state.event == AuthChangeEvent.signedIn && state.session != null;
        if (signedIn) {
          // Small delay to let Supabase persist the session so
          // currentUser isn’t null when LaunchController rebuilds.
          await Future.delayed(const Duration(milliseconds: 100));

          if (!context.mounted) return;
          _navigated = true;
          context.go('/launch');
        }
      });
    });

    final spacing = ResponsiveService.getMediumSpacing(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm your email')),
      body: Padding(
        padding: ResponsiveService.getMediumPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "We've sent a confirmation link to\n${widget.email}.\n\n"
              'Please open your email and tap the link to verify your account.\n'
              'After confirming, you’ll be returned to the app automatically.',
            ),
            SizedBox(height: spacing * 2),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
