import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../connectivity_service.dart';
import '../../../features/today_feed/domain/models/today_feed_content.dart';

/// Service for handling user interactions and sync operations for Today Feed cache
class TodayFeedCacheSyncService {
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  // Sync-related state
  static Timer? _syncRetryTimer;
  static StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  static bool _syncInProgress = false;

  // Cache keys for sync operations
  static const String _pendingInteractionsKey =
      'today_feed_pending_interactions';
  static const String _backgroundSyncEnabledKey = 'today_feed_background_sync';
  static const String _syncErrorsKey = 'today_feed_sync_errors';
  static const String _lastSuccessfulSyncKey =
      'today_feed_last_successful_sync';
  static const String _syncRetryCountKey = 'today_feed_sync_retry_count';

  // Configuration constants
  static const int _maxSyncRetries = 3;
  static const Duration _syncRetryDelay = Duration(minutes: 5);
  static const int _maxSyncErrors = 50;
  static const Duration _syncErrorRetention = Duration(days: 3);
  static const Duration _pendingInteractionRetention = Duration(days: 7);

  /// Initialize the sync service
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _isInitialized = true;

    // Initialize connectivity listener
    await _initializeConnectivityListener();

    debugPrint('✅ TodayFeedCacheSyncService initialized');
  }

  /// Cache pending user interactions for later sync
  static Future<void> cachePendingInteraction(
    Map<String, dynamic> interaction,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    try {
      final interactionsJson = _prefs!.getString(_pendingInteractionsKey);
      List<Map<String, dynamic>> interactions = [];

      if (interactionsJson != null) {
        final interactionsData = jsonDecode(interactionsJson) as List<dynamic>;
        interactions = interactionsData.cast<Map<String, dynamic>>();
      }

      // Add timestamp and metadata to interaction
      final enhancedInteraction = Map<String, dynamic>.from(interaction);
      enhancedInteraction.addAll({
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'device_timezone': DateTime.now().timeZoneName,
        'queue_id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      interactions.add(enhancedInteraction);

      await _prefs!.setString(
        _pendingInteractionsKey,
        jsonEncode(interactions),
      );

      debugPrint(
        '💾 Pending interaction cached (${interactions.length} total)',
      );
    } catch (e) {
      debugPrint('❌ Failed to cache pending interaction: $e');
      await _queueSyncError('cache_interaction', e.toString());
    }
  }

  /// Get pending interactions for sync
  static Future<List<Map<String, dynamic>>> getPendingInteractions() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    try {
      final interactionsJson = _prefs!.getString(_pendingInteractionsKey);
      if (interactionsJson == null) return [];

      final interactionsData = jsonDecode(interactionsJson) as List<dynamic>;
      return interactionsData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get pending interactions: $e');
      await _queueSyncError('get_interactions', e.toString());
      return [];
    }
  }

  /// Clear pending interactions after successful sync
  static Future<void> clearPendingInteractions() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    try {
      await _prefs!.remove(_pendingInteractionsKey);
      await _updateLastSuccessfulSync();
      debugPrint('✅ Pending interactions cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear pending interactions: $e');
      await _queueSyncError('clear_interactions', e.toString());
    }
  }

  /// Enable/disable background sync
  static Future<void> setBackgroundSyncEnabled(bool enabled) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    try {
      await _prefs!.setBool(_backgroundSyncEnabledKey, enabled);
      debugPrint('⚙️ Background sync ${enabled ? 'enabled' : 'disabled'}');

      if (enabled) {
        await _initializeConnectivityListener();
      } else {
        await _disposeConnectivityListener();
      }
    } catch (e) {
      debugPrint('❌ Failed to set background sync preference: $e');
      await _queueSyncError('set_background_sync', e.toString());
    }
  }

  /// Check if background sync is enabled
  static Future<bool> isBackgroundSyncEnabled() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    return _prefs!.getBool(_backgroundSyncEnabledKey) ?? true;
  }

  /// Sync when online (main sync operation)
  static Future<void> syncWhenOnline() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    if (_syncInProgress) {
      debugPrint('🔄 Sync already in progress, skipping');
      return;
    }

    try {
      _syncInProgress = true;
      debugPrint('🔄 Starting sync when online');

      // Check if background sync is enabled
      final isEnabled = await isBackgroundSyncEnabled();
      if (!isEnabled) {
        debugPrint('⚠️ Background sync is disabled, skipping');
        return;
      }

      // Get pending interactions
      final pendingInteractions = await getPendingInteractions();
      if (pendingInteractions.isEmpty) {
        debugPrint('ℹ️ No pending interactions to sync');
        await _updateLastSuccessfulSync();
        return;
      }

      debugPrint(
        '🔄 Syncing ${pendingInteractions.length} pending interactions',
      );

      // In a real implementation, this would make API calls to sync interactions
      // For now, we'll simulate the sync process
      await _simulateSyncOperation(pendingInteractions);

      // Clear interactions after successful sync
      await clearPendingInteractions();
      await _resetSyncRetryCount();

      debugPrint('✅ Sync completed successfully');
    } catch (e) {
      debugPrint('❌ Failed to sync when online: $e');
      await _handleSyncError('sync_when_online', e.toString());
      rethrow;
    } finally {
      _syncInProgress = false;
    }
  }

  /// Mark content as viewed (creates interaction for sync)
  static Future<void> markContentAsViewed(TodayFeedContent content) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    try {
      // Create interaction for sync
      await cachePendingInteraction({
        'action': 'content_viewed',
        'content_id': content.id,
        'content_date': content.contentDate.toIso8601String(),
        'topic_category': content.topicCategory.toString(),
        'ai_confidence_score': content.aiConfidenceScore,
        'estimated_reading_minutes': content.estimatedReadingMinutes,
        'viewed_at': DateTime.now().toIso8601String(),
      });

      debugPrint('📋 Content marked as viewed: ${content.title}');
    } catch (e) {
      debugPrint('❌ Failed to mark content as viewed: $e');
      await _queueSyncError('mark_content_viewed', e.toString());
      rethrow;
    }
  }

  /// Get sync status for debugging and monitoring
  static Future<Map<String, dynamic>> getSyncStatus() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    try {
      final pendingInteractions = await getPendingInteractions();
      final syncErrors = await getSyncErrors();
      final lastSuccessfulSync = _prefs!.getString(_lastSuccessfulSyncKey);
      final syncRetryCount = _prefs!.getInt(_syncRetryCountKey) ?? 0;
      final backgroundSyncEnabled = await isBackgroundSyncEnabled();

      return {
        'sync_in_progress': _syncInProgress,
        'pending_interactions_count': pendingInteractions.length,
        'sync_errors_count': syncErrors.length,
        'last_successful_sync': lastSuccessfulSync,
        'sync_retry_count': syncRetryCount,
        'max_retries': _maxSyncRetries,
        'background_sync_enabled': backgroundSyncEnabled,
        'connectivity_listener_active': _connectivitySubscription != null,
        'last_connectivity_change': _getLastConnectivityChange(),
        'connectivity_status': await _getCurrentConnectivityStatus(),
        'is_online': await _isOnline(),
      };
    } catch (e) {
      debugPrint('❌ Failed to get sync status: $e');
      return {
        'error': e.toString(),
        'sync_in_progress': _syncInProgress,
        'pending_interactions_count': 0,
        'sync_errors_count': 0,
      };
    }
  }

  /// Get sync errors for analysis
  static Future<List<Map<String, dynamic>>> getSyncErrors() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    try {
      final errorsJson = _prefs!.getString(_syncErrorsKey);
      if (errorsJson == null) return [];

      final List<dynamic> errorsList = jsonDecode(errorsJson);
      return errorsList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get sync errors: $e');
      return [];
    }
  }

  /// Cleanup expired pending interactions
  static Future<void> cleanupPendingInteractions() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    try {
      final interactionsJson = _prefs!.getString(_pendingInteractionsKey);
      if (interactionsJson == null) return;

      final interactions = jsonDecode(interactionsJson) as List<dynamic>;
      final cutoffDate = DateTime.now().subtract(_pendingInteractionRetention);

      final validInteractions =
          interactions.where((interaction) {
            try {
              final timestamp = DateTime.parse(
                interaction['timestamp'] as String,
              );
              return timestamp.isAfter(cutoffDate);
            } catch (e) {
              return false; // Remove invalid entries
            }
          }).toList();

      if (validInteractions.length != interactions.length) {
        await _prefs!.setString(
          _pendingInteractionsKey,
          jsonEncode(validInteractions),
        );
        debugPrint(
          '🧹 Cleaned up pending interactions: ${interactions.length} → ${validInteractions.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup pending interactions: $e');
    }
  }

  /// Cleanup old sync errors
  static Future<void> cleanupSyncErrors() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    try {
      final errorsJson = _prefs!.getString(_syncErrorsKey);
      if (errorsJson == null) return;

      final errors = jsonDecode(errorsJson) as List<dynamic>;
      final cutoffDate = DateTime.now().subtract(_syncErrorRetention);

      final recentErrors =
          errors.where((error) {
            try {
              final timestamp = DateTime.parse(error['timestamp'] as String);
              return timestamp.isAfter(cutoffDate);
            } catch (e) {
              return false; // Remove invalid entries
            }
          }).toList();

      if (recentErrors.length != errors.length) {
        await _prefs!.setString(_syncErrorsKey, jsonEncode(recentErrors));
        debugPrint(
          '🧹 Cleaned up sync errors: ${errors.length} → ${recentErrors.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup sync errors: $e');
    }
  }

  /// Get sync performance metrics
  static Future<Map<String, dynamic>> getSyncMetrics() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedCacheSyncService not initialized');
    }

    try {
      final pendingInteractions = await getPendingInteractions();
      final syncErrors = await getSyncErrors();
      final lastSuccessfulSync = _prefs!.getString(_lastSuccessfulSyncKey);
      final syncRetryCount = _prefs!.getInt(_syncRetryCountKey) ?? 0;

      // Calculate success rate
      final totalAttempts = pendingInteractions.length + syncErrors.length;
      final successRate =
          totalAttempts > 0
              ? ((totalAttempts - syncErrors.length) / totalAttempts * 100)
                  .clamp(0.0, 100.0)
              : 100.0;

      // Calculate average retry count
      final avgRetryCount =
          pendingInteractions.isNotEmpty
              ? pendingInteractions
                      .map((i) => i['retry_count'] as int? ?? 0)
                      .reduce((a, b) => a + b) /
                  pendingInteractions.length
              : 0.0;

      return {
        'pending_count': pendingInteractions.length,
        'error_count': syncErrors.length,
        'success_rate_percentage': successRate,
        'current_retry_count': syncRetryCount,
        'average_retry_count': avgRetryCount,
        'last_successful_sync': lastSuccessfulSync,
        'sync_efficiency': _calculateSyncEfficiency(successRate, avgRetryCount),
        'recommendations': _generateSyncRecommendations(
          successRate,
          syncErrors.length,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to get sync metrics: $e');
      return {
        'error': e.toString(),
        'pending_count': 0,
        'error_count': 0,
        'success_rate_percentage': 0.0,
      };
    }
  }

  /// Dispose sync service resources
  static Future<void> dispose() async {
    try {
      _syncRetryTimer?.cancel();
      await _disposeConnectivityListener();

      _syncRetryTimer = null;
      _connectivitySubscription = null;
      _syncInProgress = false;
      _isInitialized = false;

      debugPrint('✅ TodayFeedCacheSyncService disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose TodayFeedCacheSyncService: $e');
    }
  }

  // PRIVATE HELPER METHODS

  /// Initialize connectivity listener for sync management
  static Future<void> _initializeConnectivityListener() async {
    try {
      await _disposeConnectivityListener(); // Clean up existing listener

      _connectivitySubscription = ConnectivityService.statusStream.listen(
        (status) async {
          debugPrint('📶 Connectivity changed: $status');
          await _handleConnectivityChange(status);
        },
        onError: (error) {
          debugPrint('❌ Connectivity listener error: $error');
        },
      );

      debugPrint('📶 Connectivity listener initialized for sync');
    } catch (e) {
      debugPrint('❌ Failed to initialize connectivity listener: $e');
    }
  }

  /// Dispose connectivity listener
  static Future<void> _disposeConnectivityListener() async {
    try {
      await _connectivitySubscription?.cancel();
      _connectivitySubscription = null;
    } catch (e) {
      debugPrint('❌ Failed to dispose connectivity listener: $e');
    }
  }

  /// Handle connectivity changes
  static Future<void> _handleConnectivityChange(
    ConnectivityStatus status,
  ) async {
    try {
      if (status == ConnectivityStatus.online) {
        debugPrint('🔄 Connection restored, checking for pending sync');

        // Check if we have pending interactions to sync
        final pendingInteractions = await getPendingInteractions();
        if (pendingInteractions.isNotEmpty) {
          debugPrint(
            '🔄 Found ${pendingInteractions.length} pending interactions, starting sync',
          );
          await syncWhenOnline();
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to handle connectivity change: $e');
      await _queueSyncError('connectivity_change', e.toString());
    }
  }

  /// Queue sync error for analysis
  static Future<void> _queueSyncError(String operation, String error) async {
    try {
      final errorsJson = _prefs!.getString(_syncErrorsKey);
      List<Map<String, dynamic>> errors = [];

      if (errorsJson != null) {
        final errorsData = jsonDecode(errorsJson) as List<dynamic>;
        errors = errorsData.cast<Map<String, dynamic>>();
      }

      errors.add({
        'operation': operation,
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': _prefs!.getInt(_syncRetryCountKey) ?? 0,
        'connectivity_status': await _getCurrentConnectivityStatus(),
      });

      // Keep only last _maxSyncErrors errors
      if (errors.length > _maxSyncErrors) {
        errors = errors.skip(errors.length - _maxSyncErrors).toList();
      }

      await _prefs!.setString(_syncErrorsKey, jsonEncode(errors));
      debugPrint('📝 Sync error queued: $operation');
    } catch (e) {
      debugPrint('❌ Failed to queue sync error: $e');
    }
  }

  /// Handle sync errors with retry logic
  static Future<void> _handleSyncError(String operation, String error) async {
    try {
      await _queueSyncError(operation, error);

      final retryCount = _prefs!.getInt(_syncRetryCountKey) ?? 0;

      if (retryCount < _maxSyncRetries) {
        await _incrementSyncRetryCount();
        await _scheduleRetry();
        debugPrint(
          '🔄 Scheduled sync retry ${retryCount + 1}/$_maxSyncRetries',
        );
      } else {
        debugPrint('⚠️ Max sync retries reached, giving up');
        await _resetSyncRetryCount();
      }
    } catch (e) {
      debugPrint('❌ Failed to handle sync error: $e');
    }
  }

  /// Schedule sync retry with exponential backoff
  static Future<void> _scheduleRetry() async {
    try {
      _syncRetryTimer?.cancel();

      final retryCount = _prefs!.getInt(_syncRetryCountKey) ?? 0;
      final delay = Duration(
        milliseconds: _syncRetryDelay.inMilliseconds * (1 << retryCount),
      );

      _syncRetryTimer = Timer(delay, () async {
        debugPrint('⏰ Retry timer triggered, attempting sync');
        try {
          await syncWhenOnline();
        } catch (e) {
          debugPrint('❌ Retry sync failed: $e');
        }
      });

      debugPrint('⏰ Sync retry scheduled in ${delay.inMinutes} minutes');
    } catch (e) {
      debugPrint('❌ Failed to schedule retry: $e');
    }
  }

  /// Simulate sync operation (replace with real API calls)
  static Future<void> _simulateSyncOperation(
    List<Map<String, dynamic>> interactions,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real implementation, this would:
    // 1. Make HTTP requests to sync each interaction
    // 2. Handle individual failures and retries
    // 3. Update interaction retry counts
    // 4. Remove successfully synced interactions

    debugPrint('🔄 Simulated sync of ${interactions.length} interactions');
  }

  /// Update last successful sync timestamp
  static Future<void> _updateLastSuccessfulSync() async {
    try {
      await _prefs!.setString(
        _lastSuccessfulSyncKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('❌ Failed to update last successful sync: $e');
    }
  }

  /// Increment sync retry count
  static Future<void> _incrementSyncRetryCount() async {
    try {
      final currentCount = _prefs!.getInt(_syncRetryCountKey) ?? 0;
      await _prefs!.setInt(_syncRetryCountKey, currentCount + 1);
    } catch (e) {
      debugPrint('❌ Failed to increment sync retry count: $e');
    }
  }

  /// Reset sync retry count
  static Future<void> _resetSyncRetryCount() async {
    try {
      await _prefs!.setInt(_syncRetryCountKey, 0);
    } catch (e) {
      debugPrint('❌ Failed to reset sync retry count: $e');
    }
  }

  /// Get current connectivity status
  static Future<String> _getCurrentConnectivityStatus() async {
    try {
      // This would use the connectivity service to get actual status
      return 'online'; // Simplified for now
    } catch (e) {
      return 'unknown';
    }
  }

  /// Check if device is online
  static Future<bool> _isOnline() async {
    try {
      final status = await _getCurrentConnectivityStatus();
      return status == 'online';
    } catch (e) {
      return false;
    }
  }

  /// Get last connectivity change timestamp
  static String? _getLastConnectivityChange() {
    try {
      return _prefs!.getString('last_connectivity_change');
    } catch (e) {
      return null;
    }
  }

  /// Calculate sync efficiency score
  static double _calculateSyncEfficiency(
    double successRate,
    double avgRetryCount,
  ) {
    try {
      // Efficiency decreases with more retries needed
      final retryPenalty = avgRetryCount * 10; // 10% penalty per retry
      final efficiency = (successRate - retryPenalty).clamp(0.0, 100.0);
      return efficiency;
    } catch (e) {
      return 0.0;
    }
  }

  /// Generate sync recommendations
  static List<String> _generateSyncRecommendations(
    double successRate,
    int errorCount,
  ) {
    final recommendations = <String>[];

    if (successRate < 80) {
      recommendations.add('Consider checking network connectivity');
      recommendations.add('Review sync error logs for patterns');
    }

    if (errorCount > 10) {
      recommendations.add(
        'High error count detected - investigate sync failures',
      );
    }

    if (successRate >= 95 && errorCount == 0) {
      recommendations.add('Sync performance is excellent');
    }

    return recommendations;
  }
}
