import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

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
import '../../../core/mixins/permission_auto_refresh_mixin.dart';

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
    extends ConsumerState<WearableDashboardScreen>
    with PermissionAutoRefreshMixin<WearableDashboardScreen> {
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

    final bool showCta =
        permissionsState.status != HealthPermissionStatus.authorized;

    return Scaffold(
      appBar: AppBar(title: const Text('Health Stats')),
      body:
          showCta
              ? _PermissionCta(permissionsState: permissionsState)
              : _buildContent(context, ref, permissionsState),
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
    final bool isDenied =
        permissionsState.status == HealthPermissionStatus.denied;
    final bool isNotDetermined =
        permissionsState.status == HealthPermissionStatus.notDetermined;

    // On iOS a denial can be "permanent" when toggled off in Settings. We
    // deep-link the user directly to the Health app sources list in that case.
    final bool needsSettingsLink = Platform.isIOS && isDenied;

    final String description;
    final String buttonLabel;
    VoidCallback onPressed;

    if (isNotDetermined) {
      description =
          'To view your health data, please grant the required permissions.';
      buttonLabel = 'Grant Apple Health Access';
      onPressed = () {
        // Open permissions flow inside bottom-sheet modal
        showHealthPermissionsModal(context);
      };
    } else if (needsSettingsLink) {
      description =
          'Apple Health access is turned off. Please enable it in Settings to resume data syncing.';
      buttonLabel = 'Open Health Settings';
      onPressed = () async {
        const url = 'x-apple-health://sources';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          // Fallback to generic app settings
          const settingsUrl = 'app-settings:';
          if (await canLaunchUrl(Uri.parse(settingsUrl))) {
            await launchUrl(Uri.parse(settingsUrl));
          }
        }
      };
    } else {
      // Android denial case or unknown; fall back to modal / settings
      description =
          'Health access is currently blocked. Please enable permissions to see your data.';
      buttonLabel = Platform.isAndroid ? 'Grant Permissions' : 'Open Settings';
      onPressed = () {
        showHealthPermissionsModal(context);
      };
    }

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
              onPressed: onPressed,
              icon: const Icon(Icons.lock_open),
              label: Text(buttonLabel),
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
