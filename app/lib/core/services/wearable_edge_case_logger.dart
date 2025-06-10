/// Wearable Edge Case Logger for T2.2.1.5-5
///
/// Logs critical edge cases: permission revocation, airplane mode, timestamp drift.
/// Provides structured logging for mitigation ticket documentation.
/// Follows single responsibility principle - pure logging service.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'wearable_data_repository.dart';
import 'wearable_data_models.dart';
import 'connectivity_service.dart';

/// Check if we're running in test environment
bool get _isTestEnvironment {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        (kDebugMode && Platform.environment['FLUTTER_TEST'] == 'true');
  } catch (e) {
    return false;
  }
}

/// Edge case types for wearable integration
enum WearableEdgeCase {
  permissionRevoked,
  airplaneMode,
  timestampDrift,
  healthConnectUnavailable,
  backgroundSyncFailure,
}

/// Edge case log entry
class EdgeCaseLogEntry {
  final String id;
  final WearableEdgeCase type;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final String description;
  final String? mitigationTicket;

  const EdgeCaseLogEntry({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.context,
    required this.description,
    this.mitigationTicket,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
    'description': description,
    'mitigationTicket': mitigationTicket,
  };

  factory EdgeCaseLogEntry.fromJson(Map<String, dynamic> json) {
    return EdgeCaseLogEntry(
      id: json['id'],
      type: WearableEdgeCase.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WearableEdgeCase.backgroundSyncFailure,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      context: Map<String, dynamic>.from(json['context']),
      description: json['description'],
      mitigationTicket: json['mitigationTicket'],
    );
  }
}

/// Lean edge case logger for wearable integration
class WearableEdgeCaseLogger {
  static const String _logKey = 'wearable_edge_case_log';
  static const int _maxLogEntries = 100;
  static const Duration _timestampDriftThreshold = Duration(minutes: 5);

  final WearableDataRepository? _repository;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Last known state for drift detection
  DateTime? _lastKnownServerTime;
  DateTime? _lastPermissionCheck;
  bool _lastConnectivityState = true;

  WearableEdgeCaseLogger({WearableDataRepository? repository})
    : _repository = repository;

  /// Initialize the logger
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      if (!_isTestEnvironment) {
        debugPrint('🚨 WearableEdgeCaseLogger initialized');
      }
      return true;
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Failed to initialize edge case logger: $e');
      }
      return false;
    }
  }

  /// Check for permission revocation edge case
  Future<void> checkPermissionRevocation() async {
    if (!_isInitialized || _repository == null) return;

    try {
      final currentStatus = await _repository.checkPermissions();
      final now = DateTime.now();

      // Only log if permissions were previously granted
      if (_lastPermissionCheck != null &&
          currentStatus != HealthPermissionStatus.authorized) {
        await _logEdgeCase(
          type: WearableEdgeCase.permissionRevoked,
          description: 'Health permissions revoked',
          context: {
            'current_status': currentStatus.name,
            'platform': Platform.operatingSystem,
            'health_connect_available': _repository.isHealthConnectAvailable,
            'permanently_denied': _repository.hasBeenPermanentlyDenied,
            'platform_info': _repository.platformInfo,
          },
        );
      }

      _lastPermissionCheck = now;
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Error checking permission revocation: $e');
      }
    }
  }

  /// Check for airplane mode / connectivity edge cases
  Future<void> checkConnectivityIssues() async {
    if (!_isInitialized) return;

    try {
      final isOnline = ConnectivityService.isOnline;
      final now = DateTime.now();

      // Log connectivity state changes
      if (_lastConnectivityState && !isOnline) {
        await _logEdgeCase(
          type: WearableEdgeCase.airplaneMode,
          description: 'Device went offline (airplane mode or network loss)',
          context: {
            'connectivity_status': ConnectivityService.currentStatus.name,
            'timestamp': now.toIso8601String(),
            'was_online': _lastConnectivityState,
          },
        );
      }

      _lastConnectivityState = isOnline;
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Error checking connectivity: $e');
      }
    }
  }

  /// Check for timestamp drift edge cases
  Future<void> checkTimestampDrift({DateTime? serverTime}) async {
    if (!_isInitialized) return;

    try {
      final localTime = DateTime.now();

      if (serverTime != null) {
        _lastKnownServerTime = serverTime;
      }

      if (_lastKnownServerTime != null) {
        final drift = localTime.difference(_lastKnownServerTime!).abs();

        if (drift > _timestampDriftThreshold) {
          await _logEdgeCase(
            type: WearableEdgeCase.timestampDrift,
            description: 'Significant timestamp drift detected',
            context: {
              'local_time': localTime.toIso8601String(),
              'server_time': _lastKnownServerTime!.toIso8601String(),
              'drift_minutes': drift.inMinutes,
              'threshold_minutes': _timestampDriftThreshold.inMinutes,
              'timezone': localTime.timeZoneName,
            },
          );
        }
      }
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Error checking timestamp drift: $e');
      }
    }
  }

  /// Check for Health Connect availability issues
  Future<void> checkHealthConnectAvailability() async {
    if (!_isInitialized || !Platform.isAndroid || _repository == null) return;

    try {
      if (!_repository.isHealthConnectAvailable) {
        final availability = await _repository.getDetailedAvailability();

        await _logEdgeCase(
          type: WearableEdgeCase.healthConnectUnavailable,
          description: 'Health Connect not available',
          context: {
            'availability_result': {
              'is_available': availability.isAvailable,
              'reason': availability.unavailabilityReason?.name,
              'user_message': availability.userMessage,
              'can_install': availability.canInstall,
              'can_resolve': availability.canResolve,
            },
            'debug_info': availability.debugInfo,
          },
        );
      }
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Error checking Health Connect availability: $e');
      }
    }
  }

  /// Log a background sync failure
  Future<void> logBackgroundSyncFailure(
    String error, {
    Map<String, dynamic>? additionalContext,
  }) async {
    await _logEdgeCase(
      type: WearableEdgeCase.backgroundSyncFailure,
      description: 'Background sync failed',
      context: {
        'error': error,
        'sync_time': DateTime.now().toIso8601String(),
        ...?additionalContext,
      },
    );
  }

  /// Execute comprehensive edge case check
  Future<void> performComprehensiveCheck({DateTime? serverTime}) async {
    if (!_isInitialized) {
      if (!_isTestEnvironment) {
        debugPrint('⚠️ Edge case logger not initialized');
      }
      return;
    }

    if (!_isTestEnvironment) {
      debugPrint('🔍 Performing comprehensive edge case check');
    }

    await Future.wait([
      checkPermissionRevocation(),
      checkConnectivityIssues(),
      checkTimestampDrift(serverTime: serverTime),
      checkHealthConnectAvailability(),
    ]);
  }

  /// Get recent edge case logs
  Future<List<EdgeCaseLogEntry>> getRecentLogs({
    Duration? since,
    WearableEdgeCase? filterType,
  }) async {
    if (!_isInitialized) return [];

    try {
      final logs = await _getAllLogs();
      final cutoff = since != null ? DateTime.now().subtract(since) : null;

      return logs.where((log) {
        final timeMatch = cutoff == null || log.timestamp.isAfter(cutoff);
        final typeMatch = filterType == null || log.type == filterType;
        return timeMatch && typeMatch;
      }).toList();
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Error getting recent logs: $e');
      }
      return [];
    }
  }

  /// Generate mitigation documentation
  Future<Map<String, dynamic>> generateMitigationReport() async {
    final logs = await getRecentLogs(since: const Duration(days: 7));
    final summary = <WearableEdgeCase, int>{};

    for (final log in logs) {
      summary[log.type] = (summary[log.type] ?? 0) + 1;
    }

    return {
      'period': '7 days',
      'total_edge_cases': logs.length,
      'summary_by_type': summary.map((k, v) => MapEntry(k.name, v)),
      'most_recent': logs.isNotEmpty ? logs.last.toJson() : null,
      'mitigation_tickets':
          logs
              .where((log) => log.mitigationTicket != null)
              .map((log) => log.mitigationTicket)
              .toSet()
              .toList(),
    };
  }

  /// Private: Log an edge case
  Future<void> _logEdgeCase({
    required WearableEdgeCase type,
    required String description,
    required Map<String, dynamic> context,
    String? mitigationTicket,
  }) async {
    try {
      final entry = EdgeCaseLogEntry(
        id: 'edge_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        timestamp: DateTime.now(),
        description: description,
        context: context,
        mitigationTicket: mitigationTicket,
      );

      await _saveLogs([entry]);
      if (!_isTestEnvironment) {
        debugPrint('🚨 Edge case logged: ${type.name} - $description');
      }
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Failed to log edge case: $e');
      }
    }
  }

  /// Private: Get all stored logs
  Future<List<EdgeCaseLogEntry>> _getAllLogs() async {
    try {
      final logsJson = _prefs!.getString(_logKey);
      if (logsJson == null) return [];

      final logsList = jsonDecode(logsJson) as List<dynamic>;
      return logsList.map((json) => EdgeCaseLogEntry.fromJson(json)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Error loading edge case logs: $e');
      }
      return [];
    }
  }

  /// Private: Save logs with size limit
  Future<void> _saveLogs(List<EdgeCaseLogEntry> newLogs) async {
    try {
      final existingLogs = await _getAllLogs();
      final allLogs = [...existingLogs, ...newLogs];

      // Keep only the most recent entries
      if (allLogs.length > _maxLogEntries) {
        allLogs.removeRange(0, allLogs.length - _maxLogEntries);
      }

      final logsJson = jsonEncode(allLogs.map((log) => log.toJson()).toList());
      await _prefs!.setString(_logKey, logsJson);
    } catch (e) {
      if (!_isTestEnvironment) {
        debugPrint('❌ Error saving edge case logs: $e');
      }
    }
  }
}
