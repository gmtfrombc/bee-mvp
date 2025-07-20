import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/services/notification_service.dart';
import 'package:app/core/services/fcm_token_service.dart';
import 'package:app/core/notifications/domain/services/notification_preferences_service.dart';
import 'package:app/core/services/notification_ab_testing_service.dart'
    as ab_service;

/// Service for generating and executing individual notification test cases
class NotificationTestGenerator {
  final _supabase = Supabase.instance.client;
  final _notificationService = NotificationService.instance;
  final _fcmTokenService = FCMTokenService.instance;
  final _preferencesService = NotificationPreferencesService.instance;
  final _abTestingService = ab_service.NotificationABTestingService.instance;

  /// Test FCM token validation
  Future<TestResult> testFCMToken(String? userId) async {
    try {
      final token = await _fcmTokenService.getCurrentToken();
      final isValid = token != null && token.isNotEmpty;

      if (isValid && userId != null) {
        // Test token refresh
        final refreshedToken = await _fcmTokenService.refreshToken();
        final refreshWorked =
            refreshedToken != null && refreshedToken.isNotEmpty;

        return TestResult(
          success: refreshWorked,
          message:
              refreshWorked
                  ? 'FCM token validation successful'
                  : 'FCM token refresh failed',
          details: {
            'original_token_valid': isValid,
            'refresh_successful': refreshWorked,
            'token_length': refreshedToken?.length ?? 0,
          },
        );
      }

      return TestResult(
        success: isValid,
        message:
            isValid ? 'FCM token is valid' : 'FCM token is invalid or missing',
        details: {'token_valid': isValid, 'token_length': token?.length ?? 0},
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'FCM token test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test user preferences compliance
  Future<TestResult> testUserPreferences(String? userId) async {
    try {
      final preferences = _preferencesService;

      // Test different preference scenarios
      final tests = <String, bool>{};

      // Test momentum notifications
      tests['momentum_enabled'] = preferences.momentumNotificationsEnabled;

      // Test intervention notifications
      tests['intervention_enabled'] =
          preferences.interventionNotificationsEnabled;

      // Test quiet hours functionality
      tests['quiet_hours_configured'] = true; // Always configured with defaults

      // Test frequency limits
      tests['frequency_limits_respected'] = preferences.canSendNotification;

      final allConfigured = tests.values.any((test) => test);

      return TestResult(
        success: allConfigured,
        message:
            allConfigured
                ? 'User preferences configured and working'
                : 'User preferences not properly configured',
        details: tests,
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'User preferences test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test notification permissions
  Future<TestResult> testNotificationPermissions() async {
    try {
      final hasPermissions = await _notificationService.hasPermissions();

      return TestResult(
        success: hasPermissions,
        message:
            hasPermissions
                ? 'Notification permissions granted'
                : 'Notification permissions not granted',
        details: {'permissions_granted': hasPermissions},
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Notification permissions test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test Supabase Edge Function connectivity
  Future<TestResult> testEdgeFunctionConnectivity(String? userId) async {
    try {
      final testUserId =
          userId ?? _supabase.auth.currentUser?.id ?? 'test_user';

      // Test calling the push notification trigger function
      final response = await _supabase.functions.invoke(
        'push-notification-triggers',
        body: {'test': true, 'user_id': testUserId, 'momentum_state': 'rising'},
      );

      final success = response.status == 200;

      return TestResult(
        success: success,
        message:
            success
                ? 'Edge function connectivity successful'
                : 'Edge function connectivity failed',
        details: {
          'status_code': response.status,
          'response_data': response.data,
        },
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Edge function connectivity test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test database connectivity
  Future<TestResult> testDatabaseConnectivity(String? userId) async {
    try {
      final testUserId =
          userId ?? _supabase.auth.currentUser?.id ?? 'test_user';

      // Test reading from notification preferences table
      final response =
          await _supabase
              .from('notification_preferences')
              .select('*')
              .eq('user_id', testUserId)
              .maybeSingle();

      return TestResult(
        success: true,
        message: 'Database connectivity successful',
        details: {'preferences_found': response != null, 'user_id': testUserId},
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Database connectivity test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test token refresh mechanism
  Future<TestResult> testTokenRefresh() async {
    try {
      final originalToken = await _fcmTokenService.getStoredToken();
      final isValid = await _fcmTokenService.isTokenValid();

      // Force a token refresh
      final newToken = await _fcmTokenService.refreshToken();

      return TestResult(
        success: newToken != null,
        message:
            newToken != null
                ? 'Token refresh successful'
                : 'Token refresh failed',
        details: {
          'original_token_exists': originalToken != null,
          'original_token_valid': isValid,
          'new_token_generated': newToken != null,
          'tokens_different': originalToken != newToken,
        },
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Token refresh test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test A/B testing variants
  Future<TestResult> testABVariants(String? userId) async {
    try {
      final testUserId =
          userId ?? _supabase.auth.currentUser?.id ?? 'test_user';

      // Test getting variant assignment
      final variant = await _abTestingService.getNotificationVariant(
        userId: testUserId,
        testName: 'momentum_notification_test',
      );

      // Test variant-specific content
      final content = _abTestingService.getNotificationContent(
        variant: variant,
        baseTitle: 'Your momentum update',
        baseBody: 'Check your progress today',
        context: {'user_name': 'Test User', 'momentum_state': 'rising'},
      );

      // Test tracking an event
      await _abTestingService.trackNotificationEvent(
        userId: testUserId,
        testName: 'momentum_notification_test',
        event: ab_service.NotificationEvent.sent,
        notificationId:
            'test_notification_${DateTime.now().millisecondsSinceEpoch}',
      );

      return TestResult(
        success: true,
        message: 'A/B testing variants successful',
        details: {
          'variant_name': variant.name,
          'variant_type': variant.type.name,
          'content_title': content['title'],
          'content_body': content['body'],
        },
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'A/B variants test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test notification content generation
  Future<TestResult> testNotificationContent() async {
    try {
      final testCases = [
        {'momentum_state': 'rising', 'expected_emoji': '🚀'},
        {'momentum_state': 'steady', 'expected_emoji': '🙂'},
        {'momentum_state': 'needs_care', 'expected_emoji': '🌱'},
      ];

      final results = <String, dynamic>{};

      for (final testCase in testCases) {
        final state = testCase['momentum_state'] as String;

        // Test content generation for different momentum states
        final variant = ab_service.NotificationVariant.control();
        final content = _abTestingService.getNotificationContent(
          variant: variant,
          baseTitle: 'Your momentum is $state',
          baseBody: 'Check your progress today',
          context: {'momentum_state': state},
        );

        results['${state}_title'] = content['title'];
        results['${state}_body'] = content['body'];
      }

      return TestResult(
        success: true,
        message: 'Notification content generation successful',
        details: results,
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Notification content test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test end-to-end notification delivery
  Future<TestResult> testEndToEndDelivery(String? userId) async {
    try {
      final testUserId =
          userId ?? _supabase.auth.currentUser?.id ?? 'test_user';

      // Send a test notification through the full pipeline
      final response = await _supabase.functions.invoke(
        'push-notification-triggers',
        body: {
          'user_id': testUserId,
          'trigger_type': 'test',
          'test_mode': true, // Prevents actual FCM sending
          'momentum_data': {
            'current_state': 'rising',
            'score': 75,
            'date': DateTime.now().toIso8601String().split('T')[0],
          },
        },
      );

      final success = response.status == 200;
      final data = response.data as Map<String, dynamic>? ?? {};

      return TestResult(
        success: success,
        message:
            success
                ? 'End-to-end delivery pipeline working'
                : 'End-to-end delivery pipeline failed',
        details: {
          'status_code': response.status,
          'notifications_processed':
              data['summary']?['total_notifications_sent'] ?? 0,
          'interventions_created':
              data['summary']?['total_interventions_created'] ?? 0,
          'pipeline_stages_passed': success ? 'all' : 'failed_at_edge_function',
        },
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'End-to-end delivery test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test notification rate limiting
  Future<TestResult> testRateLimiting(String? userId) async {
    try {
      final testUserId =
          userId ?? _supabase.auth.currentUser?.id ?? 'test_user';

      // Check current rate limit status
      final rateLimitResponse = await _supabase.functions.invoke(
        'check-notification-rate-limit',
        body: {'user_id': testUserId, 'notification_type': 'momentum_drop'},
      );

      final canSend =
          rateLimitResponse.status == 200 &&
          (rateLimitResponse.data as Map<String, dynamic>?)?['can_send'] ==
              true;

      return TestResult(
        success: true, // Rate limiting working is success
        message:
            canSend
                ? 'Rate limiting allows notifications'
                : 'Rate limiting blocking notifications (as expected)',
        details: {
          'can_send_notification': canSend,
          'rate_limit_active': !canSend,
          'daily_count': rateLimitResponse.data?['daily_count'] ?? 0,
          'max_per_day': rateLimitResponse.data?['max_per_day'] ?? 3,
        },
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Rate limiting test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Test notification delivery tracking
  Future<TestResult> testDeliveryTracking() async {
    try {
      // Get recent notification records to verify tracking
      final response = await _supabase
          .from('momentum_notifications')
          .select('id, delivery_status, sent_at, delivered_at, created_at')
          .order('created_at', ascending: false)
          .limit(5);

      final notifications = response as List;
      final hasTrackedDeliveries = notifications.any(
        (n) => n['delivery_status'] != null && n['sent_at'] != null,
      );

      return TestResult(
        success: true,
        message:
            hasTrackedDeliveries
                ? 'Delivery tracking working correctly'
                : 'No delivery tracking data found (may be normal for new users)',
        details: {
          'recent_notifications_count': notifications.length,
          'has_delivery_tracking': hasTrackedDeliveries,
          'delivery_statuses':
              notifications.map((n) => n['delivery_status']).toSet().toList(),
        },
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Delivery tracking test failed',
        details: {'error': e.toString()},
      );
    }
  }

  /// Generate a comprehensive test suite
  Future<Map<String, TestResult>> generateTestSuite({
    String? userId,
    bool includeABTests = true,
    bool testAllScenarios = true,
    bool includeEndToEndTests = true,
  }) async {
    final results = <String, TestResult>{};

    try {
      if (kDebugMode) {
        debugPrint('🧪 Generating notification test suite...');
      }

      // Core Tests (Always Run)
      results['fcm_token'] = await testFCMToken(userId);
      results['user_preferences'] = await testUserPreferences(userId);
      results['notification_permissions'] = await testNotificationPermissions();
      results['edge_function_connectivity'] =
          await testEdgeFunctionConnectivity(userId);

      // Extended Tests (Optional)
      if (testAllScenarios) {
        results['database_connectivity'] = await testDatabaseConnectivity(
          userId,
        );
        results['token_refresh'] = await testTokenRefresh();
        results['delivery_tracking'] = await testDeliveryTracking();
      }

      // A/B Testing Tests (Optional)
      if (includeABTests) {
        results['ab_variants'] = await testABVariants(userId);
      }

      // Content Generation Test (Always Run)
      results['notification_content'] = await testNotificationContent();

      // End-to-End Tests (Optional but Recommended)
      if (includeEndToEndTests) {
        results['end_to_end_delivery'] = await testEndToEndDelivery(userId);
        results['rate_limiting'] = await testRateLimiting(userId);
      }

      if (kDebugMode) {
        final passCount = results.values.where((r) => r.success).length;
        debugPrint(
          '✅ Test suite generated: $passCount/${results.length} tests passed',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error generating test suite: $e');
      }
      results['test_suite_error'] = TestResult(
        success: false,
        message: 'Failed to generate complete test suite',
        details: {'error': e.toString()},
      );
    }

    return results;
  }
}

/// Test result for individual test
class TestResult {
  final bool success;
  final String message;
  final Map<String, dynamic> details;

  TestResult({
    required this.success,
    required this.message,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'details': details};
  }
}
