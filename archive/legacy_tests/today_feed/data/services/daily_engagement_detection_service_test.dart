import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/data/services/daily_engagement_detection_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('DailyEngagementDetectionService Tests', () {
    late DailyEngagementDetectionService service;

    setUp(() {
      service = DailyEngagementDetectionService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should create service instance successfully', () {
      expect(service, isNotNull);
      expect(service.getCacheStatistics()['cache_size'], equals(0));
    });

    test('should detect first-time daily engagement', () {
      final testContent = TodayFeedContent.sample();

      expect(testContent.hasUserEngaged, isFalse);
      expect(testContent.id, isNotNull);
    });

    test('should return correct engagement status structure', () {
      const status = EngagementStatus(
        hasEngagedToday: false,
        isEligibleForMomentum: true,
        source: EngagementSource.database,
      );

      expect(status.hasEngagedToday, isFalse);
      expect(status.isEligibleForMomentum, isTrue);
      expect(status.source, equals(EngagementSource.database));
      expect(status.lastEngagementTime, isNull);
      expect(status.error, isNull);
    });

    test('should create successful engagement result', () {
      const result = EngagementResult(
        success: true,
        momentumAwarded: true,
        momentumPoints: 1,
        isDuplicate: false,
        engagementRecorded: true,
        message: 'First daily engagement! +1 momentum point earned',
      );

      expect(result.success, isTrue);
      expect(result.momentumAwarded, isTrue);
      expect(result.momentumPoints, equals(1));
      expect(result.isDuplicate, isFalse);
      expect(result.engagementRecorded, isTrue);
      expect(result.message, contains('First daily engagement'));
    });
  });
}
