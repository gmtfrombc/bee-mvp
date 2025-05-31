import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifications/domain/services/notification_analytics_service.dart';
import '../notifications/domain/models/notification_models.dart' as domain;
import '../notifications/domain/models/notification_types.dart' as domain;

/// Service for A/B testing notification effectiveness
///
/// ⚠️ MIGRATION NOTICE: This service is being refactored
/// This class now delegates to NotificationAnalyticsService for core functionality
/// while maintaining backward compatibility during the transition period.
class NotificationABTestingService {
  static NotificationABTestingService? _instance;
  static NotificationABTestingService get instance {
    _instance ??= NotificationABTestingService._();
    return _instance!;
  }

  NotificationABTestingService._();

  // Delegation to new domain service
  final _analyticsService = NotificationAnalyticsService.instance;

  /// Get notification variant for user
  Future<NotificationVariant> getNotificationVariant({
    required String userId,
    required String testName,
  }) async {
    // Delegate to new domain service
    final domainVariant = await _analyticsService.getNotificationVariant(
      userId: userId,
      testName: testName,
    );

    // Convert domain model to local model for backward compatibility
    return NotificationVariant(
      name: domainVariant.name,
      type: _convertVariantType(domainVariant.type),
      config: domainVariant.config,
    );
  }

  /// Convert domain VariantType to local VariantType
  VariantType _convertVariantType(domain.VariantType domainType) {
    switch (domainType) {
      case domain.VariantType.control:
        return VariantType.control;
      case domain.VariantType.personalized:
        return VariantType.personalized;
      case domain.VariantType.urgent:
        return VariantType.urgent;
      case domain.VariantType.encouraging:
        return VariantType.encouraging;
      case domain.VariantType.social:
        return VariantType.social;
      case domain.VariantType.gamified:
        return VariantType.gamified;
    }
  }

  /// Track notification event for A/B testing
  Future<void> trackNotificationEvent({
    required String userId,
    required String testName,
    required NotificationEvent event,
    required String notificationId,
    Map<String, dynamic>? metadata,
  }) async {
    // Delegate to new domain service with type conversion
    await _analyticsService.trackNotificationEvent(
      userId: userId,
      testName: testName,
      event: _convertNotificationEvent(event),
      notificationId: notificationId,
      metadata: metadata,
    );
  }

  /// Convert local NotificationEvent to domain NotificationEvent
  domain.NotificationEvent _convertNotificationEvent(NotificationEvent event) {
    switch (event) {
      case NotificationEvent.sent:
        return domain.NotificationEvent.sent;
      case NotificationEvent.delivered:
        return domain.NotificationEvent.delivered;
      case NotificationEvent.opened:
        return domain.NotificationEvent.opened;
      case NotificationEvent.clicked:
        return domain.NotificationEvent.clicked;
      case NotificationEvent.dismissed:
        return domain.NotificationEvent.dismissed;
      case NotificationEvent.converted:
        return domain.NotificationEvent.converted;
    }
  }

  /// Get A/B test results
  Future<ABTestResults> getTestResults(String testName) async {
    // Delegate to new domain service
    final domainResults = await _analyticsService.getTestResults(testName);

    // Convert domain model to local model for backward compatibility
    return ABTestResults(
      testName: domainResults.testName,
      variants:
          domainResults.variants
              .map(
                (v) => VariantResults(
                  name: v.name,
                  participants: v.participants,
                  deliveryRate: v.deliveryRate,
                  openRate: v.openRate,
                  clickRate: v.clickRate,
                  conversionRate: v.conversionRate,
                  engagementScore: v.engagementScore,
                ),
              )
              .toList(),
      statisticalSignificance: domainResults.statisticalSignificance,
      winningVariant: domainResults.winningVariant,
      confidenceLevel: domainResults.confidenceLevel,
    );
  }

  /// Create new A/B test
  Future<bool> createABTest({
    required String testName,
    required String description,
    required List<NotificationVariant> variants,
    required Map<String, double> trafficAllocation,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Convert local variants to domain variants
    final domainVariants =
        variants
            .map(
              (v) => domain.NotificationVariant(
                name: v.name,
                type: _convertToDomainVariantType(v.type),
                config: v.config,
              ),
            )
            .toList();

    // Delegate to new domain service
    return await _analyticsService.createABTest(
      testName: testName,
      description: description,
      variants: domainVariants,
      trafficAllocation: trafficAllocation,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Convert local VariantType to domain VariantType
  domain.VariantType _convertToDomainVariantType(VariantType type) {
    switch (type) {
      case VariantType.control:
        return domain.VariantType.control;
      case VariantType.personalized:
        return domain.VariantType.personalized;
      case VariantType.urgent:
        return domain.VariantType.urgent;
      case VariantType.encouraging:
        return domain.VariantType.encouraging;
      case VariantType.social:
        return domain.VariantType.social;
      case VariantType.gamified:
        return domain.VariantType.gamified;
    }
  }

  /// Get active A/B tests
  Future<List<ABTest>> getActiveTests() async {
    // Delegate to new domain service
    final domainTests = await _analyticsService.getActiveTests();

    // Convert domain models to local models for backward compatibility
    return domainTests
        .map(
          (test) => ABTest(
            testName: test.testName,
            description: test.description,
            variants:
                test.variants
                    .map(
                      (v) => NotificationVariant(
                        name: v.name,
                        type: _convertVariantType(v.type),
                        config: v.config,
                      ),
                    )
                    .toList(),
            trafficAllocation: test.trafficAllocation,
            startDate: test.startDate,
            endDate: test.endDate,
            status: test.status,
          ),
        )
        .toList();
  }

  /// Stop A/B test
  Future<bool> stopTest(String testName) async {
    // Delegate to new domain service
    return await _analyticsService.stopTest(testName);
  }

  /// Get notification content based on variant
  Map<String, String> getNotificationContent({
    required NotificationVariant variant,
    required String baseTitle,
    required String baseBody,
    Map<String, dynamic>? context,
  }) {
    // Convert local variant to domain variant and delegate
    final domainVariant = domain.NotificationVariant(
      name: variant.name,
      type: _convertToDomainVariantType(variant.type),
      config: variant.config,
    );

    return _analyticsService.getNotificationContent(
      variant: domainVariant,
      baseTitle: baseTitle,
      baseBody: baseBody,
      context: context,
    );
  }
}

/// Notification variant configuration
class NotificationVariant {
  final String name;
  final VariantType type;
  final Map<String, dynamic> config;

  NotificationVariant({
    required this.name,
    required this.type,
    required this.config,
  });

  factory NotificationVariant.control() {
    return NotificationVariant(
      name: 'control',
      type: VariantType.control,
      config: {},
    );
  }

  factory NotificationVariant.fromJson(Map<String, dynamic> json) {
    return NotificationVariant(
      name: json['name'],
      type: VariantType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VariantType.control,
      ),
      config: json['config'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type.name, 'config': config};
  }
}

/// Types of notification variants
enum VariantType {
  control,
  personalized,
  urgent,
  encouraging,
  social,
  gamified,
}

/// Notification events for tracking
enum NotificationEvent {
  sent,
  delivered,
  opened,
  clicked,
  dismissed,
  converted,
}

/// A/B test results
class ABTestResults {
  final String testName;
  final List<VariantResults> variants;
  final double statisticalSignificance;
  final String? winningVariant;
  final double confidenceLevel;

  ABTestResults({
    required this.testName,
    required this.variants,
    required this.statisticalSignificance,
    this.winningVariant,
    required this.confidenceLevel,
  });

  factory ABTestResults.fromJson(Map<String, dynamic> json) {
    return ABTestResults(
      testName: json['test_name'],
      variants:
          (json['variants'] as List)
              .map((v) => VariantResults.fromJson(v))
              .toList(),
      statisticalSignificance:
          (json['statistical_significance'] as num).toDouble(),
      winningVariant: json['winning_variant'],
      confidenceLevel: (json['confidence_level'] as num).toDouble(),
    );
  }
}

/// Results for a specific variant
class VariantResults {
  final String name;
  final int participants;
  final double deliveryRate;
  final double openRate;
  final double clickRate;
  final double conversionRate;
  final double engagementScore;

  VariantResults({
    required this.name,
    required this.participants,
    required this.deliveryRate,
    required this.openRate,
    required this.clickRate,
    required this.conversionRate,
    required this.engagementScore,
  });

  factory VariantResults.fromJson(Map<String, dynamic> json) {
    return VariantResults(
      name: json['name'],
      participants: json['participants'],
      deliveryRate: (json['delivery_rate'] as num).toDouble(),
      openRate: (json['open_rate'] as num).toDouble(),
      clickRate: (json['click_rate'] as num).toDouble(),
      conversionRate: (json['conversion_rate'] as num).toDouble(),
      engagementScore: (json['engagement_score'] as num).toDouble(),
    );
  }
}

/// A/B test configuration
class ABTest {
  final String testName;
  final String description;
  final List<NotificationVariant> variants;
  final Map<String, double> trafficAllocation;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;

  ABTest({
    required this.testName,
    required this.description,
    required this.variants,
    required this.trafficAllocation,
    required this.startDate,
    this.endDate,
    required this.status,
  });

  factory ABTest.fromJson(Map<String, dynamic> json) {
    return ABTest(
      testName: json['test_name'],
      description: json['description'],
      variants:
          (json['variants'] as List)
              .map((v) => NotificationVariant.fromJson(v))
              .toList(),
      trafficAllocation: Map<String, double>.from(json['traffic_allocation']),
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      status: json['status'],
    );
  }
}

/// Riverpod provider for notification A/B testing service
final notificationABTestingServiceProvider =
    Provider<NotificationABTestingService>((ref) {
      return NotificationABTestingService.instance;
    });
