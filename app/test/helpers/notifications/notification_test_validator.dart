import 'notification_test_generator.dart';

/// Service for validating and analyzing notification test results
class NotificationTestValidator {
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

  /// Validate test results and provide analysis
  NotificationTestAnalysis analyzeTestResults(
    Map<String, TestResult> testResults,
  ) {
    final analysis = NotificationTestAnalysis();

    // Count successes and failures
    final successCount = testResults.values.where((r) => r.success).length;
    final failureCount = testResults.length - successCount;

    analysis.totalTests = testResults.length;
    analysis.successCount = successCount;
    analysis.failureCount = failureCount;
    analysis.successRate = successCount / testResults.length;

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
            criticalIssues.add('$testName: ${result.message}');
            break;
          case 'database_connectivity':
          case 'end_to_end_delivery':
            warnings.add('$testName: ${result.message}');
            break;
          default:
            informational.add('$testName: ${result.message}');
        }
      }
    }

    analysis.criticalIssues = criticalIssues;
    analysis.warnings = warnings;
    analysis.informational = informational;

    // Determine overall health
    if (criticalIssues.isEmpty && warnings.isEmpty) {
      analysis.overallHealth = NotificationSystemHealth.excellent;
    } else if (criticalIssues.isEmpty && warnings.length <= 1) {
      analysis.overallHealth = NotificationSystemHealth.good;
    } else if (criticalIssues.length <= 1) {
      analysis.overallHealth = NotificationSystemHealth.fair;
    } else {
      analysis.overallHealth = NotificationSystemHealth.poor;
    }

    // Generate summary
    analysis.summary = _generateSummary(analysis);

    return analysis;
  }

  /// Validate specific test categories
  TestCategoryValidation validateTestCategory(
    String category,
    Map<String, TestResult> testResults,
  ) {
    final validation = TestCategoryValidation(category: category);

    switch (category) {
      case 'core_functionality':
        validation.tests = _getCoreTests(testResults);
        break;
      case 'connectivity':
        validation.tests = _getConnectivityTests(testResults);
        break;
      case 'content_generation':
        validation.tests = _getContentTests(testResults);
        break;
      case 'end_to_end':
        validation.tests = _getEndToEndTests(testResults);
        break;
      default:
        validation.tests = testResults;
    }

    validation.calculateMetrics();
    return validation;
  }

  /// Check if notification system is ready for production
  ProductionReadinessCheck checkProductionReadiness(
    Map<String, TestResult> testResults,
  ) {
    final check = ProductionReadinessCheck();

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

    check.criticalTestsPassed = passedCritical;
    check.criticalTestsFailed = failedCritical;
    check.isProductionReady = failedCritical.isEmpty;

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

    check.optionalTestsPassed = optionalPassed;
    check.optionalTestsFailed = optionalFailed;

    // Generate production readiness report
    check.report = _generateProductionReport(check);

    return check;
  }

  /// Validate test results against performance benchmarks
  PerformanceBenchmarkValidation validatePerformanceBenchmarks(
    Map<String, TestResult> testResults,
  ) {
    final validation = PerformanceBenchmarkValidation();

    // Extract performance metrics from test results
    final tokenTest = testResults['fcm_token'];
    if (tokenTest != null && tokenTest.success) {
      final tokenLength = tokenTest.details['token_length'] as int? ?? 0;
      validation.fcmTokenValid =
          tokenLength > 100; // FCM tokens are typically 152+ chars
    }

    final connectivityTest = testResults['edge_function_connectivity'];
    if (connectivityTest != null) {
      final statusCode = connectivityTest.details['status_code'] as int? ?? 0;
      validation.edgeFunctionResponseTime = statusCode == 200 ? 'good' : 'poor';
    }

    final endToEndTest = testResults['end_to_end_delivery'];
    if (endToEndTest != null && endToEndTest.success) {
      final processed =
          endToEndTest.details['notifications_processed'] as int? ?? 0;
      validation.deliveryPipelineEfficiency =
          processed > 0 ? 'efficient' : 'needs_improvement';
    }

    validation.calculateOverallScore();
    return validation;
  }

  /// Generate detailed error analysis
  ErrorAnalysis analyzeErrors(Map<String, TestResult> testResults) {
    final analysis = ErrorAnalysis();

    for (final entry in testResults.entries) {
      final testName = entry.key;
      final result = entry.value;

      if (!result.success) {
        final error = TestError(
          testName: testName,
          errorMessage: result.message,
          details: result.details,
          category: _categorizeError(testName),
          severity: _determineSeverity(testName),
        );
        analysis.errors.add(error);
      }
    }

    analysis.generateSolutions();
    return analysis;
  }

  // Helper methods
  String _generateSummary(NotificationTestAnalysis analysis) {
    final buffer = StringBuffer();

    buffer.writeln('Test Results Summary:');
    buffer.writeln('- Total Tests: ${analysis.totalTests}');
    buffer.writeln(
      '- Success Rate: ${(analysis.successRate * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln('- Overall Health: ${analysis.overallHealth.name}');

    if (analysis.criticalIssues.isNotEmpty) {
      buffer.writeln('- Critical Issues: ${analysis.criticalIssues.length}');
    }

    if (analysis.warnings.isNotEmpty) {
      buffer.writeln('- Warnings: ${analysis.warnings.length}');
    }

    return buffer.toString();
  }

  Map<String, TestResult> _getCoreTests(Map<String, TestResult> allTests) {
    const coreTestNames = [
      'fcm_token',
      'notification_permissions',
      'user_preferences',
    ];
    return Map.fromEntries(
      allTests.entries.where((entry) => coreTestNames.contains(entry.key)),
    );
  }

  Map<String, TestResult> _getConnectivityTests(
    Map<String, TestResult> allTests,
  ) {
    const connectivityTestNames = [
      'edge_function_connectivity',
      'database_connectivity',
    ];
    return Map.fromEntries(
      allTests.entries.where(
        (entry) => connectivityTestNames.contains(entry.key),
      ),
    );
  }

  Map<String, TestResult> _getContentTests(Map<String, TestResult> allTests) {
    const contentTestNames = ['notification_content', 'ab_variants'];
    return Map.fromEntries(
      allTests.entries.where((entry) => contentTestNames.contains(entry.key)),
    );
  }

  Map<String, TestResult> _getEndToEndTests(Map<String, TestResult> allTests) {
    const endToEndTestNames = [
      'end_to_end_delivery',
      'rate_limiting',
      'delivery_tracking',
    ];
    return Map.fromEntries(
      allTests.entries.where((entry) => endToEndTestNames.contains(entry.key)),
    );
  }

  String _generateProductionReport(ProductionReadinessCheck check) {
    final buffer = StringBuffer();

    buffer.writeln('# Production Readiness Report');
    buffer.writeln(
      'Status: ${check.isProductionReady ? "✅ READY" : "❌ NOT READY"}',
    );
    buffer.writeln();

    buffer.writeln('## Critical Tests');
    for (final test in check.criticalTestsPassed) {
      buffer.writeln('✅ $test');
    }
    for (final test in check.criticalTestsFailed) {
      buffer.writeln('❌ $test');
    }

    if (check.optionalTestsPassed.isNotEmpty ||
        check.optionalTestsFailed.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## Optional Tests');
      for (final test in check.optionalTestsPassed) {
        buffer.writeln('✅ $test');
      }
      for (final test in check.optionalTestsFailed) {
        buffer.writeln('⚠️ $test');
      }
    }

    return buffer.toString();
  }

  ErrorCategory _categorizeError(String testName) {
    switch (testName) {
      case 'fcm_token':
      case 'token_refresh':
        return ErrorCategory.configuration;
      case 'notification_permissions':
        return ErrorCategory.permissions;
      case 'edge_function_connectivity':
      case 'database_connectivity':
        return ErrorCategory.connectivity;
      case 'end_to_end_delivery':
      case 'delivery_tracking':
        return ErrorCategory.delivery;
      default:
        return ErrorCategory.general;
    }
  }

  ErrorSeverity _determineSeverity(String testName) {
    const criticalTests = [
      'fcm_token',
      'notification_permissions',
      'edge_function_connectivity',
    ];
    const highTests = ['user_preferences', 'end_to_end_delivery'];

    if (criticalTests.contains(testName)) {
      return ErrorSeverity.critical;
    } else if (highTests.contains(testName)) {
      return ErrorSeverity.high;
    } else {
      return ErrorSeverity.medium;
    }
  }
}

/// Overall test results container
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
      'tests': testResults.map((k, v) => MapEntry(k, v.toJson())),
      'errors': errors,
    };
  }
}

/// Analysis of test results
class NotificationTestAnalysis {
  int totalTests = 0;
  int successCount = 0;
  int failureCount = 0;
  double successRate = 0.0;
  NotificationSystemHealth overallHealth = NotificationSystemHealth.unknown;
  List<String> criticalIssues = [];
  List<String> warnings = [];
  List<String> informational = [];
  String summary = '';
}

/// Test category validation
class TestCategoryValidation {
  final String category;
  Map<String, TestResult> tests = {};
  int passCount = 0;
  int failCount = 0;
  double successRate = 0.0;

  TestCategoryValidation({required this.category});

  void calculateMetrics() {
    passCount = tests.values.where((r) => r.success).length;
    failCount = tests.length - passCount;
    successRate = tests.isNotEmpty ? passCount / tests.length : 0.0;
  }
}

/// Production readiness check
class ProductionReadinessCheck {
  bool isProductionReady = false;
  List<String> criticalTestsPassed = [];
  List<String> criticalTestsFailed = [];
  List<String> optionalTestsPassed = [];
  List<String> optionalTestsFailed = [];
  String report = '';
}

/// Performance benchmark validation
class PerformanceBenchmarkValidation {
  bool fcmTokenValid = false;
  String edgeFunctionResponseTime = 'unknown';
  String deliveryPipelineEfficiency = 'unknown';
  int overallScore = 0;

  void calculateOverallScore() {
    int score = 0;
    if (fcmTokenValid) score += 30;
    if (edgeFunctionResponseTime == 'good') score += 35;
    if (deliveryPipelineEfficiency == 'efficient') score += 35;
    overallScore = score;
  }
}

/// Error analysis results
class ErrorAnalysis {
  List<TestError> errors = [];
  List<String> solutions = [];

  void generateSolutions() {
    solutions.clear();
    for (final error in errors) {
      switch (error.category) {
        case ErrorCategory.configuration:
          solutions.add('Check Firebase configuration and FCM setup');
          break;
        case ErrorCategory.permissions:
          solutions.add('Request notification permissions from user');
          break;
        case ErrorCategory.connectivity:
          solutions.add('Verify network connectivity and service endpoints');
          break;
        case ErrorCategory.delivery:
          solutions.add('Check notification delivery pipeline configuration');
          break;
        case ErrorCategory.general:
          solutions.add('Review general system configuration');
          break;
      }
    }
  }
}

/// Individual test error
class TestError {
  final String testName;
  final String errorMessage;
  final Map<String, dynamic> details;
  final ErrorCategory category;
  final ErrorSeverity severity;

  TestError({
    required this.testName,
    required this.errorMessage,
    required this.details,
    required this.category,
    required this.severity,
  });
}

/// Enums for categorization
enum NotificationSystemHealth { excellent, good, fair, poor, unknown }

enum ErrorCategory {
  configuration,
  permissions,
  connectivity,
  delivery,
  general,
}

enum ErrorSeverity { critical, high, medium, low }
