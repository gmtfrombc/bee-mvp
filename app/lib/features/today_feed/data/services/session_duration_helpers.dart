part of 'session_duration_tracking_service.dart';

/// Active session tracker for real-time duration monitoring
class _ActiveSessionTracker {
  final String sessionId;
  final String userId;
  final int contentId;
  final DateTime startTime;
  final TodayFeedContent content;

  DateTime lastActivity;
  final List<DateTime> activitySamples = [];
  Timer? _samplingTimer;
  Timer? _timeoutTimer;

  _ActiveSessionTracker({
    required this.sessionId,
    required this.userId,
    required this.contentId,
    required this.startTime,
    required this.content,
  }) : lastActivity = startTime;

  void startSampling() {
    _samplingTimer?.cancel();
    _samplingTimer = Timer.periodic(
      SessionTrackingConfig.samplingInterval,
      (_) => _recordActivitySample(),
    );
    _resetTimeoutTimer();
  }

  void _recordActivitySample() {
    final now = DateTime.now();
    activitySamples.add(now);
    lastActivity = now;
    _resetTimeoutTimer();
  }

  void _resetTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(
      SessionTrackingConfig.sessionTimeout,
      _onSessionTimeout,
    );
  }

  void _onSessionTimeout() {
    debugPrint('⏰ Session timeout for session $sessionId');
  }

  void recordInteraction() {
    final now = DateTime.now();
    lastActivity = now;
    activitySamples.add(now);
    _resetTimeoutTimer();
  }

  ReadingSession finalize({Map<String, dynamic>? additionalMetadata}) {
    _samplingTimer?.cancel();
    _timeoutTimer?.cancel();

    final endTime = lastActivity;
    return ReadingSession.fromTrackingData(
      sessionId: sessionId,
      userId: userId,
      contentId: contentId,
      startTime: startTime,
      endTime: endTime,
      activitySamples: activitySamples,
      content: content,
      additionalMetadata: additionalMetadata,
    );
  }

  void dispose() {
    _samplingTimer?.cancel();
    _timeoutTimer?.cancel();
  }
}

// ---------------------------------------------------------------------------
// 🗄️  Pending Session Cache & Sync Helpers (moved from main file)
// ---------------------------------------------------------------------------

extension _SessionSyncHelpers on SessionDurationTrackingService {
  void _cachePendingSession(Map<String, dynamic> sessionData) {
    if (_pendingSessions.length >= SessionTrackingConfig.maxPendingSessions) {
      _pendingSessions.removeAt(0); // Remove oldest session
    }

    _pendingSessions.add({
      ...sessionData,
      'cached_at': DateTime.now().toIso8601String(),
    });

    debugPrint(
      "💾 Session cached for offline sync: ${sessionData['session_id']}",
    );
  }

  void _onConnectivityChanged(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online) {
      _syncPendingSessions();
    }
  }

  Future<void> _syncPendingSessions() async {
    if (_pendingSessions.isEmpty || !ConnectivityService.isOnline) {
      return;
    }

    final sessionsToSync = List<Map<String, dynamic>>.from(_pendingSessions);
    _pendingSessions.clear();

    int syncedCount = 0;
    for (final sessionData in sessionsToSync) {
      try {
        // Remove cache metadata before syncing
        final cleanData = Map<String, dynamic>.from(sessionData);
        cleanData.remove('cached_at');

        await _syncSessionToDatabase(cleanData);
        syncedCount++;
      } catch (e) {
        debugPrint('❌ Failed to sync cached session: $e');
        // Re-add to pending if sync fails
        _cachePendingSession(sessionData);
      }
    }

    if (syncedCount > 0) {
      debugPrint('📤 Synced $syncedCount cached sessions to database');
    }
  }
}
