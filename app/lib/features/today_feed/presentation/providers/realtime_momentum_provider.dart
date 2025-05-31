import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/realtime_momentum_update_service.dart';
import '../../data/services/today_feed_momentum_award_service.dart';

/// Provider for the RealtimeMomentumUpdateService
///
/// Implements T1.3.4.5: Real-time momentum meter updates
///
/// This provider manages the lifecycle of the real-time momentum update service
/// and provides access to it throughout the Today Feed feature
final realtimeMomentumUpdateServiceProvider =
    Provider<RealtimeMomentumUpdateService>((ref) {
      final service = RealtimeMomentumUpdateService();

      // Initialize with the current provider container
      service.initialize(ref.container);

      // Dispose when the provider is disposed
      ref.onDispose(() {
        service.dispose();
      });

      return service;
    });

/// Provider for the TodayFeedMomentumAwardService with real-time updates
///
/// Updated version that includes real-time momentum updates functionality
final todayFeedMomentumAwardServiceProvider =
    Provider<TodayFeedMomentumAwardService>((ref) {
      final service = TodayFeedMomentumAwardService();

      // Initialize with the current provider container for real-time updates
      service.initialize(ref.container);

      // Dispose when the provider is disposed
      ref.onDispose(() {
        service.dispose();
      });

      return service;
    });

/// Provider for real-time momentum update statistics
final realtimeMomentumStatsProvider = FutureProvider<RealtimeUpdateStatistics>((
  ref,
) async {
  final service = ref.watch(realtimeMomentumUpdateServiceProvider);
  return await service.getUpdateStatistics();
});

/// Provider for checking if real-time momentum updates are ready
final realtimeMomentumReadyProvider = Provider<bool>((ref) {
  final service = ref.watch(realtimeMomentumUpdateServiceProvider);
  return service.isReady;
});

/// Provider for triggering momentum updates
final momentumUpdateTriggerProvider = Provider<
  Future<RealtimeUpdateResult> Function({
    required String userId,
    required int pointsAwarded,
    required String interactionId,
    bool enableOptimisticUpdate,
  })
>((ref) {
  final service = ref.watch(realtimeMomentumUpdateServiceProvider);

  return ({
    required String userId,
    required int pointsAwarded,
    required String interactionId,
    bool enableOptimisticUpdate = true,
  }) async {
    return await service.triggerMomentumUpdate(
      userId: userId,
      pointsAwarded: pointsAwarded,
      interactionId: interactionId,
      enableOptimisticUpdate: enableOptimisticUpdate,
    );
  };
});
