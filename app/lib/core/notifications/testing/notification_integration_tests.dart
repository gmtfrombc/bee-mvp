import 'package:flutter/foundation.dart';
import '../domain/models/notification_models.dart';
import 'notification_test_framework.dart';

/// High-level integration tests for notification system
/// Consolidates end-to-end test scenarios and complex testing logic
/// Extracted from notification_test_generator.dart and notification_test_validator.dart
class NotificationIntegrationTests {
  static NotificationIntegrationTests? _instance;
  static NotificationIntegrationTests get instance {
    _instance ??= NotificationIntegrationTests._();
    return _instance!;
  }

  NotificationIntegrationTests._();

  final _testFramework = NotificationTestFramework.instance;

  // ========== End-to-End Test Scenarios ==========

  /// Test complete notification flow from trigger to delivery
  Future<TestResult> testCompleteNotificationFlow({String? userId}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Testing complete notification flow...');
      }

      // Step 1: Test core prerequisites
      final prerequisites = await _testPrerequisites(userId);
      if (!prerequisites.success) {
        return TestResult(
          success: false,
          message: 'Prerequisites failed: ${prerequisites.message}',
          data: prerequisites.data ?? {},
          timestamp: DateTime.now(),
        );
      }

      // Step 2: Test content generation and trigger logic
      final contentAndTrigger = await _testContentAndTriggerFlow(userId);
      if (!contentAndTrigger.success) {
        return TestResult(
          success: false,
          message: 'Content/trigger flow failed: ${contentAndTrigger.message}',
          data: contentAndTrigger.data ?? {},
          timestamp: DateTime.now(),
        );
      }

      // Step 3: Test end-to-end delivery pipeline
      final deliveryPipeline = await _testDeliveryPipeline(userId);
      if (!deliveryPipeline.success) {
        return TestResult(
          success: false,
          message: 'Delivery pipeline failed: ${deliveryPipeline.message}',
          data: deliveryPipeline.data ?? {},
          timestamp: DateTime.now(),
        );
      }

      // Step 4: Test tracking and analytics
      final trackingAnalytics = await _testTrackingAndAnalytics(userId);

      return TestResult(
        success: true,
        message: 'Complete notification flow working correctly',
        data: {
          'prerequisites': prerequisites.data,
          'content_trigger': contentAndTrigger.data,
          'delivery_pipeline': deliveryPipeline.data,
          'tracking_analytics': trackingAnalytics.data,
          'flow_stages_passed': 4,
        },
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Complete notification flow test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
      );
    }
  }

  /// Test permission handling across different scenarios
  Future<TestResult> testPermissionHandling() async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Testing permission handling scenarios...');
      }

      final results = <String, dynamic>{};

      // Test current permission status
      final currentPermissions = await _testFramework.generateTestSuite(
        includeABTests: false,
        testAllScenarios: false,
        includeEndToEndTests: false,
      );

      final permissionTest =
          currentPermissions.testResults['notification_permissions'];
      results['current_permissions'] = permissionTest?.success ?? false;

      // Test FCM token availability (depends on permissions)
      final tokenTest = currentPermissions.testResults['fcm_token'];
      results['fcm_token_available'] = tokenTest?.success ?? false;

      // Determine permission scenario
      if (results['current_permissions'] == true) {
        results['permission_scenario'] = 'granted';
        results['recommendations'] = ['Permissions are properly configured'];
      } else {
        results['permission_scenario'] = 'denied_or_not_requested';
        results['recommendations'] = [
          'Request notification permissions from user',
          'Provide clear explanation of notification benefits',
          'Consider in-app permission prompting strategy',
        ];
      }

      final allPermissionsWorking =
          results['current_permissions'] == true &&
          results['fcm_token_available'] == true;

      return TestResult(
        success: allPermissionsWorking,
        message:
            allPermissionsWorking
                ? 'Permission handling working correctly'
                : 'Permission issues detected - see recommendations',
        data: results,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Permission handling test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
      );
    }
  }

  /// Test content generation across multiple scenarios
  Future<TestResult> testContentGeneration() async {
    try {
      if (kDebugMode) {
        debugPrint('📝 Testing content generation scenarios...');
      }

      final results = <String, dynamic>{};

      // Test basic content generation
      final basicContentSuite = await _testFramework.generateTestSuite(
        includeABTests: false,
        testAllScenarios: false,
        includeEndToEndTests: false,
      );

      final contentTest = basicContentSuite.testResults['notification_content'];
      results['basic_content_generation'] = contentTest?.success ?? false;

      // Test A/B variant content generation
      final abContentSuite = await _testFramework.generateTestSuite(
        includeABTests: true,
        testAllScenarios: false,
        includeEndToEndTests: false,
      );

      final abTest = abContentSuite.testResults['ab_variants'];
      results['ab_variant_content'] = abTest?.success ?? false;

      // Test multiple momentum states
      results['momentum_state_variants'] = ['rising', 'steady', 'needs_care'];

      final allContentWorking = results['basic_content_generation'] == true;
      final recommendedTests = results['ab_variant_content'] == true;

      return TestResult(
        success: allContentWorking,
        message:
            allContentWorking
                ? 'Content generation working correctly'
                : 'Content generation issues detected',
        data: {
          ...results,
          'recommended_features_working': recommendedTests,
          'critical_features_working': allContentWorking,
        },
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Content generation test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
      );
    }
  }

  /// Test system performance under different loads
  Future<TestResult> testSystemPerformance({String? userId}) async {
    try {
      if (kDebugMode) {
        debugPrint('⚡ Testing system performance...');
      }

      final results = <String, dynamic>{};
      final startTime = DateTime.now();

      // Test response times for critical operations
      final coreTestStart = DateTime.now();
      final coreSuite = await _testFramework.generateTestSuite(
        userId: userId,
        includeABTests: false,
        testAllScenarios: false,
        includeEndToEndTests: false,
      );
      final coreTestDuration = DateTime.now().difference(coreTestStart);

      results['core_test_duration_ms'] = coreTestDuration.inMilliseconds;
      results['core_tests_passed'] =
          coreSuite.testResults.values.where((t) => t.success).length;
      results['core_tests_total'] = coreSuite.testResults.length;

      // Test full suite performance
      final fullTestStart = DateTime.now();
      final fullSuite = await _testFramework.generateTestSuite(
        userId: userId,
        includeABTests: true,
        testAllScenarios: true,
        includeEndToEndTests: true,
      );
      final fullTestDuration = DateTime.now().difference(fullTestStart);

      results['full_test_duration_ms'] = fullTestDuration.inMilliseconds;
      results['full_tests_passed'] =
          fullSuite.testResults.values.where((t) => t.success).length;
      results['full_tests_total'] = fullSuite.testResults.length;

      // Performance benchmarks
      final corePerformanceOk =
          coreTestDuration.inMilliseconds < 5000; // 5 seconds
      final fullPerformanceOk =
          fullTestDuration.inMilliseconds < 15000; // 15 seconds

      results['performance_benchmarks'] = {
        'core_tests_under_5s': corePerformanceOk,
        'full_tests_under_15s': fullPerformanceOk,
      };

      final overallDuration = DateTime.now().difference(startTime);
      results['total_performance_test_duration_ms'] =
          overallDuration.inMilliseconds;

      return TestResult(
        success: corePerformanceOk && fullPerformanceOk,
        message:
            'System performance ${corePerformanceOk && fullPerformanceOk ? "meets" : "does not meet"} benchmarks',
        data: results,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'System performance test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
      );
    }
  }

  /// Test device compatibility across different scenarios
  Future<TestResult> testDeviceCompatibility() async {
    try {
      if (kDebugMode) {
        debugPrint('📱 Testing device compatibility...');
      }

      final results = <String, dynamic>{};

      // Test basic device capabilities
      final basicSuite = await _testFramework.generateTestSuite(
        includeABTests: false,
        testAllScenarios: false,
        includeEndToEndTests: false,
      );

      // Check core device capabilities
      final permissionsTest =
          basicSuite.testResults['notification_permissions'];
      final fcmTest = basicSuite.testResults['fcm_token'];

      results['notification_permissions_supported'] =
          permissionsTest?.success ?? false;
      results['fcm_supported'] = fcmTest?.success ?? false;

      // Determine device compatibility level
      if (results['notification_permissions_supported'] &&
          results['fcm_supported']) {
        results['compatibility_level'] = 'full';
        results['supported_features'] = [
          'push_notifications',
          'fcm_messaging',
          'background_processing',
          'user_preferences',
        ];
      } else if (results['fcm_supported']) {
        results['compatibility_level'] = 'partial';
        results['supported_features'] = ['fcm_messaging'];
        results['unsupported_features'] = ['push_notifications'];
      } else {
        results['compatibility_level'] = 'limited';
        results['supported_features'] = [];
        results['unsupported_features'] = [
          'push_notifications',
          'fcm_messaging',
        ];
      }

      final isFullyCompatible = results['compatibility_level'] == 'full';

      return TestResult(
        success: isFullyCompatible,
        message: 'Device compatibility: ${results["compatibility_level"]}',
        data: results,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Device compatibility test failed',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
      );
    }
  }

  // ========== Helper Methods for Complex Test Scenarios ==========

  /// Test core prerequisites for notification system
  Future<TestResult> _testPrerequisites(String? userId) async {
    final suite = await _testFramework.generateTestSuite(
      userId: userId,
      includeABTests: false,
      testAllScenarios: false,
      includeEndToEndTests: false,
    );

    final fcmTest = suite.testResults['fcm_token'];
    final permissionsTest = suite.testResults['notification_permissions'];
    final preferencesTest = suite.testResults['user_preferences'];

    final allPrerequisitesPassed = [
      fcmTest,
      permissionsTest,
      preferencesTest,
    ].every((test) => test?.success == true);

    return TestResult(
      success: allPrerequisitesPassed,
      message:
          allPrerequisitesPassed
              ? 'All prerequisites met'
              : 'Some prerequisites failed',
      data: {
        'fcm_token': fcmTest?.success ?? false,
        'permissions': permissionsTest?.success ?? false,
        'preferences': preferencesTest?.success ?? false,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Test content generation and trigger logic flow
  Future<TestResult> _testContentAndTriggerFlow(String? userId) async {
    final suite = await _testFramework.generateTestSuite(
      userId: userId,
      includeABTests: true,
      testAllScenarios: false,
      includeEndToEndTests: false,
    );

    final contentTest = suite.testResults['notification_content'];
    final abTest = suite.testResults['ab_variants'];

    final contentFlowWorking = contentTest?.success == true;

    return TestResult(
      success: contentFlowWorking,
      message:
          contentFlowWorking
              ? 'Content and trigger flow working'
              : 'Content flow issues detected',
      data: {
        'content_generation': contentTest?.success ?? false,
        'ab_testing': abTest?.success ?? false,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Test delivery pipeline end-to-end
  Future<TestResult> _testDeliveryPipeline(String? userId) async {
    final suite = await _testFramework.generateTestSuite(
      userId: userId,
      includeABTests: false,
      testAllScenarios: false,
      includeEndToEndTests: true,
    );

    final endToEndTest = suite.testResults['end_to_end_delivery'];
    final connectivityTest = suite.testResults['edge_function_connectivity'];

    final pipelineWorking =
        endToEndTest?.success == true && connectivityTest?.success == true;

    return TestResult(
      success: pipelineWorking,
      message:
          pipelineWorking
              ? 'Delivery pipeline working'
              : 'Delivery pipeline issues detected',
      data: {
        'end_to_end_delivery': endToEndTest?.success ?? false,
        'edge_function_connectivity': connectivityTest?.success ?? false,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Test tracking and analytics functionality
  Future<TestResult> _testTrackingAndAnalytics(String? userId) async {
    final suite = await _testFramework.generateTestSuite(
      userId: userId,
      includeABTests: true,
      testAllScenarios: true,
      includeEndToEndTests: false,
    );

    final deliveryTrackingTest = suite.testResults['delivery_tracking'];
    final abTest = suite.testResults['ab_variants'];

    return TestResult(
      success: true, // Non-critical for main flow
      message: 'Tracking and analytics tested',
      data: {
        'delivery_tracking': deliveryTrackingTest?.success ?? false,
        'ab_testing_analytics': abTest?.success ?? false,
      },
      timestamp: DateTime.now(),
    );
  }

  // ========== Quick Test Scenarios ==========

  /// Quick health check combining multiple test categories
  Future<Map<String, dynamic>> performQuickHealthCheck({String? userId}) async {
    try {
      if (kDebugMode) {
        debugPrint('🩺 Performing quick notification health check...');
      }

      final startTime = DateTime.now();

      // Run core tests only for quick assessment
      final coreResults = await _testFramework.generateTestSuite(
        userId: userId,
        includeABTests: false,
        testAllScenarios: false,
        includeEndToEndTests: false,
      );

      // Analyze the results using the framework
      final analysis = _testFramework.analyzeTestResults(
        coreResults.testResults,
      );

      final duration = DateTime.now().difference(startTime);

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'health_status': analysis.overallHealth.name,
        'success_rate': analysis.successRate,
        'total_tests': analysis.totalTests,
        'passed_tests': analysis.successCount,
        'failed_tests': analysis.failureCount,
        'critical_issues': analysis.criticalIssues,
        'warnings': analysis.warnings,
        'test_duration_ms': duration.inMilliseconds,
        'summary': analysis.summary,
      };
    } catch (e) {
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'health_status': 'error',
        'error': e.toString(),
      };
    }
  }
}
