/// Live Vitals Provider for T2.2.1.5-4
///
/// Riverpod providers for Live Vitals developer screen functionality.
/// Debug builds only.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/live_vitals_service.dart';
import '../services/live_vitals_models.dart';

/// Provider for the LiveVitalsService singleton
final liveVitalsServiceProvider = Provider<LiveVitalsService>((ref) {
  return LiveVitalsService();
});

/// Provider for live vitals streaming state
final liveVitalsStreamingStateProvider = StateNotifierProvider<
  LiveVitalsStreamingNotifier,
  LiveVitalsStreamingState
>((ref) {
  final service = ref.watch(liveVitalsServiceProvider);
  return LiveVitalsStreamingNotifier(service);
});

/// Provider for live vitals updates stream
final liveVitalsUpdateStreamProvider = StreamProvider<LiveVitalsUpdate>((ref) {
  final service = ref.watch(liveVitalsServiceProvider);

  // Only provide stream in debug mode
  if (kReleaseMode) {
    return const Stream.empty();
  }

  try {
    return service.vitalsStream;
  } catch (e) {
    debugPrint('❌ Error accessing vitals stream: $e');
    return const Stream.empty();
  }
});

/// Provider for debug statistics
final liveVitalsDebugStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(liveVitalsServiceProvider);
  return service.getDebugStats();
});

/// Streaming state model
class LiveVitalsStreamingState {
  final bool isInitialized;
  final bool isStreaming;
  final String? error;
  final DateTime? lastUpdate;

  const LiveVitalsStreamingState({
    this.isInitialized = false,
    this.isStreaming = false,
    this.error,
    this.lastUpdate,
  });

  LiveVitalsStreamingState copyWith({
    bool? isInitialized,
    bool? isStreaming,
    String? error,
    DateTime? lastUpdate,
  }) {
    return LiveVitalsStreamingState(
      isInitialized: isInitialized ?? this.isInitialized,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error ?? this.error,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  bool get canStart => isInitialized && !isStreaming;
  bool get canStop => isInitialized && isStreaming;
  bool get hasError => error != null;
}

/// State notifier for live vitals streaming
class LiveVitalsStreamingNotifier
    extends StateNotifier<LiveVitalsStreamingState> {
  final LiveVitalsService _service;

  LiveVitalsStreamingNotifier(this._service)
    : super(const LiveVitalsStreamingState());

  /// Initialize the service
  Future<void> initialize() async {
    try {
      state = state.copyWith(error: null);
      final success = await _service.initialize();

      if (success) {
        state = state.copyWith(isInitialized: true);
        debugPrint('✅ LiveVitalsService initialized via provider');
      } else {
        state = state.copyWith(error: 'Failed to initialize LiveVitalsService');
      }
    } catch (e) {
      state = state.copyWith(error: 'Initialization error: $e');
      debugPrint('❌ LiveVitalsService initialization error: $e');
    }
  }

  /// Start streaming
  Future<void> startStreaming() async {
    if (!state.isInitialized) {
      await initialize();
    }

    if (!state.canStart) {
      debugPrint('⚠️ Cannot start streaming: ${state.toString()}');
      return;
    }

    try {
      state = state.copyWith(error: null);
      final success = await _service.startStreaming();

      if (success) {
        state = state.copyWith(isStreaming: true, lastUpdate: DateTime.now());
        debugPrint('🚀 Live vitals streaming started');
      } else {
        state = state.copyWith(error: 'Failed to start streaming');
      }
    } catch (e) {
      state = state.copyWith(error: 'Streaming start error: $e');
      debugPrint('❌ Error starting live vitals streaming: $e');
    }
  }

  /// Stop streaming
  void stopStreaming() {
    if (!state.canStop) {
      debugPrint('⚠️ Cannot stop streaming: not currently active');
      return;
    }

    try {
      _service.stopStreaming();
      state = state.copyWith(isStreaming: false, lastUpdate: DateTime.now());
      debugPrint('⏹️ Live vitals streaming stopped');
    } catch (e) {
      state = state.copyWith(error: 'Error stopping streaming: $e');
      debugPrint('❌ Error stopping live vitals streaming: $e');
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
