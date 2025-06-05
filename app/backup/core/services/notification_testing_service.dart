import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifications/domain/models/notification_models.dart';
import '../notifications/testing/notification_test_framework.dart';
import '../notifications/testing/notification_integration_tests.dart';

/// Coordinator service for notification testing
/// Simplified in Sprint 2 to delegate to unified testing framework
/// Acts as backward-compatible interface while testing logic moved to framework
class NotificationTestingService {
  static NotificationTestingService? _instance;
  static NotificationTestingService get instance {
    _instance ??= NotificationTestingService._();
    return _instance!;
  }

  NotificationTestingService._();

  final _testFramework = NotificationTestFramework.instance;
  final _integrationTests = NotificationIntegrationTests.instance;

  /// Run comprehensive notification delivery tests
  /// This is the main entry point that coordinates test generation and validation
  Future<NotificationTestResults> runComprehensiveTests({
    String? userId,
    bool includeABTests = true,
    bool testAllScenarios = true,
    bool includeEndToEndTests = true,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Starting comprehensive notification tests...');
      }

      // Delegate to the unified testing framework
      final results = await _testFramework.generateTestSuite(
        userId: userId,
        includeABTests: includeABTests,
        testAllScenarios: testAllScenarios,
        includeEndToEndTests: includeEndToEndTests,
      );

      if (kDebugMode) {
        debugPrint(
          '✅ Notification tests completed. Success rate: ${(results.overallSuccess * 100).toStringAsFixed(1)}%',
        );
        debugPrint('📊 Tests run: ${results.testResults.length}');
        debugPrint(
          '✅ Passed: ${results.testResults.values.where((r) => r.success).length}',
        );
        debugPrint(
          '❌ Failed: ${results.testResults.values.where((r) => !r.success).length}',
        );
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error running notification tests: $e');
      }

      final results = NotificationTestResults(
        testResults: {},
        errors: {'comprehensive_test_error': e.toString()},
        overallSuccess: 0.0,
      );
      return results;
    }
  }

  /// Generate test report using the framework
  Future<String> generateTestReport(NotificationTestResults results) async {
    return _testFramework.generateTestReport(results);
  }

  /// Generate recommendations based on test results
  String generateRecommendations(NotificationTestResults results) {
    return _testFramework.generateRecommendations(results);
  }

  /// Analyze test results for insights and health assessment
  NotificationTestAnalysis analyzeTestResults(
    Map<String, TestResult> testResults,
  ) {
    return _testFramework.analyzeTestResults(testResults);
  }

  /// Check if notification system is ready for production
  ProductionReadinessCheck checkProductionReadiness(
    Map<String, TestResult> testResults,
  ) {
    return _testFramework.checkProductionReadiness(testResults);
  }

  // ========== High-Level Integration Test Methods ==========

  /// Test complete notification flow from trigger to delivery
  Future<TestResult> testCompleteNotificationFlow({String? userId}) async {
    return _integrationTests.testCompleteNotificationFlow(userId: userId);
  }

  /// Test permission handling across different scenarios
  Future<TestResult> testPermissionHandling() async {
    return _integrationTests.testPermissionHandling();
  }

  /// Test content generation across multiple scenarios
  Future<TestResult> testContentGeneration() async {
    return _integrationTests.testContentGeneration();
  }

  /// Test system performance under different loads
  Future<TestResult> testSystemPerformance({String? userId}) async {
    return _integrationTests.testSystemPerformance(userId: userId);
  }

  /// Test device compatibility across different scenarios
  Future<TestResult> testDeviceCompatibility() async {
    return _integrationTests.testDeviceCompatibility();
  }

  // ========== Individual Test Methods (Backward Compatibility) ==========

  /// Quick health check for immediate status assessment
  Future<Map<String, dynamic>> quickHealthCheck({String? userId}) async {
    return _integrationTests.performQuickHealthCheck(userId: userId);
  }

  // ========== Deprecated Methods (Maintained for Backward Compatibility) ==========
  // These delegate to the framework but are marked for future removal

  /// @deprecated Use testCompleteNotificationFlow instead
  Future<TestResult> testFCMToken(String? userId) async {
    final suite = await _testFramework.generateTestSuite(
      userId: userId,
      includeABTests: false,
      testAllScenarios: false,
      includeEndToEndTests: false,
    );
    return suite.testResults['fcm_token'] ??
        TestResult(
          success: false,
          message: 'FCM token test not found',
          data: {},
          timestamp: DateTime.now(),
        );
  }

  /// @deprecated Use testCompleteNotificationFlow instead
  Future<TestResult> testUserPreferences(String? userId) async {
    final suite = await _testFramework.generateTestSuite(
      userId: userId,
      includeABTests: false,
      testAllScenarios: false,
      includeEndToEndTests: false,
    );
    return suite.testResults['user_preferences'] ??
        TestResult(
          success: false,
          message: 'User preferences test not found',
          data: {},
          timestamp: DateTime.now(),
        );
  }

  /// @deprecated Use testPermissionHandling instead
  Future<TestResult> testNotificationPermissions() async {
    final suite = await _testFramework.generateTestSuite(
      includeABTests: false,
      testAllScenarios: false,
      includeEndToEndTests: false,
    );
    return suite.testResults['notification_permissions'] ??
        TestResult(
          success: false,
          message: 'Notification permissions test not found',
          data: {},
          timestamp: DateTime.now(),
        );
  }

  /// @deprecated Use testCompleteNotificationFlow instead
  Future<TestResult> testEdgeFunctionConnectivity(String? userId) async {
    final suite = await _testFramework.generateTestSuite(
      userId: userId,
      includeABTests: false,
      testAllScenarios: false,
      includeEndToEndTests: false,
    );
    return suite.testResults['edge_function_connectivity'] ??
        TestResult(
          success: false,
          message: 'Edge function connectivity test not found',
          data: {},
          timestamp: DateTime.now(),
        );
  }
}

/// Riverpod provider for notification testing service
final notificationTestingServiceProvider = Provider<NotificationTestingService>(
  (ref) {
    return NotificationTestingService.instance;
  },
);
