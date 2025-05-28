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

      test('should serialize to JSON correctly', () {
        final json = sampleData.toJson();

        expect(json['state'], equals('rising'));
        expect(json['percentage'], equals(85.0));
        expect(json['message'], equals("You're doing great!"));
        expect(json['lastUpdated'], equals(testDate.toIso8601String()));
        expect(json['weeklyTrend'], isA<List>());
        expect(json['stats'], isA<Map<String, dynamic>>());
      });

      test('should deserialize from JSON correctly', () {
        final json = sampleData.toJson();
        final deserialized = MomentumData.fromJson(json);

        expect(deserialized.state, equals(sampleData.state));
        expect(deserialized.percentage, equals(sampleData.percentage));
        expect(deserialized.message, equals(sampleData.message));
        expect(deserialized.lastUpdated, equals(sampleData.lastUpdated));
        expect(
          deserialized.weeklyTrend.length,
          equals(sampleData.weeklyTrend.length),
        );
        expect(
          deserialized.stats.lessonsCompleted,
          equals(sampleData.stats.lessonsCompleted),
        );
      });

      test('should handle invalid JSON gracefully', () {
        final invalidJson = {
          'state': 'invalid_state',
          'percentage': 85.0,
          'message': "Test message",
          'lastUpdated': testDate.toIso8601String(),
          'weeklyTrend': [],
          'stats': {
            'lessonsCompleted': 0,
            'totalLessons': 0,
            'streakDays': 0,
            'todayMinutes': 0,
          },
        };

        final deserialized = MomentumData.fromJson(invalidJson);

        // Should default to steady state for invalid state
        expect(deserialized.state, equals(MomentumState.steady));
        expect(deserialized.percentage, equals(85.0));
        expect(deserialized.message, equals("Test message"));
      });

      test('should round-trip serialize/deserialize correctly', () {
        final json = sampleData.toJson();
        final deserialized = MomentumData.fromJson(json);
        final jsonAgain = deserialized.toJson();

        expect(jsonAgain, equals(json));
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

      test('should serialize to JSON correctly', () {
        final json = dailyMomentum.toJson();

        expect(json['date'], equals(testDate.toIso8601String()));
        expect(json['state'], equals('rising'));
        expect(json['percentage'], equals(85.0));
      });

      test('should deserialize from JSON correctly', () {
        final json = dailyMomentum.toJson();
        final deserialized = DailyMomentum.fromJson(json);

        expect(deserialized.date, equals(dailyMomentum.date));
        expect(deserialized.state, equals(dailyMomentum.state));
        expect(deserialized.percentage, equals(dailyMomentum.percentage));
      });

      test('should handle invalid state in JSON gracefully', () {
        final invalidJson = {
          'date': testDate.toIso8601String(),
          'state': 'invalid_state',
          'percentage': 75.0,
        };

        final deserialized = DailyMomentum.fromJson(invalidJson);

        expect(deserialized.state, equals(MomentumState.steady));
        expect(deserialized.percentage, equals(75.0));
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

      test('should serialize to JSON correctly', () {
        final json = stats.toJson();

        expect(json['lessonsCompleted'], equals(4));
        expect(json['totalLessons'], equals(5));
        expect(json['streakDays'], equals(7));
        expect(json['todayMinutes'], equals(25));
      });

      test('should deserialize from JSON correctly', () {
        final json = stats.toJson();
        final deserialized = MomentumStats.fromJson(json);

        expect(deserialized.lessonsCompleted, equals(stats.lessonsCompleted));
        expect(deserialized.totalLessons, equals(stats.totalLessons));
        expect(deserialized.streakDays, equals(stats.streakDays));
        expect(deserialized.todayMinutes, equals(stats.todayMinutes));
      });

      test('should round-trip serialize/deserialize correctly', () {
        final json = stats.toJson();
        final deserialized = MomentumStats.fromJson(json);
        final jsonAgain = deserialized.toJson();

        expect(jsonAgain, equals(json));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle extreme percentage values', () {
        final extremeData = MomentumData(
          state: MomentumState.rising,
          percentage: 999.99,
          message: "Test",
          lastUpdated: testDate,
          weeklyTrend: [],
          stats: const MomentumStats(
            lessonsCompleted: 0,
            totalLessons: 0,
            streakDays: 0,
            todayMinutes: 0,
          ),
        );

        expect(extremeData.percentage, equals(999.99));

        final json = extremeData.toJson();
        final deserialized = MomentumData.fromJson(json);
        expect(deserialized.percentage, equals(999.99));
      });

      test('should handle empty weekly trend', () {
        final emptyTrendData = MomentumData(
          state: MomentumState.steady,
          percentage: 50.0,
          message: "Test",
          lastUpdated: testDate,
          weeklyTrend: [],
          stats: const MomentumStats(
            lessonsCompleted: 0,
            totalLessons: 0,
            streakDays: 0,
            todayMinutes: 0,
          ),
        );

        expect(emptyTrendData.weeklyTrend.isEmpty, isTrue);

        final json = emptyTrendData.toJson();
        final deserialized = MomentumData.fromJson(json);
        expect(deserialized.weeklyTrend.isEmpty, isTrue);
      });

      test('should handle very large stats values', () {
        const largeStats = MomentumStats(
          lessonsCompleted: 999,
          totalLessons: 1000,
          streakDays: 365,
          todayMinutes: 1440, // 24 hours
        );

        expect(largeStats.lessonsRatio, equals('999/1000'));
        expect(largeStats.streakText, equals('365 days'));
        expect(largeStats.todayText, equals('1440m'));
      });

      test('should handle malformed JSON data gracefully', () {
        final malformedJson = {
          'state': 'rising',
          'percentage': 'not_a_number', // This should cause an error
          'message': "Test",
          'lastUpdated': testDate.toIso8601String(),
          'weeklyTrend': [],
          'stats': {
            'lessonsCompleted': 0,
            'totalLessons': 0,
            'streakDays': 0,
            'todayMinutes': 0,
          },
        };

        // This should throw an exception for invalid data types
        expect(
          () => MomentumData.fromJson(malformedJson),
          throwsA(isA<TypeError>()),
        );
      });

      test('should handle missing JSON fields gracefully', () {
        final incompleteJson = {
          'state': 'rising',
          'percentage': 85.0,
          // Missing message, lastUpdated, weeklyTrend, stats
        };

        // This should throw an exception for missing required fields
        expect(
          () => MomentumData.fromJson(incompleteJson),
          throwsA(isA<TypeError>()),
        );
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
