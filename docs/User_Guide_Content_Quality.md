# Today Feed Content Quality Service - User Guide

**Version:** 1.0  
**Epic:** 1.3 Today Feed (AI Daily Brief)  
**Task:** T1.3.5.9 - Content Quality Validation and Safety Monitoring  

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Core Features](#core-features)
4. [API Reference](#api-reference)
5. [Configuration](#configuration)
6. [Best Practices](#best-practices)
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)
9. [Performance Considerations](#performance-considerations)
10. [Integration Guide](#integration-guide)

---

## Overview

The Today Feed Content Quality Service is a comprehensive system for validating AI-generated health content, ensuring safety standards, and monitoring content quality in real-time. It provides automated content analysis, safety monitoring, alert management, and quality metrics tracking.

### Key Features

- **Content Validation**: Format, readability, and engagement analysis
- **Safety Monitoring**: Medical safety checks, misinformation detection
- **Real-time Alerts**: Stream-based notifications for quality issues
- **Quality Metrics**: Historical tracking and trend analysis
- **Modular Architecture**: Six specialized components working together

### System Components

```
TodayFeedContentQualityService (Main Orchestrator)
├── TodayFeedContentValidator (Format & Quality Analysis)
├── TodayFeedSafetyMonitor (Safety & Medical Checks)
├── TodayFeedQualityAlertManager (Alert Management)
├── TodayFeedQualityMetricsCalculator (Analytics & Metrics)
└── Data Models (Shared data structures)
```

---

## Quick Start

### 1. Initialize the Service

```dart
import 'package:app/features/today_feed/data/services/today_feed_content_quality_service.dart';

// Initialize the service (call once at app startup)
await TodayFeedContentQualityService.initialize();
```

### 2. Validate Content

```dart
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

// Create or get your content
final content = TodayFeedContent(
  id: 1,
  contentDate: DateTime.now(),
  title: 'How Walking Improves Your Health',
  summary: 'Research shows that regular walking can improve cardiovascular health...',
  topicCategory: HealthTopic.exercise,
  aiConfidenceScore: 0.85,
);

// Validate content quality
final result = await TodayFeedContentQualityService.validateContentQuality(content);

if (result.isValid) {
  print('✅ Content approved: ${result.overallQualityScore}');
} else {
  print('❌ Content needs review: ${result.issues}');
}
```

### 3. Monitor Alerts

```dart
// Listen for real-time quality alerts
TodayFeedContentQualityService.alertStream.listen((alert) {
  print('🚨 Alert: ${alert.message} (${alert.severity})');
  
  if (alert.severity == AlertSeverity.critical) {
    // Handle critical alerts immediately
    handleCriticalAlert(alert);
  }
});
```

### 4. Get Quality Metrics

```dart
// Get current quality metrics
final metrics = await TodayFeedContentQualityService.getQualityMetrics();

print('Quality Score: ${metrics.averageQualityScore}');
print('Safety Score: ${metrics.averageSafetyScore}');
print('Active Alerts: ${metrics.activeAlerts}');
```

---

## Core Features

### Content Validation

The service validates content across multiple dimensions:

#### Format Validation
- **Title Length**: 10-60 characters optimal
- **Summary Length**: 50-200 characters optimal  
- **Punctuation**: Proper sentence endings
- **Capitalization**: Appropriate title case

#### Readability Analysis
- **Sentence Complexity**: Average words per sentence
- **Word Complexity**: Complex word ratio analysis
- **Sentence Variety**: Variance in sentence lengths
- **Overall Score**: 0.6+ threshold for approval

#### Engagement Scoring
- **Engagement Words**: "research", "discover", "proven", etc.
- **Actionable Language**: "how to", "tips", "guide"
- **Personal Pronouns**: "you", "your" for connection
- **Questions**: Curiosity-driving content
- **Numbers**: Specific data points

### Safety Monitoring

Comprehensive safety checks for health content:

#### Medical Safety
- **Prohibited Terms**: "diagnose", "cure", "prescription"
- **Directive Language**: "you should", "must", "always"
- **Inappropriate Claims**: Disease cure claims
- **Consultation Advice**: Encourages professional consultation

#### Content Appropriateness
- **Inappropriate Terms**: "dangerous", "extreme", "toxic"
- **Sensationalized Language**: "shocking", "unbelievable"
- **Fear-based Content**: "scary", "terrifying", "alarming"

#### Misinformation Detection
- **Absolute Claims**: "proven fact", "guaranteed", "100%"
- **Conspiracy Language**: "big pharma", "cover-up", "secret cure"
- **Unsupported Superlatives**: "best", "only way", "never fails"

### Alert Management

Real-time alert system with multiple severity levels:

#### Alert Types
- **Quality Issues**: Format, readability, engagement problems
- **Safety Issues**: Medical safety violations
- **Performance Issues**: System performance alerts
- **User Feedback**: User-reported content issues

#### Alert Severities
- **Low**: Minor improvements suggested
- **Medium**: Notable issues requiring attention
- **High**: Significant problems needing resolution
- **Critical**: Immediate action required

### Quality Metrics

Comprehensive analytics and trend tracking:

#### Key Metrics
- **Overall Quality Score**: Weighted average (0.7+ threshold)
- **Safety Score**: Medical safety rating (0.8+ threshold)
- **Validation Volume**: Number of validations over time
- **Alert Frequency**: Alert generation trends
- **Trend Analysis**: Quality improvements or decline

---

## API Reference

### Main Service Methods

#### `initialize()`
Initializes all modular components.
```dart
static Future<void> initialize()
```

#### `validateContentQuality(content)`
Validates content and returns comprehensive results.
```dart
static Future<QualityValidationResult> validateContentQuality(TodayFeedContent content)
```

**Returns:** `QualityValidationResult`
- `isValid`: Boolean validation status
- `overallQualityScore`: Weighted quality score (0.0-1.0)
- `safetyScore`: Safety validation score (0.0-1.0)
- `readabilityScore`: Readability analysis score (0.0-1.0)
- `engagementScore`: Engagement potential score (0.0-1.0)
- `issues`: List of critical issues found
- `warnings`: List of minor issues found
- `recommendations`: Suggested improvements

#### `monitorContentSafety(content)`
Performs safety-specific monitoring.
```dart
static Future<SafetyMonitoringResult> monitorContentSafety(TodayFeedContent content)
```

#### `analyzeContent(content)`
Comprehensive analysis with parallel execution.
```dart
static Future<ContentAnalysisResult> analyzeContent(TodayFeedContent content)
```

**Returns:** `ContentAnalysisResult`
- `validationResult`: Quality validation details
- `safetyResult`: Safety monitoring details
- `safetySummary`: Safety risk assessment
- `overallRecommendation`: APPROVE/REVIEW/REJECT

### Alert Management

#### `alertStream`
Real-time alert notifications.
```dart
static Stream<QualityAlert> get alertStream
```

#### `getQualityAlerts()`
Retrieve stored alerts with filtering.
```dart
static Future<List<QualityAlert>> getQualityAlerts({
  AlertSeverity? severity,
  AlertType? type,
  bool? resolved,
  String? contentId,
})
```

#### `resolveAlert(alertId)`
Mark an alert as resolved.
```dart
static Future<bool> resolveAlert(String alertId)
```

#### `bulkResolveAlerts()`
Resolve multiple alerts by criteria.
```dart
static Future<int> bulkResolveAlerts({
  AlertSeverity? severity,
  AlertType? type,
  String? contentId,
})
```

### Metrics and Analytics

#### `getQualityMetrics()`
Current quality metrics and trends.
```dart
static Future<QualityMetrics> getQualityMetrics()
```

#### `getQualityAnalytics()`
Detailed analytics and performance data.
```dart
static Future<QualityAnalytics> getQualityAnalytics()
```

#### `getValidationHistory()`
Historical validation data.
```dart
static Future<List<QualityValidationResult>> getValidationHistory({
  int? limit,
  DateTime? since,
})
```

### Utility Methods

#### `generateSafetySummary(result)`
Generate safety risk summary.
```dart
static SafetySummary generateSafetySummary(SafetyMonitoringResult result)
```

#### `requiresImmediateReview(result)`
Check if content needs immediate review.
```dart
static bool requiresImmediateReview(SafetyMonitoringResult result)
```

#### `clearCache()`
Clear validation cache and history.
```dart
static Future<void> clearCache()
```

#### `dispose()`
Clean up resources (call at app shutdown).
```dart
static Future<void> dispose()
```

---

## Configuration

### Quality Thresholds

The system uses configurable quality thresholds:

```dart
// Default thresholds (in TodayFeedContentQualityService)
static const double _minSafetyScore = 0.8;           // Safety threshold
static const double _minOverallQualityScore = 0.7;  // Overall quality threshold

// Validator thresholds (in TodayFeedContentValidator)
static const double _minReadabilityScore = 0.6;     // Readability threshold
static const double _minEngagementScore = 0.5;      // Engagement threshold
static const double _minFormatScore = 0.7;          // Format threshold
```

### Scoring Weights

Content scores use weighted calculations:

```dart
// Overall quality score weighting
final overallScore = (formatScore * 0.15) +      // Format: 15%
                    (safetyScore * 0.35) +       // Safety: 35% (prioritized)
                    (readabilityScore * 0.20) +  // Readability: 20%
                    (engagementScore * 0.15) +   // Engagement: 15%
                    (confidenceScore * 0.15);    // AI Confidence: 15%
```

### Storage Limits

```dart
// Alert storage (in TodayFeedQualityAlertManager)
static const int _maxAlertHistory = 100;

// Validation history (in TodayFeedQualityMetricsCalculator)
static const int _maxValidationHistory = 200;
```

---

## Best Practices

### Content Validation Workflow

1. **Pre-Generation Validation**
   ```dart
   // Validate content parameters before AI generation
   if (title.length > 60 || summary.length > 200) {
     // Adjust parameters
   }
   ```

2. **Post-Generation Validation**
   ```dart
   final result = await TodayFeedContentQualityService.validateContentQuality(content);
   
   if (!result.isValid) {
     // Log issues and regenerate or manually review
     logValidationIssues(result.issues);
     return await regenerateContent(contentParams);
   }
   ```

3. **Safety-First Approach**
   ```dart
   if (result.safetyScore < 0.8) {
     // Always reject unsafe content regardless of other scores
     return ContentStatus.rejected;
   }
   ```

### Alert Handling

1. **Critical Alerts**
   ```dart
   TodayFeedContentQualityService.alertStream.listen((alert) {
     if (alert.severity == AlertSeverity.critical) {
       // Immediate notification to content team
       notifyContentTeam(alert);
       
       // Block content publication
       blockContent(alert.contentId);
     }
   });
   ```

2. **Alert Resolution**
   ```dart
   // Regular alert cleanup
   Timer.periodic(Duration(hours: 6), (_) async {
     await TodayFeedContentQualityService.clearOldAlerts(
       olderThan: Duration(days: 30)
     );
   });
   ```

### Performance Optimization

1. **Batch Validation**
   ```dart
   // For multiple content pieces, use parallel processing
   final futures = contents.map((content) => 
     TodayFeedContentQualityService.validateContentQuality(content)
   );
   final results = await Future.wait(futures);
   ```

2. **Selective Analysis**
   ```dart
   // Use specific methods for targeted analysis
   if (onlySafetyCheck) {
     final safetyResult = await TodayFeedContentQualityService.monitorContentSafety(content);
   } else {
     final fullAnalysis = await TodayFeedContentQualityService.analyzeContent(content);
   }
   ```

### Error Handling

```dart
try {
  final result = await TodayFeedContentQualityService.validateContentQuality(content);
  // Handle result
} catch (e) {
  // Log error and use fallback validation
  logger.error('Content validation failed', error: e);
  
  // Basic fallback checks
  if (content.title.isEmpty || content.summary.isEmpty) {
    return QualityValidationResult.error(
      contentId: content.id.toString(),
      errorMessage: 'Content validation service unavailable',
    );
  }
}
```

---

## Examples

### Example 1: High-Quality Content

```dart
final content = TodayFeedContent(
  id: 1,
  contentDate: DateTime.now(),
  title: 'How Simple Walking Can Improve Your Health',
  summary: 'Research shows that regular walking may help improve cardiovascular health and mental wellbeing. Consider adding a daily walk to your routine.',
  topicCategory: HealthTopic.exercise,
  aiConfidenceScore: 0.85,
);

final result = await TodayFeedContentQualityService.validateContentQuality(content);

// Expected result:
// isValid: true
// overallQualityScore: ~0.87
// safetyScore: ~0.95
// recommendation: "APPROVE - Content meets high standards"
```

### Example 2: Unsafe Content Detection

```dart
final unsafeContent = TodayFeedContent(
  id: 2,
  contentDate: DateTime.now(),
  title: 'Cure Your Disease Instantly with This Secret Medicine',
  summary: 'This dangerous medication will cure everything. You should take it immediately without consulting your doctor.',
  topicCategory: HealthTopic.prevention,
  aiConfidenceScore: 0.7,
);

final result = await TodayFeedContentQualityService.validateContentQuality(content);

// Expected result:
// isValid: false
// safetyScore: ~0.25 (very low)
// issues: ['Contains prohibited medical term: cure', 'Contains medical advice']
// recommendation: "REJECT - Content has safety issues"
```

### Example 3: Alert Monitoring

```dart
class ContentQualityMonitor {
  StreamSubscription<QualityAlert>? _alertSubscription;
  
  void startMonitoring() {
    _alertSubscription = TodayFeedContentQualityService.alertStream.listen((alert) {
      switch (alert.severity) {
        case AlertSeverity.critical:
          handleCriticalAlert(alert);
          break;
        case AlertSeverity.high:
          handleHighPriorityAlert(alert);
          break;
        case AlertSeverity.medium:
        case AlertSeverity.low:
          logAlert(alert);
          break;
      }
    });
  }
  
  void handleCriticalAlert(QualityAlert alert) {
    // Immediate action for critical alerts
    NotificationService.sendUrgentNotification(
      'Critical content quality alert: ${alert.message}'
    );
    
    // Block content if it has an ID
    if (alert.contentId != null) {
      ContentService.blockContent(alert.contentId!);
    }
  }
  
  void dispose() {
    _alertSubscription?.cancel();
  }
}
```

### Example 4: Quality Dashboard

```dart
class QualityDashboard extends StatefulWidget {
  @override
  _QualityDashboardState createState() => _QualityDashboardState();
}

class _QualityDashboardState extends State<QualityDashboard> {
  QualityMetrics? metrics;
  List<QualityAlert> activeAlerts = [];
  
  @override
  void initState() {
    super.initState();
    loadDashboardData();
    
    // Auto-refresh every 5 minutes
    Timer.periodic(Duration(minutes: 5), (_) => loadDashboardData());
  }
  
  Future<void> loadDashboardData() async {
    final [metricsResult, alertsResult] = await Future.wait([
      TodayFeedContentQualityService.getQualityMetrics(),
      TodayFeedContentQualityService.getQualityAlerts(resolved: false),
    ]);
    
    setState(() {
      metrics = metricsResult;
      activeAlerts = alertsResult;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Content Quality Dashboard')),
      body: metrics == null 
        ? CircularProgressIndicator()
        : Column(
            children: [
              QualityMetricsCard(metrics: metrics!),
              ActiveAlertsCard(alerts: activeAlerts),
              QualityTrendsChart(metrics: metrics!),
            ],
          ),
    );
  }
}
```

---

## Troubleshooting

### Common Issues

#### Service Not Initialized
**Error:** `StateError: TodayFeedContentQualityService not initialized`

**Solution:**
```dart
// Ensure initialization before use
await TodayFeedContentQualityService.initialize();
```

#### High Memory Usage
**Issue:** Service consuming too much memory

**Solutions:**
```dart
// Regular cleanup
await TodayFeedContentQualityService.clearCache();
await TodayFeedContentQualityService.clearOldAlerts();

// Dispose when not needed
await TodayFeedContentQualityService.dispose();
```

#### Alert Stream Not Working
**Issue:** Not receiving real-time alerts

**Check:**
```dart
// Ensure service is initialized
await TodayFeedContentQualityService.initialize();

// Check stream subscription
final subscription = TodayFeedContentQualityService.alertStream.listen(
  (alert) => print('Alert received: ${alert.message}'),
  onError: (error) => print('Alert stream error: $error'),
);
```

#### Low Performance
**Issue:** Validation taking too long

**Optimizations:**
```dart
// Use parallel processing for multiple validations
final futures = contents.map(TodayFeedContentQualityService.validateContentQuality);
final results = await Future.wait(futures);

// Use specific methods for targeted checks
final safetyOnly = await TodayFeedContentQualityService.monitorContentSafety(content);
```

### Debug Mode

Enable debug logging for troubleshooting:

```dart
// The service automatically logs to debugPrint in debug mode
// Look for these prefixes in logs:
// ✅ - Successful operations
// ❌ - Errors
// ⚠️ - Warnings
// 🧹 - Cleanup operations
```

### Validation Issues

#### Content Always Rejected
Check content against quality thresholds:

```dart
final validator = TodayFeedContentValidator.validateContent(content);
print('Format Score: ${validator.formatResult.formatScore}');
print('Readability Score: ${validator.readabilityScore}');
print('Engagement Score: ${validator.engagementScore}');
print('Issues: ${validator.issues}');
```

#### Safety Scores Too Low
Review safety monitoring results:

```dart
final safetyResult = TodayFeedSafetyMonitor.monitorContentSafety(content);
print('Safety Score: ${safetyResult.safetyScore}');
print('Risk Factors: ${safetyResult.riskFactors}');
print('Recommendations: ${safetyResult.recommendations}');
```

---

## Performance Considerations

### Execution Time
- **Single Validation**: ~50-200ms typical
- **Comprehensive Analysis**: ~100-500ms typical
- **Parallel Processing**: Recommended for multiple validations

### Memory Usage
- **Alert History**: Limited to 100 items
- **Validation History**: Limited to 200 items
- **Regular Cleanup**: Automatic every 6 hours

### Storage
- **SharedPreferences**: Used for persistence
- **Data Size**: ~1-5KB per validation result
- **Cleanup Frequency**: Configure based on usage

### Optimization Tips

1. **Batch Operations**
   ```dart
   // Good: Process multiple items in parallel
   final results = await Future.wait(
     contents.map(service.validateContentQuality)
   );
   
   // Avoid: Sequential processing
   for (final content in contents) {
     await service.validateContentQuality(content);
   }
   ```

2. **Selective Analysis**
   ```dart
   // For quick safety checks only
   final safetyResult = await service.monitorContentSafety(content);
   
   // For full analysis when needed
   final fullResult = await service.analyzeContent(content);
   ```

3. **Alert Management**
   ```dart
   // Regular cleanup to prevent memory buildup
   Timer.periodic(Duration(hours: 6), (_) async {
     await service.clearOldAlerts(olderThan: Duration(days: 7));
   });
   ```

---

## Integration Guide

### App Startup

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(/* your app */);
        }
        return LoadingScreen();
      },
    );
  }
  
  Future<void> initializeServices() async {
    await TodayFeedContentQualityService.initialize();
    // Initialize other services...
  }
}
```

### Content Generation Pipeline

```dart
class ContentGenerationService {
  static Future<TodayFeedContent?> generateAndValidateContent(
    ContentParameters params
  ) async {
    // 1. Generate content with AI
    final rawContent = await AIService.generateContent(params);
    
    // 2. Validate content quality
    final qualityResult = await TodayFeedContentQualityService
        .validateContentQuality(rawContent);
    
    // 3. Check validation results
    if (!qualityResult.isValid) {
      logger.warning('Content failed validation: ${qualityResult.issues}');
      
      if (qualityResult.safetyScore < 0.8) {
        // Safety issue - reject immediately
        return null;
      } else {
        // Quality issue - try regeneration
        return await regenerateContent(params);
      }
    }
    
    // 4. Additional safety check
    final safetyResult = await TodayFeedContentQualityService
        .monitorContentSafety(rawContent);
    
    if (!safetyResult.isPassed) {
      logger.error('Content failed safety check: ${safetyResult.riskFactors}');
      return null;
    }
    
    return rawContent;
  }
}
```

### Real-time Monitoring

```dart
class ContentQualityManager {
  static StreamSubscription<QualityAlert>? _alertSubscription;
  
  static void startMonitoring() {
    _alertSubscription = TodayFeedContentQualityService.alertStream
        .listen(_handleAlert);
  }
  
  static void _handleAlert(QualityAlert alert) {
    switch (alert.severity) {
      case AlertSeverity.critical:
        _handleCriticalAlert(alert);
        break;
      case AlertSeverity.high:
        _handleHighAlert(alert);
        break;
      default:
        _logAlert(alert);
    }
  }
  
  static void _handleCriticalAlert(QualityAlert alert) {
    // Send immediate notification
    NotificationService.sendCriticalAlert(alert);
    
    // Block content if applicable
    if (alert.contentId != null) {
      ContentService.blockContent(alert.contentId!);
    }
    
    // Log for review
    AnalyticsService.logCriticalQualityIssue(alert);
  }
  
  static void dispose() {
    _alertSubscription?.cancel();
  }
}
```

---

## Conclusion

The Today Feed Content Quality Service provides a robust, comprehensive solution for ensuring high-quality, safe health content in your application. By following this guide, you can effectively integrate and utilize all features of the service to maintain content standards and protect user safety.

For additional support or questions, refer to the test files in `/test/features/today_feed/data/services/` or contact the development team.

---

**Last Updated:** January 2025  
**Version:** 1.0  
**Maintainer:** BEE-MVP Development Team 