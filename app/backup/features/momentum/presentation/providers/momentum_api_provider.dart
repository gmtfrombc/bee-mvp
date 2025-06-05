import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/services/momentum_api_service.dart';
import '../../domain/models/momentum_data.dart';
import '../../../../core/theme/app_theme.dart';

/// Provider for the MomentumApiService using the proper Supabase provider
final momentumApiServiceProvider = FutureProvider<MomentumApiService>((
  ref,
) async {
  final supabase = await ref.watch(supabaseProvider.future);
  return MomentumApiService(supabase);
});

/// Enhanced provider for momentum data with improved caching and offline support
final realtimeMomentumProvider = StreamProvider<MomentumData>((ref) async* {
  try {
    final apiService = await ref.watch(momentumApiServiceProvider.future);
    final connectivityStatus = ref.watch(connectivityProvider);

    final initialData = await _initializeAndGetMomentum(apiService, ref);
    yield initialData;

    // Set up real-time updates only if online
    if (connectivityStatus.maybeWhen(
      data: (status) => status == ConnectivityStatus.online,
      orElse: () => false,
    )) {
      yield* _createRealtimeStream(apiService, ref);
    } else {
      // If offline, periodically check for cached updates
      yield* _createOfflineStream(apiService, ref);
    }
  } catch (e) {
    // If everything fails, try to get cached data
    final cachedData = await OfflineCacheService.getCachedMomentumData(
      allowStaleData: true,
    );

    if (cachedData != null) {
      yield cachedData;
      return;
    }

    throw Exception('Failed to get momentum data: $e');
  }
});

/// Initialize momentum data with enhanced caching support
Future<MomentumData> _initializeAndGetMomentum(
  MomentumApiService apiService,
  Ref ref,
) async {
  try {
    // Initialize offline support
    await apiService.initializeOfflineSupport();

    // Get momentum data with offline support
    return await apiService.getMomentumWithOfflineSupport();
  } catch (e) {
    // If everything fails, try to get cached data
    final cachedData = await OfflineCacheService.getCachedMomentumData(
      allowStaleData: true,
    );

    if (cachedData != null) {
      return cachedData;
    }

    throw Exception('Failed to get momentum data: $e');
  }
}

/// Create real-time stream for online mode
Stream<MomentumData> _createRealtimeStream(
  MomentumApiService apiService,
  Ref ref,
) async* {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return;

  // Subscribe to real-time updates
  final _ = apiService.subscribeToMomentumUpdates(
    onUpdate: (data) {
      // Cache the updated data
      OfflineCacheService.cacheMomentumData(data, isHighPriority: true);
    },
    onError: (error) {
      // Queue error for later reporting
      OfflineCacheService.queueError({
        'type': 'realtime_error',
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      });
    },
  );

  // Listen to the channel and yield updates
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    try {
      final momentumData = await apiService.getCurrentMomentum();
      yield momentumData;
    } catch (e) {
      // If network fails, try cached data
      final cachedData = await OfflineCacheService.getCachedMomentumData(
        allowStaleData: true,
      );
      if (cachedData != null) {
        yield cachedData;
      }
    }
  }
}

/// Create offline stream that periodically checks for cached updates
Stream<MomentumData> _createOfflineStream(
  MomentumApiService apiService,
  Ref ref,
) async* {
  // In offline mode, check cached data every minute
  await for (final _ in Stream.periodic(const Duration(minutes: 1))) {
    final cachedData = await OfflineCacheService.getCachedMomentumData(
      allowStaleData: true,
    );

    if (cachedData != null) {
      yield cachedData;
    }
  }
}

/// Provider for cache statistics
final cacheStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await OfflineCacheService.getEnhancedCacheStats();
});

/// Provider for connectivity-aware momentum data
final connectivityAwareMomentumProvider = Provider<AsyncValue<MomentumData>>((
  ref,
) {
  final momentumAsync = ref.watch(realtimeMomentumProvider);

  return momentumAsync.when(
    data: (data) {
      // Add connectivity context to the data
      return AsyncValue.data(data);
    },
    loading: () {
      // While loading, try to show cached data if available
      return const AsyncValue.loading();
    },
    error: (error, stack) {
      // On error, this will be handled by the offline fallback
      return AsyncValue.error(error, stack);
    },
  );
});

/// Provider for offline indicator
final isOfflineModeProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.maybeWhen(
    data: (status) => status == ConnectivityStatus.offline,
    orElse: () => true, // Assume offline if unknown
  );
});

/// Provider for cache health
final cacheHealthProvider = FutureProvider<int>((ref) async {
  final stats = await OfflineCacheService.getEnhancedCacheStats();
  return stats['healthScore'] ?? 0;
});

/// Manual refresh provider
final manualRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final apiService = await ref.read(momentumApiServiceProvider.future);

    // Invalidate cache and force fresh fetch
    await apiService.invalidateMomentumCache(reason: 'Manual refresh');

    // Warm cache with fresh data
    await apiService.warmMomentumCache();

    // Refresh the provider
    ref.invalidate(realtimeMomentumProvider);
  };
});

/// Background sync provider
final backgroundSyncProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final apiService = await ref.read(momentumApiServiceProvider.future);
    await apiService.processPendingMomentumActions();
  };
});

/// Cache management provider
final cacheManagementProvider = Provider<CacheManager>((ref) {
  return CacheManager(ref);
});

/// Cache management helper class
class CacheManager {
  final Ref _ref;

  CacheManager(this._ref);

  /// Clear all cache
  Future<void> clearCache() async {
    await OfflineCacheService.clearAllCache();
    _ref.invalidate(realtimeMomentumProvider);
  }

  /// Enable/disable background sync
  Future<void> setBackgroundSync(bool enabled) async {
    await OfflineCacheService.enableBackgroundSync(enabled);
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return await OfflineCacheService.getEnhancedCacheStats();
  }

  /// Warm cache
  Future<void> warmCache() async {
    final apiService = await _ref.read(momentumApiServiceProvider.future);
    await apiService.warmMomentumCache();
  }

  /// Process pending actions
  Future<void> processPendingActions() async {
    final apiService = await _ref.read(momentumApiServiceProvider.future);
    await apiService.processPendingMomentumActions();
  }
}

/// Provider for legacy compatibility
final legacyMomentumNotifierProvider =
    StateNotifierProvider<LegacyMomentumNotifier, AsyncValue<MomentumData>>((
      ref,
    ) {
      return LegacyMomentumNotifier(ref);
    });

/// Legacy notifier for backward compatibility
class LegacyMomentumNotifier extends StateNotifier<AsyncValue<MomentumData>> {
  final Ref _ref;

  LegacyMomentumNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  void _initialize() async {
    try {
      final apiService = await _ref.read(momentumApiServiceProvider.future);
      final data = await apiService.getMomentumWithOfflineSupport();
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();

    try {
      final apiService = await _ref.read(momentumApiServiceProvider.future);
      await apiService.invalidateMomentumCache(reason: 'Manual refresh');
      final data = await apiService.getCurrentMomentum();
      state = AsyncValue.data(data);
    } catch (e, stack) {
      // Try cached data on error
      final cachedData = await OfflineCacheService.getCachedMomentumData(
        allowStaleData: true,
      );

      if (cachedData != null) {
        state = AsyncValue.data(cachedData);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}

/// Provider for momentum history data
final momentumHistoryProvider =
    FutureProvider.family<List<DailyMomentum>, DateRange>((
      ref,
      dateRange,
    ) async {
      final apiService = await ref.watch(momentumApiServiceProvider.future);
      return await apiService.getMomentumHistory(
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
    });

/// Helper class for date range parameters
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({required this.startDate, required this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

/// Controller provider that provides notifier-like methods for compatibility
final momentumControllerProvider = Provider<MomentumController>((ref) {
  return MomentumController(ref);
});

/// Controller class that provides notifier-like methods
class MomentumController {
  final Ref _ref;

  MomentumController(this._ref);

  /// Refresh momentum data (equivalent to old notifier.refresh())
  Future<void> refresh() async {
    final apiService = await _ref.read(momentumApiServiceProvider.future);
    await apiService.invalidateMomentumCache(reason: 'Manual refresh');
    _ref.invalidate(realtimeMomentumProvider);
  }

  /// Simulate state change (for demo/testing purposes)
  Future<void> simulateStateChange(MomentumState newState) async {
    // For now, we'll invalidate and refresh
    // In a real implementation, this might update backend data
    await refresh();
  }

  /// Calculate momentum score
  Future<void> calculateMomentumScore({String? targetDate}) async {
    final apiService = await _ref.read(momentumApiServiceProvider.future);
    await apiService.calculateMomentumScore(targetDate: targetDate);
    _ref.invalidate(realtimeMomentumProvider);
  }
}

/// Legacy provider for backward compatibility
final momentumProvider = realtimeMomentumProvider;
