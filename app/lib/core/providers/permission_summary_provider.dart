import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/permission_summary.dart';
import 'health_permission_provider.dart' show healthPermissionManagerProvider;

/// Emits up-to-date [PermissionSummary] objects.
final permissionSummaryProvider = StreamProvider<PermissionSummary>((ref) {
  final mgr = ref.watch(healthPermissionManagerProvider);

  // Helper to convert cache → summary
  PermissionSummary build() => PermissionSummary.fromCache(mgr.permissionCache);

  // If manager not yet initialised we bootstrap it once.
  Future<void> ensureInit() async {
    if (!mgr.isInitialized) {
      await mgr.initialize();
    }
  }

  // Emit initial value synchronously once init done, then follow deltaStream.
  final controller = StreamController<PermissionSummary>();

  ensureInit().then((_) async {
    // Perform an immediate fresh permission check to avoid emitting stale cache
    try {
      await mgr.checkPermissions(useCache: false);

      // Success – surface explicit log for QA diagnostics
      // ignore: avoid_print
      print('permissionSummaryProvider: fresh permission check completed');
    } catch (e) {
      // Non-fatal: log and continue with cached values if fresh check fails
      // ignore: avoid_print
      print('permissionSummaryProvider: fresh permission check failed – $e');
    }

    controller.add(build());

    // Forward subsequent deltas
    mgr.deltaStream.listen((_) => controller.add(build()));
  });

  return controller.stream;
});
