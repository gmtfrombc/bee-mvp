import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../navigation/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

/// Popup menu (⋮) action that allows users to sign-out while inside the
/// onboarding flow. Used by all onboarding pages so QA can return to the
/// registration/login screen during testing.
class OnboardingLogoutButton extends ConsumerWidget {
  const OnboardingLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'logout') {
          // Attempt sign-out via provider (handles state). Also call Supabase
          // directly as a safety net because PKCE sign-out can occasionally
          // require an extra invocation on iOS TestFlight builds.
          await ref.read(authNotifierProvider.notifier).signOut();
          try {
            await Supabase.instance.client.auth.signOut();
          } catch (_) {
            /* ignore */
          }

          if (context.mounted) {
            // Route to the app's LaunchController which decides whether to
            // show Auth or Onboarding based on the fresh auth state.
            context.go(kLaunchRoute);
          }
        }
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem<String>(
              value: 'logout',
              child: Text('Log out'),
            ),
          ],
    );
  }
}
