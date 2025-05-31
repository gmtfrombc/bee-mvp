import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_test_generator.dart';
import 'notification_test_validator.dart';

/// Service for testing notification delivery across different scenarios
/// Coordinates test generation and validation through extracted components
class NotificationTestingService {
  static NotificationTestingService? _instance;
  static NotificationTestingService get instance {
    _instance ??= NotificationTestingService._();
    return _instance!;
  }

  NotificationTestingService._();

  final _testGenerator = NotificationTestGenerator();
  final _testValidator = NotificationTestValidator();

  /// Run comprehensive notification delivery tests
  /// This is the main entry point that coordinates test generation and validation
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

      // Use the test generator to create and execute all tests
      final testResults = await _testGenerator.generateTestSuite(
        userId: userId,
        includeABTests: includeABTests,
        testAllScenarios: testAllScenarios,
        includeEndToEndTests: includeEndToEndTests,
      );

      // Add all test results to the results container
      for (final entry in testResults.entries) {
        results.addTest(entry.key, entry.value);
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

  /// Generate test report using the validator
  /// Delegates to NotificationTestValidator
  Future<String> generateTestReport(NotificationTestResults results) async {
    return _testValidator.generateTestReport(results);
  }

  /// Generate recommendations based on test results
  /// Delegates to NotificationTestValidator
  String generateRecommendations(NotificationTestResults results) {
    return _testValidator.generateRecommendations(results);
  }

  /// Analyze test results for insights and health assessment
  /// Delegates to NotificationTestValidator
  NotificationTestAnalysis analyzeTestResults(
    Map<String, TestResult> testResults,
  ) {
    return _testValidator.analyzeTestResults(testResults);
  }

  /// Validate specific test categories
  /// Delegates to NotificationTestValidator
  TestCategoryValidation validateTestCategory(
    String category,
    Map<String, TestResult> testResults,
  ) {
    return _testValidator.validateTestCategory(category, testResults);
  }

  /// Check if notification system is ready for production
  /// Delegates to NotificationTestValidator
  ProductionReadinessCheck checkProductionReadiness(
    Map<String, TestResult> testResults,
  ) {
    return _testValidator.checkProductionReadiness(testResults);
  }

  /// Validate test results against performance benchmarks
  /// Delegates to NotificationTestValidator
  PerformanceBenchmarkValidation validatePerformanceBenchmarks(
    Map<String, TestResult> testResults,
  ) {
    return _testValidator.validatePerformanceBenchmarks(testResults);
  }

  /// Generate detailed error analysis
  /// Delegates to NotificationTestValidator
  ErrorAnalysis analyzeErrors(Map<String, TestResult> testResults) {
    return _testValidator.analyzeErrors(testResults);
  }

  /// Run individual test methods (exposed for granular testing)
  /// These delegate directly to the test generator

  /// Test FCM token validation
  Future<TestResult> testFCMToken(String? userId) async {
    return _testGenerator.testFCMToken(userId);
  }

  /// Test user preferences compliance
  Future<TestResult> testUserPreferences(String? userId) async {
    return _testGenerator.testUserPreferences(userId);
  }

  /// Test notification permissions
  Future<TestResult> testNotificationPermissions() async {
    return _testGenerator.testNotificationPermissions();
  }

  /// Test Supabase Edge Function connectivity
  Future<TestResult> testEdgeFunctionConnectivity(String? userId) async {
    return _testGenerator.testEdgeFunctionConnectivity(userId);
  }

  /// Test database connectivity
  Future<TestResult> testDatabaseConnectivity(String? userId) async {
    return _testGenerator.testDatabaseConnectivity(userId);
  }

  /// Test token refresh mechanism
  Future<TestResult> testTokenRefresh() async {
    return _testGenerator.testTokenRefresh();
  }

  /// Test A/B testing variants
  Future<TestResult> testABVariants(String? userId) async {
    return _testGenerator.testABVariants(userId);
  }

  /// Test notification content generation
  Future<TestResult> testNotificationContent() async {
    return _testGenerator.testNotificationContent();
  }

  /// Test end-to-end notification delivery
  Future<TestResult> testEndToEndDelivery(String? userId) async {
    return _testGenerator.testEndToEndDelivery(userId);
  }

  /// Test notification rate limiting
  Future<TestResult> testRateLimiting(String? userId) async {
    return _testGenerator.testRateLimiting(userId);
  }

  /// Test notification delivery tracking
  Future<TestResult> testDeliveryTracking() async {
    return _testGenerator.testDeliveryTracking();
  }

  /// Quick health check for immediate status assessment
  Future<Map<String, dynamic>> quickHealthCheck({String? userId}) async {
    try {
      if (kDebugMode) {
        print('🩺 Running quick notification health check...');
      }

      // Run core tests only for quick assessment
      final coreTests = <String, TestResult>{};
      coreTests['fcm_token'] = await testFCMToken(userId);
      coreTests['notification_permissions'] =
          await testNotificationPermissions();
      coreTests['edge_function_connectivity'] =
          await testEdgeFunctionConnectivity(userId);

      // Analyze the results
      final analysis = analyzeTestResults(coreTests);

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'overall_health': analysis.overallHealth.name,
        'success_rate': (analysis.successRate * 100).toStringAsFixed(1),
        'tests_run': analysis.totalTests,
        'tests_passed': analysis.successCount,
        'critical_issues': analysis.criticalIssues.length,
        'warnings': analysis.warnings.length,
        'summary': analysis.summary,
        'is_healthy':
            analysis.overallHealth == NotificationSystemHealth.excellent ||
            analysis.overallHealth == NotificationSystemHealth.good,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Quick health check failed: $e');
      }
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'overall_health': 'error',
        'error': e.toString(),
        'is_healthy': false,
      };
    }
  }

  /// Get service information and capabilities
  Map<String, dynamic> getServiceInfo() {
    return {
      'service_name': 'NotificationTestingService',
      'version': '2.0.0',
      'architecture': 'modular',
      'components': ['NotificationTestGenerator', 'NotificationTestValidator'],
      'capabilities': [
        'Comprehensive test suite execution',
        'Individual test case generation',
        'Test result validation and analysis',
        'Production readiness assessment',
        'Performance benchmark validation',
        'Error analysis and recommendations',
        'Quick health checks',
      ],
      'test_categories': [
        'core_functionality',
        'connectivity',
        'content_generation',
        'end_to_end',
      ],
      'last_refactored': '2024-12-30',
      'size_reduction':
          'Reduced from 686 lines to ~250 lines via component extraction',
    };
  }
}

/// Riverpod provider for notification testing service
final notificationTestingServiceProvider = Provider<NotificationTestingService>(
  (ref) {
    return NotificationTestingService.instance;
  },
);
