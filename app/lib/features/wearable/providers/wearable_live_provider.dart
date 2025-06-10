/// Wearable Live Data Providers
///
/// Riverpod providers for real-time wearable data streaming.
/// Follows existing momentum provider patterns.
/// Part of Epic 2.2 Task T2.2.2.1
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/services/wearable_live_service.dart';
import '../../../core/services/wearable_live_models.dart';

/// Provider for WearableLiveService instance
final wearableLiveServiceProvider = Provider<WearableLiveService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return WearableLiveService(supabase);
});

/// Provider for live wearable data stream
final wearableLiveDataProvider = StreamProvider<List<WearableLiveMessage>>((
  ref,
) {
  final service = ref.watch(wearableLiveServiceProvider);
  return service.messageStream;
});

/// Provider for wearable live streaming state
final wearableLiveStateProvider =
    StateNotifierProvider<WearableLiveStateNotifier, WearableLiveState>((ref) {
      final service = ref.watch(wearableLiveServiceProvider);
      return WearableLiveStateNotifier(service);
    });

/// State for wearable live streaming
class WearableLiveState {
  final bool isStreaming;
  final String? currentUserId;
  final String connectionStatus;
  final bool isWebSocketAvailable;
  final int messageCount;
  final int failureQueueSize;

  const WearableLiveState({
    this.isStreaming = false,
    this.currentUserId,
    this.connectionStatus = 'inactive',
    this.isWebSocketAvailable = true,
    this.messageCount = 0,
    this.failureQueueSize = 0,
  });

  WearableLiveState copyWith({
    bool? isStreaming,
    String? currentUserId,
    String? connectionStatus,
    bool? isWebSocketAvailable,
    int? messageCount,
    int? failureQueueSize,
  }) {
    return WearableLiveState(
      isStreaming: isStreaming ?? this.isStreaming,
      currentUserId: currentUserId ?? this.currentUserId,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isWebSocketAvailable: isWebSocketAvailable ?? this.isWebSocketAvailable,
      messageCount: messageCount ?? this.messageCount,
      failureQueueSize: failureQueueSize ?? this.failureQueueSize,
    );
  }

  /// Whether we're currently using HTTPS fallback
  bool get isUsingHttpsFallback => connectionStatus == 'https_fallback';

  /// Whether there are failed messages queued for retry
  bool get hasFailures => failureQueueSize > 0;
}

/// State notifier for wearable live streaming
class WearableLiveStateNotifier extends StateNotifier<WearableLiveState> {
  final WearableLiveService _service;

  WearableLiveStateNotifier(this._service) : super(const WearableLiveState()) {
    _initializeState();
  }

  void _initializeState() {
    state = WearableLiveState(
      isStreaming: _service.isActive,
      currentUserId: _service.currentUserId,
      connectionStatus: _service.connectionStatus,
      isWebSocketAvailable: _service.isWebSocketAvailable,
      failureQueueSize: _service.failureQueueSize,
    );
  }

  /// Start streaming for a user
  Future<bool> startStreaming(String userId) async {
    final success = await _service.startStreaming(userId);

    state = state.copyWith(
      isStreaming: success,
      currentUserId: success ? userId : null,
      connectionStatus: _service.connectionStatus,
      isWebSocketAvailable: _service.isWebSocketAvailable,
      failureQueueSize: _service.failureQueueSize,
    );

    return success;
  }

  /// Stop streaming
  Future<void> stopStreaming() async {
    await _service.stopStreaming();

    state = state.copyWith(
      isStreaming: false,
      currentUserId: null,
      connectionStatus: _service.connectionStatus,
      isWebSocketAvailable: _service.isWebSocketAvailable,
      messageCount: 0,
      failureQueueSize: 0,
    );
  }

  /// Publish a live message
  Future<void> publishMessage(WearableLiveMessage message) async {
    await _service.publishMessage(message);

    state = state.copyWith(
      messageCount: state.messageCount + 1,
      connectionStatus: _service.connectionStatus,
      isWebSocketAvailable: _service.isWebSocketAvailable,
      failureQueueSize: _service.failureQueueSize,
    );
  }

  /// Update connection status
  void updateConnectionStatus() {
    state = state.copyWith(
      connectionStatus: _service.connectionStatus,
      isWebSocketAvailable: _service.isWebSocketAvailable,
      failureQueueSize: _service.failureQueueSize,
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
