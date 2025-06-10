import 'package:flutter/foundation.dart';

/// Alert severity levels for content quality issues
enum AlertSeverity {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const AlertSeverity(this.value);
  final String value;

  static AlertSeverity fromString(String value) {
    return AlertSeverity.values.firstWhere(
      (severity) => severity.value == value,
      orElse: () => AlertSeverity.medium,
    );
  }
}

/// Types of quality alerts
enum AlertType {
  qualityIssue('quality_issue'),
  safetyIssue('safety_issue'),
  performanceIssue('performance_issue'),
  userFeedback('user_feedback');

  const AlertType(this.value);
  final String value;

  static AlertType fromString(String value) {
    return AlertType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AlertType.qualityIssue,
    );
  }
}

/// Quality alert data model
@immutable
class QualityAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final String? contentId;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final bool isResolved;
  final DateTime? resolvedAt;

  const QualityAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    this.contentId,
    required this.details,
    required this.createdAt,
    this.isResolved = false,
    this.resolvedAt,
  });

  QualityAlert copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? message,
    String? contentId,
    Map<String, dynamic>? details,
    DateTime? createdAt,
    bool? isResolved,
    DateTime? resolvedAt,
  }) {
    return QualityAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      contentId: contentId ?? this.contentId,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.value,
    'severity': severity.value,
    'message': message,
    'content_id': contentId,
    'details': details,
    'created_at': createdAt.toIso8601String(),
    'is_resolved': isResolved,
    'resolved_at': resolvedAt?.toIso8601String(),
  };

  factory QualityAlert.fromJson(Map<String, dynamic> json) {
    return QualityAlert(
      id: json['id'] as String,
      type: AlertType.fromString(json['type'] as String),
      severity: AlertSeverity.fromString(json['severity'] as String),
      message: json['message'] as String,
      contentId: json['content_id'] as String?,
      details: Map<String, dynamic>.from(json['details'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      isResolved: json['is_resolved'] as bool? ?? false,
      resolvedAt:
          json['resolved_at'] != null
              ? DateTime.parse(json['resolved_at'] as String)
              : null,
    );
  }
}

/// Quality validation result data model
@immutable
class QualityValidationResult {
  final String contentId;
  final bool isValid;
  final double overallQualityScore;
  final double safetyScore;
  final double readabilityScore;
  final double engagementScore;
  final double confidenceScore;
  final List<String> issues;
  final List<String> warnings;
  final bool requiresReview;
  final DateTime validatedAt;
  final List<String> recommendations;
  final String? errorMessage;

  const QualityValidationResult({
    required this.contentId,
    required this.isValid,
    required this.overallQualityScore,
    required this.safetyScore,
    required this.readabilityScore,
    required this.engagementScore,
    required this.confidenceScore,
    required this.issues,
    required this.warnings,
    required this.requiresReview,
    required this.validatedAt,
    required this.recommendations,
    this.errorMessage,
  });

  factory QualityValidationResult.error({
    required String contentId,
    required String errorMessage,
  }) {
    return QualityValidationResult(
      contentId: contentId,
      isValid: false,
      overallQualityScore: 0.0,
      safetyScore: 0.0,
      readabilityScore: 0.0,
      engagementScore: 0.0,
      confidenceScore: 0.0,
      issues: ['Validation failed: $errorMessage'],
      warnings: const [],
      requiresReview: true,
      validatedAt: DateTime.now(),
      recommendations: const ['Review validation error and retry'],
      errorMessage: errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
    'content_id': contentId,
    'is_valid': isValid,
    'overall_quality_score': overallQualityScore,
    'safety_score': safetyScore,
    'readability_score': readabilityScore,
    'engagement_score': engagementScore,
    'confidence_score': confidenceScore,
    'issues': issues,
    'warnings': warnings,
    'requires_review': requiresReview,
    'validated_at': validatedAt.toIso8601String(),
    'recommendations': recommendations,
    'error_message': errorMessage,
  };

  factory QualityValidationResult.fromJson(Map<String, dynamic> json) {
    return QualityValidationResult(
      contentId: json['content_id'] as String,
      isValid: json['is_valid'] as bool,
      overallQualityScore: (json['overall_quality_score'] as num).toDouble(),
      safetyScore: (json['safety_score'] as num).toDouble(),
      readabilityScore: (json['readability_score'] as num).toDouble(),
      engagementScore: (json['engagement_score'] as num).toDouble(),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      issues: List<String>.from(json['issues'] as List),
      warnings: List<String>.from(json['warnings'] as List),
      requiresReview: json['requires_review'] as bool,
      validatedAt: DateTime.parse(json['validated_at'] as String),
      recommendations: List<String>.from(json['recommendations'] as List),
      errorMessage: json['error_message'] as String?,
    );
  }
}

/// Safety monitoring result data model
@immutable
class SafetyMonitoringResult {
  final String contentId;
  final double safetyScore;
  final Map<String, bool> safetyChecks;
  final List<String> riskFactors;
  final List<String> recommendations;
  final bool isPassed;
  final DateTime monitoredAt;
  final String? errorMessage;

  const SafetyMonitoringResult({
    required this.contentId,
    required this.safetyScore,
    required this.safetyChecks,
    required this.riskFactors,
    required this.recommendations,
    required this.isPassed,
    required this.monitoredAt,
    this.errorMessage,
  });

  factory SafetyMonitoringResult.error({
    required String contentId,
    required String errorMessage,
  }) {
    return SafetyMonitoringResult(
      contentId: contentId,
      safetyScore: 0.0,
      safetyChecks: const {},
      riskFactors: ['Safety monitoring failed: $errorMessage'],
      recommendations: const ['Review safety monitoring error and retry'],
      isPassed: false,
      monitoredAt: DateTime.now(),
      errorMessage: errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
    'content_id': contentId,
    'safety_score': safetyScore,
    'safety_checks': safetyChecks,
    'risk_factors': riskFactors,
    'recommendations': recommendations,
    'is_passed': isPassed,
    'monitored_at': monitoredAt.toIso8601String(),
    'error_message': errorMessage,
  };

  factory SafetyMonitoringResult.fromJson(Map<String, dynamic> json) {
    return SafetyMonitoringResult(
      contentId: json['content_id'] as String,
      safetyScore: (json['safety_score'] as num).toDouble(),
      safetyChecks: Map<String, bool>.from(json['safety_checks'] as Map),
      riskFactors: List<String>.from(json['risk_factors'] as List),
      recommendations: List<String>.from(json['recommendations'] as List),
      isPassed: json['is_passed'] as bool,
      monitoredAt: DateTime.parse(json['monitored_at'] as String),
      errorMessage: json['error_message'] as String?,
    );
  }
}

/// Quality metrics data model
@immutable
class QualityMetrics {
  final DateTime timestamp;
  final int totalValidations;
  final int last24hValidations;
  final int last7dValidations;
  final double averageQualityScore;
  final double averageSafetyScore;
  final int activeAlerts;
  final int criticalAlerts;
  final String qualityTrend;
  final String safetyTrend;
  final List<String> recommendations;
  final String? errorMessage;

  const QualityMetrics({
    required this.timestamp,
    required this.totalValidations,
    required this.last24hValidations,
    required this.last7dValidations,
    required this.averageQualityScore,
    required this.averageSafetyScore,
    required this.activeAlerts,
    required this.criticalAlerts,
    required this.qualityTrend,
    required this.safetyTrend,
    required this.recommendations,
    this.errorMessage,
  });

  factory QualityMetrics.error(String errorMessage) {
    return QualityMetrics(
      timestamp: DateTime.now(),
      totalValidations: 0,
      last24hValidations: 0,
      last7dValidations: 0,
      averageQualityScore: 0.0,
      averageSafetyScore: 0.0,
      activeAlerts: 0,
      criticalAlerts: 0,
      qualityTrend: 'unknown',
      safetyTrend: 'unknown',
      recommendations: ['Unable to calculate metrics: $errorMessage'],
      errorMessage: errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'total_validations': totalValidations,
    'last_24h_validations': last24hValidations,
    'last_7d_validations': last7dValidations,
    'average_quality_score': averageQualityScore,
    'average_safety_score': averageSafetyScore,
    'active_alerts': activeAlerts,
    'critical_alerts': criticalAlerts,
    'quality_trend': qualityTrend,
    'safety_trend': safetyTrend,
    'recommendations': recommendations,
    'error_message': errorMessage,
  };

  factory QualityMetrics.fromJson(Map<String, dynamic> json) {
    return QualityMetrics(
      timestamp: DateTime.parse(json['timestamp'] as String),
      totalValidations: json['total_validations'] as int,
      last24hValidations: json['last_24h_validations'] as int,
      last7dValidations: json['last_7d_validations'] as int,
      averageQualityScore: (json['average_quality_score'] as num).toDouble(),
      averageSafetyScore: (json['average_safety_score'] as num).toDouble(),
      activeAlerts: json['active_alerts'] as int,
      criticalAlerts: json['critical_alerts'] as int,
      qualityTrend: json['quality_trend'] as String,
      safetyTrend: json['safety_trend'] as String,
      recommendations: List<String>.from(json['recommendations'] as List),
      errorMessage: json['error_message'] as String?,
    );
  }
}

/// Format validation result data model
@immutable
class FormatValidationResult {
  final double formatScore;
  final List<String> issues;
  final List<String> warnings;

  const FormatValidationResult({
    required this.formatScore,
    required this.issues,
    required this.warnings,
  });
}

/// Safety validation result data model
@immutable
class SafetyValidationResult {
  final double safetyScore;
  final List<String> issues;
  final List<String> warnings;

  const SafetyValidationResult({
    required this.safetyScore,
    required this.issues,
    required this.warnings,
  });
}

/// Safety check result data model
@immutable
class SafetyCheckResult {
  final bool isPassed;
  final List<String> riskFactors;
  final List<String> recommendations;

  const SafetyCheckResult({
    required this.isPassed,
    required this.riskFactors,
    required this.recommendations,
  });
}
