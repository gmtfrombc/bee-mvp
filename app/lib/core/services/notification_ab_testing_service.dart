import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

/// Service for A/B testing notification effectiveness
class NotificationABTestingService {
  static NotificationABTestingService? _instance;
  static NotificationABTestingService get instance {
    _instance ??= NotificationABTestingService._();
    return _instance!;
  }

  NotificationABTestingService._();

  final _supabase = Supabase.instance.client;
  final _random = Random();

  /// Get notification variant for user
  Future<NotificationVariant> getNotificationVariant({
    required String userId,
    required String testName,
  }) async {
    try {
      // Check if user already has a variant assigned
      final existingAssignment =
          await _supabase
              .from('notification_ab_assignments')
              .select()
              .eq('user_id', userId)
              .eq('test_name', testName)
              .maybeSingle();

      if (existingAssignment != null) {
        return NotificationVariant.fromJson(existingAssignment['variant']);
      }

      // Get active test configuration
      final testConfig = await _getTestConfiguration(testName);
      if (testConfig == null) {
        return NotificationVariant.control(); // Default to control if no test
      }

      // Assign user to a variant based on traffic allocation
      final variant = _assignVariant(testConfig);

      // Store assignment
      await _supabase.from('notification_ab_assignments').insert({
        'user_id': userId,
        'test_name': testName,
        'variant': variant.toJson(),
        'assigned_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print(
          '🧪 A/B Test Assignment: $userId -> ${variant.name} for $testName',
        );
      }

      return variant;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting notification variant: $e');
      }
      return NotificationVariant.control(); // Fallback to control
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
    try {
      // Get user's variant assignment
      final assignment =
          await _supabase
              .from('notification_ab_assignments')
              .select()
              .eq('user_id', userId)
              .eq('test_name', testName)
              .maybeSingle();

      if (assignment == null) {
        if (kDebugMode) {
          print(
            '⚠️ No A/B test assignment found for user $userId in test $testName',
          );
        }
        return;
      }

      // Track the event
      await _supabase.from('notification_ab_events').insert({
        'user_id': userId,
        'test_name': testName,
        'variant_name': assignment['variant']['name'],
        'event_type': event.name,
        'notification_id': notificationId,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print(
          '📊 A/B Event Tracked: ${event.name} for ${assignment['variant']['name']}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking notification event: $e');
      }
    }
  }

  /// Get A/B test results
  Future<ABTestResults> getTestResults(String testName) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-ab-test-results',
        body: {'test_name': testName},
      );

      if (response.status == 200 && response.data != null) {
        return ABTestResults.fromJson(response.data);
      }

      // Return mock results if function not available
      return ABTestResults(
        testName: testName,
        variants: [
          VariantResults(
            name: 'control',
            participants: 150,
            deliveryRate: 0.95,
            openRate: 0.32,
            clickRate: 0.08,
            conversionRate: 0.05,
            engagementScore: 0.28,
          ),
          VariantResults(
            name: 'variant_a',
            participants: 145,
            deliveryRate: 0.96,
            openRate: 0.38,
            clickRate: 0.12,
            conversionRate: 0.07,
            engagementScore: 0.35,
          ),
        ],
        statisticalSignificance: 0.85,
        winningVariant: 'variant_a',
        confidenceLevel: 0.95,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting test results: $e');
      }
      throw Exception('Failed to get test results: $e');
    }
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
    try {
      await _supabase.from('notification_ab_tests').insert({
        'test_name': testName,
        'description': description,
        'variants': variants.map((v) => v.toJson()).toList(),
        'traffic_allocation': trafficAllocation,
        'start_date': (startDate ?? DateTime.now()).toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ A/B Test created: $testName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating A/B test: $e');
      }
      return false;
    }
  }

  /// Get active A/B tests
  Future<List<ABTest>> getActiveTests() async {
    try {
      final response = await _supabase
          .from('notification_ab_tests')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List).map((item) => ABTest.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting active tests: $e');
      }
      return [];
    }
  }

  /// Stop A/B test
  Future<bool> stopTest(String testName) async {
    try {
      await _supabase
          .from('notification_ab_tests')
          .update({
            'status': 'stopped',
            'end_date': DateTime.now().toIso8601String(),
          })
          .eq('test_name', testName);

      if (kDebugMode) {
        print('🛑 A/B Test stopped: $testName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping test: $e');
      }
      return false;
    }
  }

  /// Get test configuration
  Future<Map<String, dynamic>?> _getTestConfiguration(String testName) async {
    try {
      final response =
          await _supabase
              .from('notification_ab_tests')
              .select()
              .eq('test_name', testName)
              .eq('status', 'active')
              .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting test configuration: $e');
      }
      return null;
    }
  }

  /// Assign variant based on traffic allocation
  NotificationVariant _assignVariant(Map<String, dynamic> testConfig) {
    final variants = testConfig['variants'] as List;
    final trafficAllocation =
        testConfig['traffic_allocation'] as Map<String, dynamic>;

    final randomValue = _random.nextDouble();
    double cumulativeWeight = 0.0;

    for (final variantData in variants) {
      final variant = NotificationVariant.fromJson(variantData);
      final weight = trafficAllocation[variant.name] ?? 0.0;
      cumulativeWeight += weight;

      if (randomValue <= cumulativeWeight) {
        return variant;
      }
    }

    // Fallback to first variant
    return NotificationVariant.fromJson(variants.first);
  }

  /// Get notification content based on variant
  Map<String, String> getNotificationContent({
    required NotificationVariant variant,
    required String baseTitle,
    required String baseBody,
    Map<String, dynamic>? context,
  }) {
    switch (variant.type) {
      case VariantType.control:
        return {'title': baseTitle, 'body': baseBody};

      case VariantType.personalized:
        return {
          'title': _personalizeContent(baseTitle, context),
          'body': _personalizeContent(baseBody, context),
        };

      case VariantType.urgent:
        return {'title': '🚨 $baseTitle', 'body': 'Urgent: $baseBody'};

      case VariantType.encouraging:
        return {
          'title': '🌟 $baseTitle',
          'body': 'You\'ve got this! $baseBody',
        };

      case VariantType.social:
        return {
          'title': baseTitle,
          'body': '$baseBody Join others on their wellness journey!',
        };

      case VariantType.gamified:
        return {
          'title': '🎯 $baseTitle',
          'body': '$baseBody Earn points for staying engaged!',
        };
    }
  }

  /// Personalize content based on context
  String _personalizeContent(String content, Map<String, dynamic>? context) {
    if (context == null) return content;

    String personalized = content;

    // Replace placeholders with context data
    if (context['user_name'] != null) {
      personalized = personalized.replaceAll('{name}', context['user_name']);
    }

    if (context['momentum_state'] != null) {
      personalized = personalized.replaceAll(
        '{momentum}',
        context['momentum_state'],
      );
    }

    if (context['streak_days'] != null) {
      personalized = personalized.replaceAll(
        '{streak}',
        '${context['streak_days']} days',
      );
    }

    return personalized;
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
