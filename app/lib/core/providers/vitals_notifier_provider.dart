/// VitalsNotifier Providers for T2.2.2.6
///
/// Riverpod providers for client-side vitals data subscription.
/// Integrates with wearable live streaming for UI widgets and JITAI engine.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/vitals/vitals_facade.dart';
import '../services/wearable_live_service.dart';
import '../services/wearable_data_repository.dart';
import '../services/vitals/stream_manager/connection_status.dart';
import 'supabase_provider.dart';

/// Provider for VitalsService instance
final vitalsNotifierServiceProvider = Provider<VitalsService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final liveService = WearableLiveService(supabase);
  final repository = WearableDataRepository();
  return VitalsService(liveService: liveService, repository: repository);
});

/// Provider for vitals data stream
final vitalsDataStreamProvider = StreamProvider<VitalsData>((ref) {
  final service = ref.watch(vitalsNotifierServiceProvider);
  return service.vitalsStream;
});

/// Provider for vitals connection status stream
final vitalsConnectionStatusProvider = StreamProvider<VitalsConnectionStatus>((
  ref,
) {
  final service = ref.watch(vitalsNotifierServiceProvider);
  return service.statusStream;
});

/// Provider for vitals subscription state management
final vitalsSubscriptionStateProvider =
    StateNotifierProvider<VitalsSubscriptionNotifier, VitalsSubscriptionState>((
      ref,
    ) {
      final service = ref.watch(vitalsNotifierServiceProvider);
      return VitalsSubscriptionNotifier(service);
    });

/// Provider for current vitals data (latest available)
final currentVitalsProvider = Provider<VitalsData?>((ref) {
  final service = ref.watch(vitalsNotifierServiceProvider);
  return service.currentVitals;
});

/// Provider for JITAI stress detection
final stressIndicatorProvider = Provider<bool>((ref) {
  final service = ref.watch(vitalsNotifierServiceProvider);
  return service.isStressIndicator();
});

/// Provider for average heart rate (for JITAI context)
final averageHeartRateProvider = Provider<double?>((ref) {
  final service = ref.watch(vitalsNotifierServiceProvider);
  return service.getAverageHeartRate();
});

/// Subscription state for UI feedback
class VitalsSubscriptionState {
  final bool isInitialized;
  final bool isActive;
  final String? currentUserId;
  final String? error;

  const VitalsSubscriptionState({
    this.isInitialized = false,
    this.isActive = false,
    this.currentUserId,
    this.error,
  });

  VitalsSubscriptionState copyWith({
    bool? isInitialized,
    bool? isActive,
    String? currentUserId,
    String? error,
  }) {
    return VitalsSubscriptionState(
      isInitialized: isInitialized ?? this.isInitialized,
      isActive: isActive ?? this.isActive,
      currentUserId: currentUserId ?? this.currentUserId,
      error: error ?? this.error,
    );
  }

  bool get canStart => isInitialized && !isActive;
  bool get canStop => isInitialized && isActive;
  bool get hasError => error != null;
}

/// State notifier for vitals subscription management
class VitalsSubscriptionNotifier
    extends StateNotifier<VitalsSubscriptionState> {
  final VitalsService _service;

  VitalsSubscriptionNotifier(this._service)
    : super(const VitalsSubscriptionState());

  /// Initialize the vitals notifier service
  Future<void> initialize() async {
    try {
      state = state.copyWith(error: null);
      final success = await _service.initialize();

      if (success) {
        state = state.copyWith(isInitialized: true);
      } else {
        state = state.copyWith(error: 'Failed to initialize VitalsNotifier');
      }
    } catch (e) {
      state = state.copyWith(error: 'Initialization error: $e');
    }
  }

  /// Start vitals subscription for a user
  Future<bool> startSubscription(String userId) async {
    if (!state.isInitialized) {
      await initialize();
    }

    if (!state.canStart) {
      return false;
    }

    try {
      state = state.copyWith(error: null);
      final success = await _service.startSubscription(userId);

      if (success) {
        state = state.copyWith(isActive: true, currentUserId: userId);
      } else {
        state = state.copyWith(error: 'Failed to start subscription');
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'Subscription error: $e');
      return false;
    }
  }

  /// Stop vitals subscription
  Future<void> stopSubscription() async {
    if (!state.canStop) return;

    try {
      await _service.stopSubscription();
      state = state.copyWith(isActive: false, currentUserId: null, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Stop subscription error: $e');
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
