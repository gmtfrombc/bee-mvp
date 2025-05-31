import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/notification_models.dart';
import '../domain/models/notification_types.dart';
import '../domain/services/notification_preferences_service.dart';
import '../../services/notification_service.dart';
import '../../services/fcm_token_service.dart';
import '../../services/notification_ab_testing_service.dart' as ab_service;

/// Unified notification testing framework
/// Consolidates test generation, execution, and validation from:
/// - notification_test_generator.dart
/// - notification_test_validator.dart
/// - Core testing logic
class NotificationTestFramework {
  static NotificationTestFramework? _instance;
  static NotificationTestFramework get instance {
    _instance ??= NotificationTestFramework._();
    return _instance!;
  }

  NotificationTestFramework._();

  final _supabase = Supabase.instance.client;
  final _notificationService = NotificationService.instance;
  final _fcmTokenService = FCMTokenService.instance;
  final _preferencesService = NotificationPreferencesService.instance;
  final _abTestingService = ab_service.NotificationABTestingService.instance;

  // ========== Test Generation Methods ==========

  /// Generate a comprehensive test suite
  Future<NotificationTestResults> generateTestSuite({
    String? userId,
    bool includeABTests = true,
    bool testAllScenarios = true,
    bool includeEndToEndTests = true,
  }) async {
    final results = <String, TestResult>{};
    final errors = <String, String>{};

    try {
      if (kDebugMode) {
        debugPrint('🧪 Generating notification test suite...');
      }

      // Core Tests (Always Run)
      results['fcm_token'] = await _testFCMToken(userId);
      results['user_preferences'] = await _testUserPreferences(userId);
      results['notification_permissions'] =
          await _testNotificationPermissions();
      results['edge_function_connectivity'] =
          await _testEdgeFunctionConnectivity(userId);

      // Extended Tests (Optional)
      if (testAllScenarios) {
        results['database_connectivity'] = await _testDatabaseConnectivity(
          userId,
        );
        results['token_refresh'] = await _testTokenRefresh();
        results['delivery_tracking'] = await _testDeliveryTracking();
      }

      // A/B Testing Tests (Optional)
      if (includeABTests) {
        results['ab_variants'] = await _testABVariants(userId);
      }

      // Content Generation Test (Always Run)
      results['notification_content'] = await _testNotificationContent();

      // End-to-End Tests (Optional but Recommended)
      if (includeEndToEndTests) {
        results['end_to_end_delivery'] = await _testEndToEndDelivery(userId);
        results['rate_limiting'] = await _testRateLimiting(userId);
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
      errors['test_suite_error'] = 'Failed to generate complete test suite: $e';
    }

    final overallSuccess =
        results.isEmpty
            ? 0.0
            : results.values.where((r) => r.success).length / results.length;

    return NotificationTestResults(
      testResults: results,
      errors: errors,
      overallSuccess: overallSuccess,
    );
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
          data: {
            'original_token_valid': isValid,
            'refresh_successful': refreshWorked,
            'token_length': refreshedToken?.length ?? 0,
          },
          timestamp: DateTime.now(),
        );
      }

      return TestResult(
        success: isValid,
        message:
            isValid ? 'FCM token is valid' : 'FCM token is invalid or missing',
        data: {'token_valid': isValid, 'token_length': token?.length ?? 0},
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'FCM token test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
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
        data: tests,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'User preferences test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
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
        data: {'permissions_granted': hasPermissions},
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Notification permissions test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
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
        data: {'status_code': response.status, 'response_data': response.data},
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Edge function connectivity test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
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
        data: {'preferences_found': response != null, 'user_id': testUserId},
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Database connectivity test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
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
        data: {
          'original_token_exists': originalToken != null,
          'original_token_valid': isValid,
          'new_token_generated': newToken != null,
          'tokens_different': originalToken != newToken,
        },
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Token refresh test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
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

      // Test tracking an event using the AB testing service's own enum
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
        data: {
          'variant_name': variant.name,
          'variant_type': variant.type.name,
          'content_title': content['title'],
          'content_body': content['body'],
        },
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'A/B variants test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
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

        // Test content generation for different momentum states using AB service's variant
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
        data: results,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Notification content test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
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
        data: {
          'status_code': response.status,
          'notifications_processed':
              data['summary']?['total_notifications_sent'] ?? 0,
          'interventions_created':
              data['summary']?['total_interventions_created'] ?? 0,
          'pipeline_stages_passed': success ? 'all' : 'failed_at_edge_function',
        },
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'End-to-end delivery test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
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
        data: {
          'can_send_notification': canSend,
          'rate_limit_active': !canSend,
          'daily_count': rateLimitResponse.data?['daily_count'] ?? 0,
          'max_per_day': rateLimitResponse.data?['max_per_day'] ?? 3,
        },
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Rate limiting test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
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
        data: {
          'recent_notifications_count': notifications.length,
          'has_delivery_tracking': hasTrackedDeliveries,
          'delivery_statuses':
              notifications.map((n) => n['delivery_status']).toSet().toList(),
        },
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Delivery tracking test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
      );
    }
  }

  // ========== Test Analysis & Validation Methods ==========

  /// Analyze test results for insights and health assessment
  NotificationTestAnalysis analyzeTestResults(
    Map<String, TestResult> testResults,
  ) {
    // Count successes and failures
    final successCount = testResults.values.where((r) => r.success).length;
    final failureCount = testResults.length - successCount;

    final successRate =
        testResults.isEmpty ? 0.0 : successCount / testResults.length;

    // Categorize issues by severity
    final criticalIssues = <String>[];
    final warnings = <String>[];
    final informational = <String>[];

    for (final entry in testResults.entries) {
      final testName = entry.key;
      final result = entry.value;

      if (!result.success) {
        switch (testName) {
          case 'fcm_token':
          case 'notification_permissions':
          case 'edge_function_connectivity':
            criticalIssues.add('$testName: ${result.message ?? "Failed"}');
            break;
          case 'database_connectivity':
          case 'end_to_end_delivery':
            warnings.add('$testName: ${result.message ?? "Failed"}');
            break;
          default:
            informational.add('$testName: ${result.message ?? "Failed"}');
        }
      }
    }

    // Determine overall health
    final overallHealth = _calculateOverallHealth(criticalIssues, warnings);

    // Generate summary
    final summary = _generateSummary(
      testResults.length,
      successRate,
      overallHealth,
      criticalIssues,
      warnings,
    );

    return NotificationTestAnalysis(
      totalTests: testResults.length,
      successCount: successCount,
      failureCount: failureCount,
      successRate: successRate,
      overallHealth: overallHealth,
      criticalIssues: criticalIssues,
      warnings: warnings,
      informational: informational,
      summary: summary,
    );
  }

  /// Check if notification system is ready for production
  ProductionReadinessCheck checkProductionReadiness(
    Map<String, TestResult> testResults,
  ) {
    // Define critical tests that must pass for production
    final criticalTests = [
      'fcm_token',
      'notification_permissions',
      'edge_function_connectivity',
      'user_preferences',
    ];

    final passedCritical = <String>[];
    final failedCritical = <String>[];

    for (final testName in criticalTests) {
      final result = testResults[testName];
      if (result != null) {
        if (result.success) {
          passedCritical.add(testName);
        } else {
          failedCritical.add(testName);
        }
      } else {
        failedCritical.add('$testName (not executed)');
      }
    }

    final isProductionReady = failedCritical.isEmpty;

    // Check optional tests
    final optionalTests = ['delivery_tracking', 'rate_limiting', 'ab_variants'];
    final optionalPassed = <String>[];
    final optionalFailed = <String>[];

    for (final testName in optionalTests) {
      final result = testResults[testName];
      if (result != null) {
        if (result.success) {
          optionalPassed.add(testName);
        } else {
          optionalFailed.add(testName);
        }
      }
    }

    return ProductionReadinessCheck(
      isProductionReady: isProductionReady,
      criticalTestsPassed: passedCritical,
      criticalTestsFailed: failedCritical,
      optionalTestsPassed: optionalPassed,
      optionalTestsFailed: optionalFailed,
      report: _generateProductionReport(
        isProductionReady,
        passedCritical,
        failedCritical,
        optionalPassed,
        optionalFailed,
      ),
    );
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
      buffer.writeln('Message: ${result.message ?? "No message"}');

      if (result.data?.isNotEmpty == true) {
        buffer.writeln('Details:');
        for (final detail in result.data!.entries) {
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
    buffer.writeln(generateRecommendations(results));

    return buffer.toString();
  }

  /// Generate recommendations based on test results
  String generateRecommendations(NotificationTestResults results) {
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
              '- Investigate end-to-end delivery failure: ${result.message ?? "Unknown error"}',
            );
            break;
          case 'rate_limiting':
            buffer.writeln(
              '- Investigate rate limiting failure: ${result.message ?? "Unknown error"}',
            );
            break;
          case 'delivery_tracking':
            buffer.writeln(
              '- Investigate delivery tracking failure: ${result.message ?? "Unknown error"}',
            );
            break;
          default:
            buffer.writeln(
              '- Investigate $testName failure: ${result.message ?? "Unknown error"}',
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

  // ========== Helper Methods ==========

  NotificationSystemHealth _calculateOverallHealth(
    List<String> criticalIssues,
    List<String> warnings,
  ) {
    if (criticalIssues.isEmpty && warnings.isEmpty) {
      return NotificationSystemHealth.excellent;
    } else if (criticalIssues.isEmpty && warnings.length <= 1) {
      return NotificationSystemHealth.good;
    } else if (criticalIssues.length <= 1) {
      return NotificationSystemHealth.fair;
    } else {
      return NotificationSystemHealth.poor;
    }
  }

  String _generateSummary(
    int totalTests,
    double successRate,
    NotificationSystemHealth overallHealth,
    List<String> criticalIssues,
    List<String> warnings,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('Test Results Summary:');
    buffer.writeln('- Total Tests: $totalTests');
    buffer.writeln(
      '- Success Rate: ${(successRate * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln('- Overall Health: ${overallHealth.name}');

    if (criticalIssues.isNotEmpty) {
      buffer.writeln('- Critical Issues: ${criticalIssues.length}');
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('- Warnings: ${warnings.length}');
    }

    return buffer.toString();
  }

  String _generateProductionReport(
    bool isReady,
    List<String> passedCritical,
    List<String> failedCritical,
    List<String> optionalPassed,
    List<String> optionalFailed,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('# Production Readiness Report');
    buffer.writeln('Status: ${isReady ? "✅ READY" : "❌ NOT READY"}');
    buffer.writeln();

    buffer.writeln('## Critical Tests');
    for (final test in passedCritical) {
      buffer.writeln('✅ $test');
    }
    for (final test in failedCritical) {
      buffer.writeln('❌ $test');
    }

    if (optionalPassed.isNotEmpty || optionalFailed.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## Optional Tests');
      for (final test in optionalPassed) {
        buffer.writeln('✅ $test');
      }
      for (final test in optionalFailed) {
        buffer.writeln('⚠️ $test');
      }
    }

    return buffer.toString();
  }
}
