import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/momentum/domain/models/momentum_data.dart';
import 'package:app/core/theme/app_theme.dart';

void main() {
  group('MomentumData Model Tests', () {
    late MomentumData sampleData;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
      sampleData = MomentumData(
        state: MomentumState.rising,
        percentage: 85.0,
        message: "You're doing great!",
        lastUpdated: testDate,
        weeklyTrend: [
          DailyMomentum(
            date: testDate.subtract(const Duration(days: 1)),
            state: MomentumState.steady,
            percentage: 75.0,
          ),
          DailyMomentum(
            date: testDate,
            state: MomentumState.rising,
            percentage: 85.0,
          ),
        ],
        stats: const MomentumStats(
          lessonsCompleted: 4,
          totalLessons: 5,
          streakDays: 7,
          todayMinutes: 25,
        ),
      );
    });

    group('MomentumData', () {
      test('should create valid momentum data instance', () {
        expect(sampleData.state, equals(MomentumState.rising));
        expect(sampleData.percentage, equals(85.0));
        expect(sampleData.message, equals("You're doing great!"));
        expect(sampleData.lastUpdated, equals(testDate));
        expect(sampleData.weeklyTrend.length, equals(2));
        expect(sampleData.stats.lessonsCompleted, equals(4));
      });

      test('should create sample data with valid defaults', () {
        final sample = MomentumData.sample();

        expect(sample.state, equals(MomentumState.rising));
        expect(sample.percentage, equals(85.0));
        expect(
          sample.message,
          equals("You're on fire! Keep up the great momentum!"),
        );
        expect(sample.weeklyTrend.length, equals(7));
        expect(sample.stats.lessonsCompleted, equals(4));
        expect(sample.stats.totalLessons, equals(5));
        expect(sample.stats.streakDays, equals(7));
        expect(sample.stats.todayMinutes, equals(25));
        expect(sample.lastUpdated, isA<DateTime>());
      });

      test('should generate valid weekly trend data', () {
        final sample = MomentumData.sample();
        final weeklyTrend = sample.weeklyTrend;

        expect(weeklyTrend.length, equals(7));

        // Check dates are in ascending order
        for (int i = 1; i < weeklyTrend.length; i++) {
          expect(
            weeklyTrend[i].date.isAfter(weeklyTrend[i - 1].date),
            isTrue,
            reason: 'Weekly trend dates should be in ascending order',
          );
        }

        // Check all have valid states and percentages
        for (final daily in weeklyTrend) {
          expect(daily.state, isA<MomentumState>());
          expect(daily.percentage, greaterThanOrEqualTo(0.0));
          expect(daily.percentage, lessThanOrEqualTo(100.0));
        }
      });

      test('should copy with new values correctly', () {
        final newDate = DateTime(2024, 1, 16);
        final copied = sampleData.copyWith(
          state: MomentumState.needsCare,
          percentage: 45.0,
          lastUpdated: newDate,
        );

        expect(copied.state, equals(MomentumState.needsCare));
        expect(copied.percentage, equals(45.0));
        expect(copied.lastUpdated, equals(newDate));
        // Unchanged values should remain the same
        expect(copied.message, equals(sampleData.message));
        expect(copied.weeklyTrend, equals(sampleData.weeklyTrend));
        expect(copied.stats, equals(sampleData.stats));
      });

      test('should copy with no changes when no parameters provided', () {
        final copied = sampleData.copyWith();

        expect(copied.state, equals(sampleData.state));
        expect(copied.percentage, equals(sampleData.percentage));
        expect(copied.message, equals(sampleData.message));
        expect(copied.lastUpdated, equals(sampleData.lastUpdated));
        expect(copied.weeklyTrend, equals(sampleData.weeklyTrend));
        expect(copied.stats, equals(sampleData.stats));
      });

      test('should serialize and deserialize correctly', () {
        final json = sampleData.toJson();
        final deserialized = MomentumData.fromJson(json);

        expect(deserialized.state, equals(sampleData.state));
        expect(deserialized.percentage, equals(sampleData.percentage));
        expect(deserialized.message, equals(sampleData.message));
      });
    });

    group('DailyMomentum', () {
      late DailyMomentum dailyMomentum;

      setUp(() {
        dailyMomentum = DailyMomentum(
          date: testDate,
          state: MomentumState.rising,
          percentage: 85.0,
        );
      });

      test('should create valid daily momentum instance', () {
        expect(dailyMomentum.date, equals(testDate));
        expect(dailyMomentum.state, equals(MomentumState.rising));
        expect(dailyMomentum.percentage, equals(85.0));
      });

      test('should serialize and deserialize correctly', () {
        final json = dailyMomentum.toJson();
        final deserialized = DailyMomentum.fromJson(json);

        expect(deserialized.date, equals(dailyMomentum.date));
        expect(deserialized.state, equals(dailyMomentum.state));
        expect(deserialized.percentage, equals(dailyMomentum.percentage));
      });
    });

    group('MomentumStats', () {
      late MomentumStats stats;

      setUp(() {
        stats = const MomentumStats(
          lessonsCompleted: 4,
          totalLessons: 5,
          streakDays: 7,
          todayMinutes: 25,
        );
      });

      test('should create valid momentum stats instance', () {
        expect(stats.lessonsCompleted, equals(4));
        expect(stats.totalLessons, equals(5));
        expect(stats.streakDays, equals(7));
        expect(stats.todayMinutes, equals(25));
      });

      test('should format lessons ratio correctly', () {
        expect(stats.lessonsRatio, equals('4/5'));

        const zeroStats = MomentumStats(
          lessonsCompleted: 0,
          totalLessons: 10,
          streakDays: 0,
          todayMinutes: 0,
        );
        expect(zeroStats.lessonsRatio, equals('0/10'));
      });

      test('should format streak text correctly', () {
        expect(stats.streakText, equals('7 days'));

        const oneDayStreak = MomentumStats(
          lessonsCompleted: 1,
          totalLessons: 1,
          streakDays: 1,
          todayMinutes: 10,
        );
        expect(oneDayStreak.streakText, equals('1 day'));

        const zeroStreak = MomentumStats(
          lessonsCompleted: 0,
          totalLessons: 5,
          streakDays: 0,
          todayMinutes: 0,
        );
        expect(zeroStreak.streakText, equals('0 days'));
      });

      test('should format today text correctly', () {
        expect(stats.todayText, equals('25m'));

        const zeroMinutes = MomentumStats(
          lessonsCompleted: 0,
          totalLessons: 5,
          streakDays: 0,
          todayMinutes: 0,
        );
        expect(zeroMinutes.todayText, equals('0m'));

        const highMinutes = MomentumStats(
          lessonsCompleted: 5,
          totalLessons: 5,
          streakDays: 10,
          todayMinutes: 120,
        );
        expect(highMinutes.todayText, equals('120m'));
      });

      test('should serialize and deserialize correctly', () {
        final json = stats.toJson();
        final deserialized = MomentumStats.fromJson(json);

        expect(deserialized.lessonsCompleted, equals(stats.lessonsCompleted));
        expect(deserialized.totalLessons, equals(stats.totalLessons));
        expect(deserialized.streakDays, equals(stats.streakDays));
      });
    });

    group('Performance Tests', () {
      test('should handle large weekly trend efficiently', () {
        final stopwatch = Stopwatch()..start();

        // Create 100 days of data
        final largeTrend = List.generate(100, (index) {
          return DailyMomentum(
            date: testDate.subtract(Duration(days: 99 - index)),
            state: MomentumState.values[index % 3],
            percentage: (index % 100).toDouble(),
          );
        });

        final data = MomentumData(
          state: MomentumState.rising,
          percentage: 85.0,
          message: "Test with large trend",
          lastUpdated: testDate,
          weeklyTrend: largeTrend,
          stats: const MomentumStats(
            lessonsCompleted: 50,
            totalLessons: 100,
            streakDays: 50,
            todayMinutes: 120,
          ),
        );

        final json = data.toJson();
        final deserialized = MomentumData.fromJson(json);

        stopwatch.stop();

        // Should complete within reasonable time (adjust as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(deserialized.weeklyTrend.length, equals(100));
      });

      test('should handle frequent copyWith operations efficiently', () {
        final stopwatch = Stopwatch()..start();

        var data = sampleData;
        for (int i = 0; i < 1000; i++) {
          data = data.copyWith(
            percentage: (i % 100).toDouble(),
            message: "Update $i",
          );
        }

        stopwatch.stop();

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
        expect(data.message, equals("Update 999"));
        expect(data.percentage, equals(99.0));
      });
    });
  });
}
