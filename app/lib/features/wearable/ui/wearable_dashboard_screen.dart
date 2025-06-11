import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/providers/vitals_notifier_provider.dart';
import '../../../core/services/wearable_data_models.dart';
import 'health_permissions_state.dart';
import 'health_permissions_modal.dart';
import 'tiles/steps_tile.dart';
import 'tiles/sleep_tile.dart';
import 'tiles/heart_rate_tile.dart';
import '../../../core/providers/supabase_provider.dart';

/// Wearable Dashboard Screen – shows live health metric tiles with
/// empty/error/loading states and pull-to-refresh. If permissions are
/// missing/blocked it surfaces a clear call-to-action so users can grant
/// access.
class WearableDashboardScreen extends ConsumerWidget {
  const WearableDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(healthPermissionsProvider);

    // Lazy-init the permission state so we always have a fresh status when the
    // screen is first shown. This avoids requiring callers to initialize the
    // provider explicitly.
    if (!permissionsState.isLoading &&
        permissionsState.status == HealthPermissionStatus.notDetermined) {
      Future.microtask(() {
        ref.read(healthPermissionsProvider.notifier).initialize();
      });
    }

    // Top-level RefreshIndicator to allow manual reloads.
    return RefreshIndicator(
      onRefresh: () async {
        // Simply invalidate the vitals stream & permission cache so new data
        // gets fetched. Riverpod will recreate providers.
        ref.invalidate(vitalsDataStreamProvider);
        ref.invalidate(healthPermissionsProvider);
        // Give the UI a tiny delay so the indicator has time to show.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveService.getResponsivePadding(context),
              child: _buildContent(context, ref, permissionsState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HealthPermissionsState permissionsState,
  ) {
    if (permissionsState.isLoading) {
      return Center(
        child: Padding(
          padding: ResponsiveService.getLargePadding(context),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    // Show CTA when permissions are not yet granted or have been denied.
    if (permissionsState.status != HealthPermissionStatus.authorized) {
      return _PermissionCta(permissionsState: permissionsState);
    }

    // Permissions granted – ensure vitals subscription is active.
    final subscriptionState = ref.watch(vitalsSubscriptionStateProvider);
    if (!subscriptionState.isActive) {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        Future.microtask(() {
          ref
              .read(vitalsSubscriptionStateProvider.notifier)
              .startSubscription(userId);
        });
      }
    }

    // Permissions granted – render tiles.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepsTile(),
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        const SleepTile(),
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        const HeartRateTile(),
        SizedBox(height: ResponsiveService.getLargeSpacing(context)),
      ],
    );
  }
}

/// Permission Call-To-Action shown when heath data permissions are missing.
class _PermissionCta extends ConsumerWidget {
  const _PermissionCta({required this.permissionsState});

  final HealthPermissionsState permissionsState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDenied = permissionsState.status == HealthPermissionStatus.denied;

    final description =
        isDenied
            ? 'Health access is currently blocked. Please enable permissions to see your data.'
            : 'To view your health data, please grant the required permissions.';

    return Center(
      child: Semantics(
        label: 'Permissions required',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety,
              size: ResponsiveService.getIconSize(context, baseSize: 64),
              color: Theme.of(context).colorScheme.primary,
              semanticLabel: '',
            ),
            SizedBox(height: ResponsiveService.getMediumSpacing(context)),
            Padding(
              padding: ResponsiveService.getMediumPadding(context),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Capture container to allow provider operations even if this
                // widget is disposed before the modal completes.
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );

                await showHealthPermissionsModal(context);

                // Invalidate outside widget lifecycle to avoid "ref disposed"
                // exceptions when the CTA is replaced by tiles.
                container.invalidate(healthPermissionsProvider);
              },
              icon: const Icon(Icons.lock_open),
              label: Text(isDenied ? 'Open Settings' : 'Grant Permissions'),
            ),
          ],
        ),
      ),
    );
  }
}
