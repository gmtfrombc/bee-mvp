import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/providers/vitals_notifier_provider.dart';
import '../../../core/services/wearable_data_models.dart';
import 'health_permissions_state.dart';
import 'health_permissions_modal.dart';
import 'tiles/steps_tile.dart';
import 'tiles/sleep_tile.dart';
import 'tiles/heart_rate_tile.dart';
import 'tiles/active_energy_tile.dart';
import 'tiles/weight_tile.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/providers/analytics_provider.dart';

/// Wearable Dashboard Screen – shows live health metric tiles with
/// empty/error/loading states and pull-to-refresh. If permissions are
/// missing/blocked it surfaces a clear call-to-action so users can grant
/// access.
class WearableDashboardScreen extends ConsumerStatefulWidget {
  const WearableDashboardScreen({super.key});

  @override
  ConsumerState<WearableDashboardScreen> createState() =>
      _WearableDashboardScreenState();
}

class _WearableDashboardScreenState
    extends ConsumerState<WearableDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize permissions once when the screen is first created.
    Future.microtask(() {
      ref.read(healthPermissionsProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final permissionsState = ref.watch(healthPermissionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Health Stats')),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger a manual refresh via the VitalsNotifier so that we fetch a
          // wider data window and guarantee fresh values from HealthKit/Connect.
          await ref.read(vitalsNotifierServiceProvider).refreshNow();

          // Allow the RefreshIndicator widget to remain visible briefly so
          // users see feedback that their gesture succeeded.
          await Future<void>.delayed(const Duration(milliseconds: 300));

          // Emit analytics event for manual refresh
          ref.read(analyticsServiceProvider).logEvent('vitals_manual_refresh');

          if (!context.mounted) return;
          // Provide user feedback once refresh completes.
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Health stats updated')));
        },
        child: _buildContent(context, ref, permissionsState),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HealthPermissionsState permissionsState,
  ) {
    if (permissionsState.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Center(
            child: Padding(
              padding: ResponsiveService.getLargePadding(context),
              child: const CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    // Show CTA when permissions are not yet granted or have been denied.
    if (permissionsState.status != HealthPermissionStatus.authorized) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveService.getResponsivePadding(context).left,
          vertical: ResponsiveService.getSmallSpacing(context),
        ),
        children: [_PermissionCta(permissionsState: permissionsState)],
      );
    }

    // Ensure vitals subscription is active.
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

    // ---------- Reorderable tiles ----------
    // Keep order in state so drag-and-drop updates instantly.
    final order = ref.watch(_tileOrderProvider);

    return ReorderableListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: ResponsiveService.getResponsivePadding(context).left,
        right: ResponsiveService.getResponsivePadding(context).right,
        bottom: ResponsiveService.getResponsivePadding(context).bottom,
        top: ResponsiveService.getSmallSpacing(context),
      ),
      itemCount: order.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(_tileOrderProvider.notifier).reorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final type = order[index];
        return _buildTileItem(context, type, index);
      },
    );
  }

  Widget _buildTileItem(BuildContext context, _TileType type, int index) {
    Widget tile;
    switch (type) {
      case _TileType.steps:
        tile = const StepsTile();
        break;
      case _TileType.energy:
        tile = const ActiveEnergyTile();
        break;
      case _TileType.sleep:
        tile = const SleepTile();
        break;
      case _TileType.heartRate:
        tile = const HeartRateTile();
        break;
      case _TileType.weight:
        tile = const WeightTile();
        break;
    }

    return Padding(
      key: ValueKey(type.name),
      padding: EdgeInsets.only(
        bottom: ResponsiveService.getTinySpacing(context),
      ),
      child: Stack(
        children: [
          tile,
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
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
                // Re-run initialization to refresh permission status.
                container.read(healthPermissionsProvider.notifier).initialize();
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

// Internal representation of each tile so we can reorder via drag & drop
enum _TileType { steps, energy, sleep, heartRate, weight }

// Holds the current order of tiles for the session. Persistence could be added
// later with SharedPreferences if desired.
final _tileOrderProvider =
    StateNotifierProvider<_TileOrderNotifier, List<_TileType>>((ref) {
      return _TileOrderNotifier();
    });

class _TileOrderNotifier extends StateNotifier<List<_TileType>> {
  static const _prefsKey = 'tile_order_v1';

  _TileOrderNotifier()
    : super(const [
        _TileType.steps,
        _TileType.energy,
        _TileType.sleep,
        _TileType.heartRate,
        _TileType.weight,
      ]) {
    _loadPersistedOrder();
  }

  Future<void> _loadPersistedOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      final parsed =
          saved.map((name) {
            // Handle migration: older versions used 'hrv'
            if (name == 'hrv') return _TileType.weight;
            return _TileType.values.firstWhere(
              (t) => t.name == name,
              orElse: () => _TileType.steps,
            );
          }).toList();
      // Only update if same length (defensive against app updates)
      if (parsed.length == 5) state = parsed;
    }
  }

  void _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state.map((e) => e.name).toList());
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final updated = [...state];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = updated;
    _persist();
  }
}
