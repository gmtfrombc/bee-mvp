import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/health_signals/pes/pes_providers.dart';
import 'package:app/features/health_signals/pes/services/notification_scheduler_service.dart';

// -----------------------------------------------------------------------------
// Test doubles
// -----------------------------------------------------------------------------
class _FakeScheduler implements NotificationSchedulerService {
  TimeOfDay? lastScheduled;
  int cancelCount = 0;

  @override
  Future<void> cancelPrompt() async {
    cancelCount += 1;
  }

  @override
  Future<void> scheduleDailyPrompt(TimeOfDay time) async {
    lastScheduled = time;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyPromptController', () {
    late _FakeScheduler fakeScheduler;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeScheduler = _FakeScheduler();
    });

    test('schedules default 09:00 prompt on first build', () async {
      final container = ProviderContainer(
        overrides: [
          notificationSchedulerProvider.overrideWith(
            (ref) async => fakeScheduler,
          ),
        ],
      );

      addTearDown(container.dispose);

      final time = await container.read(dailyPromptControllerProvider.future);
      expect(time.hour, 9);
      expect(time.minute, 0);
      expect(fakeScheduler.lastScheduled?.hour, 9);
      expect(fakeScheduler.lastScheduled?.minute, 0);
    });

    test('updateTime persists preference and reschedules', () async {
      final container = ProviderContainer(
        overrides: [
          notificationSchedulerProvider.overrideWith(
            (ref) async => fakeScheduler,
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(dailyPromptControllerProvider.notifier);

      await controller.updateTime(const TimeOfDay(hour: 18, minute: 30));

      // Verify scheduler called with new time.
      expect(fakeScheduler.lastScheduled?.hour, 18);
      expect(fakeScheduler.lastScheduled?.minute, 30);

      // Verify state updated.
      final value = await container.read(dailyPromptControllerProvider.future);
      expect(value.hour, 18);
      expect(value.minute, 30);

      // Verify prefs persisted.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('dailyPromptHour'), 18);
      expect(prefs.getInt('dailyPromptMinute'), 30);
    });
  });
}
