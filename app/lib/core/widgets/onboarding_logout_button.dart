import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../navigation/routes.dart';
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
          // Sign out via AuthNotifier so state providers are refreshed.
          await ref.read(authNotifierProvider.notifier).signOut();
          if (context.mounted) {
            context.go(kAuthRoute);
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
