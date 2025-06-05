import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/today_feed_content.dart';
import 'today_feed_content_quality_models.dart';

/// Alert management service for Today Feed content quality system
/// Part of the modular content quality system for Epic 1.3 Task T1.3.5.9
class TodayFeedQualityAlertManager {
  static const String _alertsKey = 'today_feed_quality_alerts';
  static const int _maxAlertHistory = 100;

  // Quality thresholds for alert generation
  static const double _minOverallQualityScore = 0.7;
  static const double _minSafetyScore = 0.8;
  static const double _criticalSafetyThreshold = 0.6;

  static SharedPreferences? _prefs;
  static StreamController<QualityAlert>? _alertController;
  static bool _isInitialized = false;

  /// Initialize the alert manager
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _alertController = StreamController<QualityAlert>.broadcast();
      _isInitialized = true;

      debugPrint('✅ TodayFeedQualityAlertManager initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize TodayFeedQualityAlertManager: $e');
      rethrow;
    }
  }

  /// Alert stream for real-time quality notifications
  static Stream<QualityAlert> get alertStream {
    if (_alertController == null) {
      throw StateError('TodayFeedQualityAlertManager not initialized');
    }
    return _alertController!.stream;
  }

  /// Generate and record quality alerts based on validation results
  static Future<List<QualityAlert>> generateQualityAlerts(
    QualityValidationResult validationResult,
    TodayFeedContent content,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityAlertManager not initialized');
    }

    final generatedAlerts = <QualityAlert>[];

    try {
      // Generate alert for low quality content
      if (validationResult.overallQualityScore < _minOverallQualityScore) {
        final qualityAlert = QualityAlert(
          id: 'quality_low_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.qualityIssue,
          severity:
              validationResult.overallQualityScore < 0.5
                  ? AlertSeverity.critical
                  : AlertSeverity.high,
          message: 'Content quality below acceptable threshold',
          contentId: content.id.toString(),
          details: {
            'quality_score': validationResult.overallQualityScore,
            'threshold': _minOverallQualityScore,
            'issues': validationResult.issues,
            'content_title': content.title,
            'readability_score': validationResult.readabilityScore,
            'engagement_score': validationResult.engagementScore,
          },
          createdAt: DateTime.now(),
        );

        generatedAlerts.add(qualityAlert);
        await _recordAlert(qualityAlert);
        _alertController?.add(qualityAlert);
      }

      // Generate alert for safety issues
      if (validationResult.safetyScore < _minSafetyScore) {
        final safetyAlert = QualityAlert(
          id: 'safety_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.safetyIssue,
          severity:
              validationResult.safetyScore < _criticalSafetyThreshold
                  ? AlertSeverity.critical
                  : AlertSeverity.high,
          message: 'Content safety issues detected',
          contentId: content.id.toString(),
          details: {
            'safety_score': validationResult.safetyScore,
            'threshold': _minSafetyScore,
            'issues': validationResult.issues,
            'content_title': content.title,
            'confidence_score': validationResult.confidenceScore,
          },
          createdAt: DateTime.now(),
        );

        generatedAlerts.add(safetyAlert);
        await _recordAlert(safetyAlert);
        _alertController?.add(safetyAlert);
      }

      // Generate alert for very low AI confidence
      if (validationResult.confidenceScore < 0.5) {
        final confidenceAlert = QualityAlert(
          id: 'confidence_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.qualityIssue,
          severity: AlertSeverity.medium,
          message: 'AI confidence score extremely low',
          contentId: content.id.toString(),
          details: {
            'confidence_score': validationResult.confidenceScore,
            'threshold': 0.5,
            'content_title': content.title,
            'requires_review': validationResult.requiresReview,
          },
          createdAt: DateTime.now(),
        );

        generatedAlerts.add(confidenceAlert);
        await _recordAlert(confidenceAlert);
        _alertController?.add(confidenceAlert);
      }

      return generatedAlerts;
    } catch (e) {
      debugPrint('❌ Failed to generate quality alerts: $e');
      return [];
    }
  }

  /// Generate safety monitoring alerts
  static Future<List<QualityAlert>> generateSafetyAlerts(
    SafetyMonitoringResult safetyResult,
    TodayFeedContent content,
  ) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityAlertManager not initialized');
    }

    final generatedAlerts = <QualityAlert>[];

    try {
      if (!safetyResult.isPassed) {
        final safetyAlert = QualityAlert(
          id: 'safety_monitor_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.safetyIssue,
          severity:
              safetyResult.safetyScore < _criticalSafetyThreshold
                  ? AlertSeverity.critical
                  : AlertSeverity.high,
          message: 'Content safety monitoring detected issues',
          contentId: content.id.toString(),
          details: {
            'safety_score': safetyResult.safetyScore,
            'risk_factors': safetyResult.riskFactors,
            'safety_checks': safetyResult.safetyChecks,
            'content_title': content.title,
            'recommendations': safetyResult.recommendations,
          },
          createdAt: DateTime.now(),
        );

        generatedAlerts.add(safetyAlert);
        await _recordAlert(safetyAlert);
        _alertController?.add(safetyAlert);
      }

      return generatedAlerts;
    } catch (e) {
      debugPrint('❌ Failed to generate safety alerts: $e');
      return [];
    }
  }

  /// Get stored quality alerts with optional filtering
  static Future<List<QualityAlert>> getQualityAlerts({
    AlertSeverity? severity,
    AlertType? type,
    bool? resolved,
    String? contentId,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityAlertManager not initialized');
    }

    try {
      final allAlerts = await _getStoredAlerts();

      return allAlerts.where((alert) {
        if (severity != null && alert.severity != severity) return false;
        if (type != null && alert.type != type) return false;
        if (resolved != null && alert.isResolved != resolved) return false;
        if (contentId != null && alert.contentId != contentId) return false;
        return true;
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get quality alerts: $e');
      return [];
    }
  }

  /// Get alerts summary for dashboard
  static Future<AlertsSummary> getAlertsSummary() async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityAlertManager not initialized');
    }

    try {
      final allAlerts = await _getStoredAlerts();
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));

      final activeAlerts =
          allAlerts
              .where((a) => !a.isResolved && a.createdAt.isAfter(dayAgo))
              .toList();

      final last24hAlerts =
          allAlerts.where((a) => a.createdAt.isAfter(dayAgo)).toList();

      final last7dAlerts =
          allAlerts.where((a) => a.createdAt.isAfter(weekAgo)).toList();

      final criticalAlerts =
          activeAlerts
              .where((a) => a.severity == AlertSeverity.critical)
              .length;

      final highAlerts =
          activeAlerts.where((a) => a.severity == AlertSeverity.high).length;

      return AlertsSummary(
        totalAlerts: allAlerts.length,
        activeAlerts: activeAlerts.length,
        last24hAlerts: last24hAlerts.length,
        last7dAlerts: last7dAlerts.length,
        criticalAlerts: criticalAlerts,
        highAlerts: highAlerts,
        safetyAlerts:
            activeAlerts.where((a) => a.type == AlertType.safetyIssue).length,
        qualityAlerts:
            activeAlerts.where((a) => a.type == AlertType.qualityIssue).length,
        trend: _calculateAlertTrend(last7dAlerts),
        lastUpdated: now,
      );
    } catch (e) {
      debugPrint('❌ Failed to get alerts summary: $e');
      return AlertsSummary.empty();
    }
  }

  /// Resolve a quality alert
  static Future<bool> resolveAlert(String alertId) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityAlertManager not initialized');
    }

    try {
      final alerts = await _getStoredAlerts();
      final alertIndex = alerts.indexWhere((a) => a.id == alertId);

      if (alertIndex == -1) return false;

      alerts[alertIndex] = alerts[alertIndex].copyWith(
        isResolved: true,
        resolvedAt: DateTime.now(),
      );

      await _storeAlerts(alerts);
      return true;
    } catch (e) {
      debugPrint('❌ Failed to resolve alert: $e');
      return false;
    }
  }

  /// Bulk resolve alerts by criteria
  static Future<int> bulkResolveAlerts({
    AlertSeverity? severity,
    AlertType? type,
    String? contentId,
  }) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityAlertManager not initialized');
    }

    try {
      final alerts = await _getStoredAlerts();
      var resolvedCount = 0;

      for (var i = 0; i < alerts.length; i++) {
        final alert = alerts[i];
        if (alert.isResolved) continue;

        final shouldResolve =
            (severity == null || alert.severity == severity) &&
            (type == null || alert.type == type) &&
            (contentId == null || alert.contentId == contentId);

        if (shouldResolve) {
          alerts[i] = alert.copyWith(
            isResolved: true,
            resolvedAt: DateTime.now(),
          );
          resolvedCount++;
        }
      }

      if (resolvedCount > 0) {
        await _storeAlerts(alerts);
      }

      return resolvedCount;
    } catch (e) {
      debugPrint('❌ Failed to bulk resolve alerts: $e');
      return 0;
    }
  }

  /// Clear old resolved alerts to manage storage
  static Future<int> clearOldAlerts({Duration? olderThan}) async {
    if (!_isInitialized) {
      throw StateError('TodayFeedQualityAlertManager not initialized');
    }

    final cutoffDate = DateTime.now().subtract(
      olderThan ?? const Duration(days: 30),
    );

    try {
      final alerts = await _getStoredAlerts();
      final initialCount = alerts.length;

      alerts.removeWhere(
        (alert) => alert.isResolved && alert.createdAt.isBefore(cutoffDate),
      );

      await _storeAlerts(alerts);
      return initialCount - alerts.length;
    } catch (e) {
      debugPrint('❌ Failed to clear old alerts: $e');
      return 0;
    }
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    _alertController?.close();
    _alertController = null;
    _isInitialized = false;
    debugPrint('🧹 TodayFeedQualityAlertManager disposed');
  }

  // Private helper methods

  /// Record quality alert to storage
  static Future<void> _recordAlert(QualityAlert alert) async {
    try {
      final alerts = await _getStoredAlerts();
      alerts.add(alert);

      // Keep only recent alerts
      if (alerts.length > _maxAlertHistory) {
        alerts.removeRange(0, alerts.length - _maxAlertHistory);
      }

      await _storeAlerts(alerts);
    } catch (e) {
      debugPrint('❌ Failed to record quality alert: $e');
    }
  }

  /// Get stored alerts from SharedPreferences
  static Future<List<QualityAlert>> _getStoredAlerts() async {
    try {
      final jsonString = _prefs!.getString(_alertsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => QualityAlert.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get stored alerts: $e');
      return [];
    }
  }

  /// Store alerts to SharedPreferences
  static Future<void> _storeAlerts(List<QualityAlert> alerts) async {
    try {
      final jsonList = alerts.map((a) => a.toJson()).toList();
      await _prefs!.setString(_alertsKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('❌ Failed to store alerts: $e');
    }
  }

  /// Calculate alert trend from recent alerts
  static String _calculateAlertTrend(List<QualityAlert> recentAlerts) {
    if (recentAlerts.length < 2) return 'insufficient_data';

    final now = DateTime.now();
    final midWeek = now.subtract(const Duration(days: 3));

    final recentCount =
        recentAlerts.where((a) => a.createdAt.isAfter(midWeek)).length;
    final olderCount =
        recentAlerts.where((a) => a.createdAt.isBefore(midWeek)).length;

    if (recentCount > olderCount * 1.5) return 'increasing';
    if (recentCount < olderCount * 0.5) return 'decreasing';
    return 'stable';
  }
}

/// Alerts summary for dashboard display
@immutable
class AlertsSummary {
  final int totalAlerts;
  final int activeAlerts;
  final int last24hAlerts;
  final int last7dAlerts;
  final int criticalAlerts;
  final int highAlerts;
  final int safetyAlerts;
  final int qualityAlerts;
  final String trend;
  final DateTime lastUpdated;

  const AlertsSummary({
    required this.totalAlerts,
    required this.activeAlerts,
    required this.last24hAlerts,
    required this.last7dAlerts,
    required this.criticalAlerts,
    required this.highAlerts,
    required this.safetyAlerts,
    required this.qualityAlerts,
    required this.trend,
    required this.lastUpdated,
  });

  factory AlertsSummary.empty() {
    return AlertsSummary(
      totalAlerts: 0,
      activeAlerts: 0,
      last24hAlerts: 0,
      last7dAlerts: 0,
      criticalAlerts: 0,
      highAlerts: 0,
      safetyAlerts: 0,
      qualityAlerts: 0,
      trend: 'stable',
      lastUpdated: DateTime.now(),
    );
  }
}
