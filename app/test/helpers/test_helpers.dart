import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/features/momentum/data/services/momentum_api_service.dart';
import 'package:app/features/momentum/presentation/providers/momentum_api_provider.dart';

/// Test utilities and helpers for BEE app testing
class TestHelpers {
  /// Create a mock momentum API service for testing
  static MockMomentumApiService createMockMomentumApiService() {
    return MockMomentumApiService();
  }

  /// Create test provider overrides for momentum-related tests
  static List<Override> createMomentumProviderOverrides() {
    return [
      momentumApiServiceProvider.overrideWith((ref) {
        return TestHelpers.createMockMomentumApiService();
      }),
      realtimeMomentumProvider.overrideWith((ref) {
        // Return a stream that emits test data
        return Stream.value(TestHelpers.createSampleMomentumData());
      }),
    ];
  }

  /// Create a test app wrapper with proper setup
  static Widget createTestApp({
    required Widget child,
    List<Override>? providerOverrides,
    ThemeData? theme,
    bool enableNotifications = false,
  }) {
    return ProviderScope(
      overrides: providerOverrides ?? createMomentumProviderOverrides(),
      child: MaterialApp(
        title: 'BEE Test',
        theme: theme ?? AppTheme.lightTheme,
        home:
            enableNotifications ? TestNotificationWrapper(child: child) : child,
      ),
    );
  }

  /// Create a test app with Scaffold wrapper
  static Widget createTestAppWithScaffold({
    required Widget child,
    List<Override>? providerOverrides,
    ThemeData? theme,
    bool enableNotifications = false,
  }) {
    return createTestApp(
      providerOverrides: providerOverrides,
      theme: theme,
      enableNotifications: enableNotifications,
      child: Scaffold(body: child),
    );
  }

  /// Pump a widget with proper test setup
  static Future<void> pumpTestWidget(
    WidgetTester tester, {
    required Widget child,
    List<Override>? providerOverrides,
    ThemeData? theme,
    Duration? settleDuration,
  }) async {
    await tester.pumpWidget(
      createTestApp(
        child: child,
        providerOverrides: providerOverrides,
        theme: theme,
      ),
    );

    // Allow for initial animations and state setup
    await tester.pump();

    if (settleDuration != null) {
      await tester.pump(settleDuration);
    } else {
      // Default settle time for most widgets
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Setup test environment before each test
  static Future<void> setUpTest() async {
    // No Supabase initialization needed for widget tests
    // Tests will use mocked providers instead
  }

  /// Create sample momentum data for testing
  static MomentumData createSampleMomentumData({
    MomentumState? state,
    double? percentage,
    String? message,
    DateTime? lastUpdated,
  }) {
    return MomentumData(
      state: state ?? MomentumState.rising,
      percentage: percentage ?? 85.0,
      message: message ?? "You're doing great! Keep up the excellent work.",
      lastUpdated: lastUpdated ?? DateTime.now(),
      stats: MomentumStats.fromJson({
        'lessonsCompleted': 4,
        'totalLessons': 5,
        'streakDays': 7,
        'todayMinutes': 25,
      }),
      weeklyTrend: [
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 6)),
          state: MomentumState.needsCare,
          percentage: 35.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 5)),
          state: MomentumState.steady,
          percentage: 55.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 4)),
          state: MomentumState.steady,
          percentage: 65.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 3)),
          state: MomentumState.rising,
          percentage: 75.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 2)),
          state: MomentumState.rising,
          percentage: 80.0,
        ),
        DailyMomentum(
          date: DateTime.now().subtract(const Duration(days: 1)),
          state: MomentumState.rising,
          percentage: 82.0,
        ),
        DailyMomentum(
          date: DateTime.now(),
          state: state ?? MomentumState.rising,
          percentage: percentage ?? 85.0,
        ),
      ],
    );
  }

  /// Create a mock Firebase RemoteMessage for testing
  static RemoteMessage createMockRemoteMessage({
    String? messageId,
    Map<String, String>? data,
    RemoteNotification? notification,
  }) {
    return RemoteMessage(
      messageId:
          messageId ?? 'test-message-${DateTime.now().millisecondsSinceEpoch}',
      data: data ?? {},
      notification: notification,
    );
  }

  /// Create a mock notification for testing different intervention types
  static RemoteMessage createMockNotificationMessage({
    required String interventionType,
    required String actionType,
    String? notificationId,
    Map<String, dynamic>? actionData,
    String? title,
    String? body,
  }) {
    return RemoteMessage(
      messageId: 'test-${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'notification_id': notificationId ?? 'test-notification-id',
        'intervention_type': interventionType,
        'action_type': actionType,
        'action_data': actionData != null ? json.encode(actionData) : '{}',
      },
      notification: RemoteNotification(
        title: title ?? 'Test Notification',
        body: body ?? 'Test notification body',
      ),
    );
  }

  /// Create test data for background notification scenarios
  static Map<String, RemoteMessage> createBackgroundNotificationScenarios() {
    return {
      'momentum_drop': createMockNotificationMessage(
        interventionType: 'momentum_drop',
        actionType: 'open_momentum_meter',
        title: 'Momentum needs attention',
        body: 'Let\'s get back on track together!',
      ),
      'celebration': createMockNotificationMessage(
        interventionType: 'celebration',
        actionType: 'view_momentum',
        actionData: {'celebration': true, 'streak_days': 7},
        title: 'Amazing momentum! 🎉',
        body: 'You\'ve been Rising for 7 days straight!',
      ),
      'consecutive_needs_care': createMockNotificationMessage(
        interventionType: 'consecutive_needs_care',
        actionType: 'schedule_call',
        actionData: {'priority': 'high', 'intervention_type': 'support_call'},
        title: 'Let\'s grow together! 🌱',
        body: 'Your coach is here to help you get back on track!',
      ),
      'score_drop': createMockNotificationMessage(
        interventionType: 'score_drop',
        actionType: 'complete_lesson',
        actionData: {'suggested_lesson': 'resilience_basics'},
        title: 'You\'ve got this! 💪',
        body: 'Everyone has ups and downs. Let\'s focus on small wins today!',
      ),
      'daily_motivation': createMockNotificationMessage(
        interventionType: 'daily_motivation',
        actionType: 'open_app',
        actionData: {'focus': 'momentum_meter'},
        title: 'Keep soaring! 🚀',
        body: 'Your momentum journey continues!',
      ),
    };
  }

  /// Simulate app lifecycle state changes for testing
  static Future<void> simulateAppStateChange(
    WidgetTester tester,
    AppLifecycleState state,
  ) async {
    // For testing purposes, we'll use a simplified approach
    // In real tests, this could be expanded to properly simulate lifecycle changes
    await tester.pump();
    // Note: Full lifecycle simulation would require more complex mocking
    // This is a placeholder for future enhancement
  }

  /// Clear all notification test data
  static Future<void> clearNotificationTestData() async {
    // Clear SharedPreferences mock data
    SharedPreferences.setMockInitialValues({});
  }

  /// Setup background notification testing environment
  static Future<void> setupBackgroundNotificationTesting() async {
    // Initialize mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Set up test environment flags
    // This would be where we'd mock Firebase initialization for tests
  }

  /// Verify notification processing results
  static Future<void> verifyNotificationProcessing({
    required String expectedNotificationId,
    required String expectedInterventionType,
    required String expectedActionType,
    Map<String, dynamic>? expectedActionData,
  }) async {
    // This helper can be used to verify that background notification processing
    // worked correctly by checking SharedPreferences or other test state
    final prefs = await SharedPreferences.getInstance();

    // Verify stored notification data
    final storedNotificationJson = prefs.getString(
      'last_background_notification',
    );
    if (storedNotificationJson != null) {
      final storedData = json.decode(storedNotificationJson);
      expect(storedData['notificationId'], equals(expectedNotificationId));
      expect(storedData['interventionType'], equals(expectedInterventionType));
      expect(storedData['actionType'], equals(expectedActionType));

      if (expectedActionData != null) {
        final actionData = json.decode(storedData['actionData'] ?? '{}');
        expectedActionData.forEach((key, value) {
          expect(actionData[key], equals(value));
        });
      }
    }
  }
}

/// Test wrapper widget for notification-enabled tests
class TestNotificationWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const TestNotificationWrapper({super.key, required this.child});

  @override
  ConsumerState<TestNotificationWrapper> createState() =>
      _TestNotificationWrapperState();
}

class _TestNotificationWrapperState
    extends ConsumerState<TestNotificationWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize test notification dispatcher if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTestNotificationHandling();
    });
  }

  void _initializeTestNotificationHandling() {
    // Initialize test-specific notification handling
    // This could set up mock notification dispatcher for testing
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Mock implementation of MomentumApiService for testing
class MockMomentumApiService implements MomentumApiService {
  @override
  Future<MomentumData> getCurrentMomentum() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return TestHelpers.createSampleMomentumData();
  }

  @override
  Future<List<DailyMomentum>> getMomentumHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return TestHelpers.createSampleMomentumData().weeklyTrend;
  }

  @override
  Future<MomentumData> calculateMomentumScore({String? targetDate}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return TestHelpers.createSampleMomentumData();
  }

  @override
  RealtimeChannel subscribeToMomentumUpdates({
    required Function(MomentumData) onUpdate,
    required Function(String) onError,
  }) {
    // For tests, we don't support real-time updates
    // Call the error callback to simulate the error handling
    onError('Real-time updates not supported in test environment');

    // We need to return something, but it won't be used in tests
    // This will throw if actually used, which is what we want
    throw UnsupportedError(
      'Real-time updates not supported in test environment',
    );
  }

  // Enhanced caching methods for testing
  @override
  Future<MomentumData> getMomentumWithOfflineSupport({
    bool allowStaleData = true,
    Duration? maxCacheAge,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return TestHelpers.createSampleMomentumData();
  }

  @override
  Future<void> initializeOfflineSupport() async {
    // Mock initialization - no actual work needed in tests
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> warmMomentumCache() async {
    // Mock cache warming
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> processPendingMomentumActions() async {
    // Mock processing
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> invalidateMomentumCache({String? reason}) async {
    // Mock cache invalidation
    await Future.delayed(const Duration(milliseconds: 10));
  }
}
