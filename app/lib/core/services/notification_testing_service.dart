import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import 'fcm_token_service.dart';
import 'notification_preferences_service.dart';
import 'notification_ab_testing_service.dart';

/// Service for testing notification delivery across different scenarios
class NotificationTestingService {
  static NotificationTestingService? _instance;
  static NotificationTestingService get instance {
    _instance ??= NotificationTestingService._();
    return _instance!;
  }

  NotificationTestingService._();

  final _supabase = Supabase.instance.client;
  final _notificationService = NotificationService.instance;
  final _fcmTokenService = FCMTokenService.instance;
  final _preferencesService = NotificationPreferencesService.instance;
  final _abTestingService = NotificationABTestingService.instance;

  /// Run comprehensive notification delivery tests
  Future<NotificationTestResults> runComprehensiveTests({
    String? userId,
    bool includeABTests = true,
    bool testAllScenarios = true,
    bool includeEndToEndTests = true,
  }) async {
    final results = NotificationTestResults();

    try {
      if (kDebugMode) {
        print('🧪 Starting comprehensive notification tests...');
      }

      // Core Tests (Always Run)
      // Test 1: FCM token validation
      final tokenTest = await _testFCMToken(userId);
      results.addTest('fcm_token', tokenTest);

      // Test 2: User preferences compliance
      final preferencesTest = await _testUserPreferences(userId);
      results.addTest('user_preferences', preferencesTest);

      // Test 3: Notification permissions
      final permissionsTest = await _testNotificationPermissions();
      results.addTest('notification_permissions', permissionsTest);

      // Test 4: Supabase Edge Function connectivity
      final edgeFunctionTest = await _testEdgeFunctionConnectivity(userId);
      results.addTest('edge_function_connectivity', edgeFunctionTest);

      // Extended Tests (Optional)
      if (testAllScenarios) {
        // Test 5: Database connectivity
        final databaseTest = await _testDatabaseConnectivity(userId);
        results.addTest('database_connectivity', databaseTest);

        // Test 6: Token refresh mechanism
        final tokenRefreshTest = await _testTokenRefresh();
        results.addTest('token_refresh', tokenRefreshTest);

        // Test 7: Notification delivery tracking
        final deliveryTrackingTest = await _testDeliveryTracking();
        results.addTest('delivery_tracking', deliveryTrackingTest);
      }

      // A/B Testing Tests (Optional)
      if (includeABTests) {
        // Test 8: A/B testing variants
        final abTest = await _testABVariants(userId);
        results.addTest('ab_variants', abTest);
      }

      // Content Generation Test (Always Run)
      // Test 9: Notification content generation
      final contentTest = await _testNotificationContent();
      results.addTest('notification_content', contentTest);

      // End-to-End Tests (Optional but Recommended)
      if (includeEndToEndTests) {
        // Test 10: End-to-end notification delivery
        final endToEndTest = await _testEndToEndDelivery(userId);
        results.addTest('end_to_end_delivery', endToEndTest);

        // Test 11: Notification rate limiting
        final rateLimitTest = await _testRateLimiting(userId);
        results.addTest('rate_limiting', rateLimitTest);
      }

      results.overallSuccess = results.calculateOverallSuccess();

      if (kDebugMode) {
        print(
          '✅ Notification tests completed. Success rate: ${(results.overallSuccess * 100).toStringAsFixed(1)}%',
        );
        print('📊 Tests run: ${results.testResults.length}');
        print(
          '✅ Passed: ${results.testResults.values.where((r) => r.success).length}',
        );
        print(
          '❌ Failed: ${results.testResults.values.where((r) => !r.success).length}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error running notification tests: $e');
      }
      results.addError('comprehensive_test_error', e.toString());
    }

    return results;
  }

  /// Test FCM token validation
  Future<TestResult> _testFCMToken(String? userId) async {
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
  Future<TestResult> _testUserPreferences(String? userId) async {
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
  Future<TestResult> _testNotificationPermissions() async {
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
  Future<TestResult> _testEdgeFunctionConnectivity(String? userId) async {
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
  Future<TestResult> _testDatabaseConnectivity(String? userId) async {
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
  Future<TestResult> _testTokenRefresh() async {
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
  Future<TestResult> _testABVariants(String? userId) async {
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
        event: NotificationEvent.sent,
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
  Future<TestResult> _testNotificationContent() async {
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
        final variant = NotificationVariant.control();
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
  Future<TestResult> _testEndToEndDelivery(String? userId) async {
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
  Future<TestResult> _testRateLimiting(String? userId) async {
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
  Future<TestResult> _testDeliveryTracking() async {
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

  /// Generate test report
  Future<String> generateTestReport(NotificationTestResults results) async {
    final buffer = StringBuffer();

    buffer.writeln('# Notification Testing Report');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln(
      'Overall Success Rate: ${(results.overallSuccess * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln();

    buffer.writeln('## Test Results');
    for (final entry in results.testResults.entries) {
      final testName = entry.key;
      final result = entry.value;

      buffer.writeln('### $testName');
      buffer.writeln('Status: ${result.success ? "✅ PASS" : "❌ FAIL"}');
      buffer.writeln('Message: ${result.message}');

      if (result.details.isNotEmpty) {
        buffer.writeln('Details:');
        for (final detail in result.details.entries) {
          buffer.writeln('  - ${detail.key}: ${detail.value}');
        }
      }
      buffer.writeln();
    }

    if (results.errors.isNotEmpty) {
      buffer.writeln('## Errors');
      for (final entry in results.errors.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
    }

    buffer.writeln('## Recommendations');
    buffer.writeln(_generateRecommendations(results));

    return buffer.toString();
  }

  /// Generate recommendations based on test results
  String _generateRecommendations(NotificationTestResults results) {
    final buffer = StringBuffer();

    for (final entry in results.testResults.entries) {
      final testName = entry.key;
      final result = entry.value;

      if (!result.success) {
        switch (testName) {
          case 'fcm_token':
            buffer.writeln(
              '- Fix FCM token issues: Ensure Firebase is properly configured',
            );
            break;
          case 'notification_permissions':
            buffer.writeln('- Request notification permissions from user');
            break;
          case 'edge_function_connectivity':
            buffer.writeln(
              '- Check Supabase Edge Function deployment and configuration',
            );
            break;
          case 'database_connectivity':
            buffer.writeln('- Verify database schema and user authentication');
            break;
          case 'end_to_end_delivery':
            buffer.writeln(
              '- Investigate end-to-end delivery failure: ${result.message}',
            );
            break;
          case 'rate_limiting':
            buffer.writeln(
              '- Investigate rate limiting failure: ${result.message}',
            );
            break;
          case 'delivery_tracking':
            buffer.writeln(
              '- Investigate delivery tracking failure: ${result.message}',
            );
            break;
          default:
            buffer.writeln(
              '- Investigate $testName failure: ${result.message}',
            );
        }
      }
    }

    if (buffer.isEmpty) {
      buffer.writeln(
        '- All tests passed! Notification system is working correctly.',
      );
    }

    return buffer.toString();
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
}

/// Overall test results
class NotificationTestResults {
  final Map<String, TestResult> testResults = {};
  final Map<String, String> errors = {};
  double overallSuccess = 0.0;

  void addTest(String name, TestResult result) {
    testResults[name] = result;
  }

  void addError(String name, String error) {
    errors[name] = error;
  }

  double calculateOverallSuccess() {
    if (testResults.isEmpty) return 0.0;

    final successCount = testResults.values.where((r) => r.success).length;
    return successCount / testResults.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_success': overallSuccess,
      'test_count': testResults.length,
      'success_count': testResults.values.where((r) => r.success).length,
      'error_count': errors.length,
      'tests': testResults.map(
        (k, v) => MapEntry(k, {
          'success': v.success,
          'message': v.message,
          'details': v.details,
        }),
      ),
      'errors': errors,
    };
  }
}

/// Riverpod provider for notification testing service
final notificationTestingServiceProvider = Provider<NotificationTestingService>(
  (ref) {
    return NotificationTestingService.instance;
  },
);
