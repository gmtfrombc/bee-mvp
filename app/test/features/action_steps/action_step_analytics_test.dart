import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/features/action_steps/services/action_step_analytics.dart';
import 'package:app/core/services/analytics_service.dart';

class _MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('ActionStepAnalytics', () {
    late _MockAnalyticsService mockAnalytics;
    late SupabaseClient fakeClient;
    late ActionStepAnalytics analytics;

    setUp(() {
      mockAnalytics = _MockAnalyticsService();
      // Use a fake Supabase URL/key – no network calls occur in this test.
      fakeClient = SupabaseClient('http://localhost:54321', 'anon-key');
      analytics = ActionStepAnalytics(fakeClient, mockAnalytics);
    });

    test('logSet forwards correct event name and params', () async {
      // Arrange
      when(
        () => mockAnalytics.logEvent(any(), params: any(named: 'params')),
      ).thenAnswer((_) async {});

      // Act
      await analytics.logSet(
        actionStepId: 'step-123',
        category: 'nutrition',
        description: 'Eat 5 servings of vegetables',
        frequency: 5,
        weekStart: '2025-07-14',
      );

      // Assert
      verify(
        () => mockAnalytics.logEvent(
          'action_step_set',
          params: captureAny(named: 'params'),
        ),
      ).called(1);
    });

    test('logView forwards correct event name', () async {
      when(
        () => mockAnalytics.logEvent(any(), params: any(named: 'params')),
      ).thenAnswer((_) async {});

      await analytics.logView(actionStepId: 'step-123');

      verify(
        () => mockAnalytics.logEvent(
          'action_step_view',
          params: captureAny(named: 'params'),
        ),
      ).called(1);
    });

    test('logEdit forwards correct event name and params', () async {
      when(
        () => mockAnalytics.logEvent(any(), params: any(named: 'params')),
      ).thenAnswer((_) async {});

      await analytics.logEdit(
        actionStepId: 'step-123',
        category: 'nutrition',
        description: 'Eat 5 servings of vegetables',
        frequency: 5,
      );

      verify(
        () => mockAnalytics.logEvent(
          'action_step_edit',
          params: captureAny(named: 'params'),
        ),
      ).called(1);
    });

    test('logDelete forwards correct event name', () async {
      when(
        () => mockAnalytics.logEvent(any(), params: any(named: 'params')),
      ).thenAnswer((_) async {});

      await analytics.logDelete(actionStepId: 'step-123');

      verify(
        () => mockAnalytics.logEvent(
          'action_step_delete',
          params: captureAny(named: 'params'),
        ),
      ).called(1);
    });

    test('logHistoryView forwards correct event name', () async {
      when(
        () => mockAnalytics.logEvent(any(), params: any(named: 'params')),
      ).thenAnswer((_) async {});

      await analytics.logHistoryView();

      verify(
        () => mockAnalytics.logEvent(
          'action_step_history_view',
          params: captureAny(named: 'params'),
        ),
      ).called(1);
    });

    test('logWeeklyReset forwards correct event name', () async {
      when(
        () => mockAnalytics.logEvent(any(), params: any(named: 'params')),
      ).thenAnswer((_) async {});

      await analytics.logWeeklyReset(previousActionStepId: 'step-122');

      verify(
        () => mockAnalytics.logEvent(
          'action_step_weekly_reset',
          params: captureAny(named: 'params'),
        ),
      ).called(1);
    });
  });
}
