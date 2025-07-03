import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/services/responsive_service.dart';

/// Banner prompting the user to verify their email address.
///
/// Displays only when the current user exists and their email is *not* yet
/// confirmed (`user.emailConfirmedAt == null`). The widget rebuilds
/// automatically whenever the auth state changes, disappearing once the email
/// becomes verified.
class EmailVerificationBanner extends ConsumerWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        final user = authState.session?.user;
        final needsVerification = user != null && user.emailConfirmedAt == null;
        if (!needsVerification) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveService.getResponsiveSpacing(context),
            vertical: ResponsiveService.getSmallSpacing(context),
          ),
          color: AppTheme.momentumCare,
          child: Row(
            children: [
              Icon(
                Icons.email,
                color: AppTheme.getSurfacePrimary(context),
                size: 16,
              ),
              SizedBox(width: ResponsiveService.getSmallSpacing(context)),
              Expanded(
                child: Text(
                  'Please verify your email address to secure your account.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.getSurfacePrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
