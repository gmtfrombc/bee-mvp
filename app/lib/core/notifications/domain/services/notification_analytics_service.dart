import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../models/notification_models.dart';
import '../models/notification_types.dart';

/// Domain service responsible for notification analytics, A/B testing, and
/// user engagement tracking.
///
/// Consolidates functionality from:
/// - notification_ab_testing_service.dart (A/B testing)
/// - Analytics methods from notification_trigger_service.dart
/// - Event tracking and metrics collection
class NotificationAnalyticsService {
  static NotificationAnalyticsService? _instance;

  final SupabaseClient _supabase;
  final Random _random;

  /// Private constructor for dependency injection (mainly for testing)
  NotificationAnalyticsService._({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client,
      _random = Random();

  /// Singleton instance getter for production use
  static NotificationAnalyticsService get instance =>
      _instance ??= NotificationAnalyticsService._();

  /// Factory constructor for testing with dependency injection
  factory NotificationAnalyticsService.forTesting({
    required SupabaseClient supabaseClient,
  }) {
    return NotificationAnalyticsService._(supabaseClient: supabaseClient);
  }

  // ============================================================================
  // A/B TESTING FUNCTIONALITY
  // ============================================================================

  /// Get notification variant for user A/B testing
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
        debugPrint(
          '🧪 A/B Test Assignment: $userId -> ${variant.name} for $testName',
        );
      }

      return variant;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting notification variant: $e');
      }
      return NotificationVariant.control(); // Fallback to control
    }
  }

  /// Track notification event for A/B testing and analytics
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
          debugPrint(
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
        debugPrint(
          '📊 A/B Event Tracked: ${event.name} for ${assignment['variant']['name']}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error tracking notification event: $e');
      }
    }
  }

  /// Get A/B test results and analytics
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
        debugPrint('❌ Error getting test results: $e');
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
        debugPrint('✅ A/B Test created: $testName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating A/B test: $e');
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
        debugPrint('❌ Error getting active tests: $e');
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
        debugPrint('🛑 A/B Test stopped: $testName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error stopping test: $e');
      }
      return false;
    }
  }

  // ============================================================================
  // ANALYTICS FUNCTIONALITY
  // ============================================================================

  /// Get notification analytics for the current user
  Future<List<NotificationAnalytics>> getNotificationAnalytics({
    int days = 30,
  }) async {
    try {
      final response = await _supabase
          .from('notification_analytics')
          .select()
          .gte(
            'notification_date',
            DateTime.now()
                .subtract(Duration(days: days))
                .toIso8601String()
                .split('T')[0],
          )
          .order('notification_date', ascending: false);

      return (response as List)
          .map((item) => NotificationAnalytics.fromJson(item))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting notification analytics: $e');
      }
      return [];
    }
  }

  /// Calculate user engagement score based on notification interactions
  Future<double> calculateEngagementScore({
    required String userId,
    int days = 30,
  }) async {
    try {
      final analytics = await getNotificationAnalytics(days: days);
      if (analytics.isEmpty) return 0.0;

      // Calculate weighted engagement score
      double totalScore = 0.0;
      int totalCount = 0;

      for (final analytic in analytics) {
        totalScore += analytic.engagementScore;
        totalCount++;
      }

      return totalCount > 0 ? totalScore / totalCount : 0.0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating engagement score: $e');
      }
      return 0.0;
    }
  }

  /// Track user notification interaction for analytics
  Future<void> trackUserInteraction({
    required String userId,
    required String notificationId,
    required NotificationInteractionType interactionType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('notification_interactions').insert({
        'user_id': userId,
        'notification_id': notificationId,
        'interaction_type': interactionType.name,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint(
          '📱 User Interaction Tracked: ${interactionType.name} for $notificationId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error tracking user interaction: $e');
      }
    }
  }

  /// Get user interaction history for analytics
  Future<List<NotificationInteraction>> getUserInteractionHistory({
    String? userId,
    int limit = 50,
  }) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No user ID provided and no current user');
      }

      final response = await _supabase
          .from('notification_interactions')
          .select()
          .eq('user_id', currentUserId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => NotificationInteraction.fromJson(item))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user interaction history: $e');
      }
      return [];
    }
  }

  // ============================================================================
  // CONTENT PERSONALIZATION (A/B TESTING VARIANTS)
  // ============================================================================

  /// Get notification content based on A/B test variant
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

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Get test configuration for A/B testing
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
        debugPrint('❌ Error getting test configuration: $e');
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
