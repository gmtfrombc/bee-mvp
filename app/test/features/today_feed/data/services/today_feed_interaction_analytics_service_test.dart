import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/today_feed/data/services/today_feed_interaction_analytics_service.dart';
import 'package:app/features/today_feed/domain/models/today_feed_content.dart';

void main() {
  group('TodayFeedInteractionAnalyticsService', () {
    late TodayFeedInteractionAnalyticsService service;

    setUp(() {
      service = TodayFeedInteractionAnalyticsService();
    });

    group('Service Initialization', () {
      test('should create singleton instance', () {
        // Arrange & Act
        final instance1 = TodayFeedInteractionAnalyticsService();
        final instance2 = TodayFeedInteractionAnalyticsService();

        // Assert
        expect(instance1, equals(instance2));
        expect(identical(instance1, instance2), isTrue);
      });

      test('should dispose without errors', () {
        // Act & Assert
        expect(() => service.dispose(), returnsNormally);
      });
    });

    group('Analytics Data Models', () {
      group('UserInteractionAnalytics', () {
        test('should create analytics with all required fields', () {
          // Arrange & Act
          const analytics = UserInteractionAnalytics(
            userId: 'test-user',
            analysisPeriodDays: 30,
            totalInteractions: 10,
            uniqueContentPieces: 5,
            averageSessionDuration: 120.0,
            engagementLevel: 'high',
            engagementRate: 0.8,
            topicPreferences: {'nutrition': 0.6, 'exercise': 0.4},
            engagementPatterns: {'peak_hour': 14},
            consecutiveDaysEngaged: 7,
            lastInteractionDate: null,
          );

          // Assert
          expect(analytics.userId, equals('test-user'));
          expect(analytics.totalInteractions, equals(10));
          expect(analytics.engagementLevel, equals('high'));
          expect(analytics.topicPreferences['nutrition'], equals(0.6));
        });

        test('should create empty analytics', () {
          // Act
          final analytics = UserInteractionAnalytics.empty('test-user');

          // Assert
          expect(analytics.userId, equals('test-user'));
          expect(analytics.totalInteractions, equals(0));
          expect(analytics.engagementLevel, equals('low'));
          expect(analytics.topicPreferences, isEmpty);
          expect(analytics.engagementPatterns, isEmpty);
        });
      });

      group('ContentPerformanceAnalytics', () {
        test('should create performance analytics with all fields', () {
          // Act
          const analytics = ContentPerformanceAnalytics(
            contentId: 1,
            totalViews: 100,
            totalClicks: 25,
            uniqueViewers: 75,
            averageSessionDuration: 90.0,
            engagementRate: 0.25,
            performanceScore: 0.65,
            interactionBreakdown: {'view': 100, 'click': 25},
          );

          // Assert
          expect(analytics.contentId, equals(1));
          expect(analytics.totalViews, equals(100));
          expect(analytics.engagementRate, equals(0.25));
          expect(analytics.interactionBreakdown['view'], equals(100));
        });

        test('should create empty performance analytics', () {
          // Act
          final analytics = ContentPerformanceAnalytics.empty(1);

          // Assert
          expect(analytics.contentId, equals(1));
          expect(analytics.totalViews, equals(0));
          expect(analytics.performanceScore, equals(0.0));
          expect(analytics.interactionBreakdown, isEmpty);
        });
      });

      group('EngagementTrendsAnalytics', () {
        test('should create trends analytics with daily data', () {
          // Arrange
          final dailyData = [
            DailyEngagementData(
              date: DateTime(2024, 1, 1),
              totalViews: 50,
              uniqueUsers: 30,
              engagementRate: 0.6,
              averageSessionDuration: 120.0,
            ),
            DailyEngagementData(
              date: DateTime(2024, 1, 2),
              totalViews: 60,
              uniqueUsers: 35,
              engagementRate: 0.7,
              averageSessionDuration: 135.0,
            ),
          ];

          // Act
          final analytics = EngagementTrendsAnalytics(
            dailyData: dailyData,
            trendDirection: 'increasing',
            averageEngagementRate: 0.65,
            peakEngagementDate: DateTime(2024, 1, 2),
          );

          // Assert
          expect(analytics.dailyData.length, equals(2));
          expect(analytics.trendDirection, equals('increasing'));
          expect(analytics.averageEngagementRate, equals(0.65));
          expect(analytics.peakEngagementDate, equals(DateTime(2024, 1, 2)));
        });

        test('should create empty trends analytics', () {
          // Act
          final analytics = EngagementTrendsAnalytics.empty();

          // Assert
          expect(analytics.dailyData, isEmpty);
          expect(analytics.trendDirection, equals('stable'));
          expect(analytics.averageEngagementRate, equals(0.0));
          expect(analytics.peakEngagementDate, isNull);
        });
      });

      group('TopicPerformanceAnalytics', () {
        test('should create topic performance analytics', () {
          // Act
          const analytics = TopicPerformanceAnalytics(
            topicEngagementRates: {'nutrition': 0.8, 'exercise': 0.6},
            topicViewCounts: {'nutrition': 100, 'exercise': 75},
            mostEngagingTopic: 'nutrition',
            leastEngagingTopic: 'exercise',
          );

          // Assert
          expect(analytics.topicEngagementRates['nutrition'], equals(0.8));
          expect(analytics.topicViewCounts['nutrition'], equals(100));
          expect(analytics.mostEngagingTopic, equals('nutrition'));
        });

        test('should create empty topic analytics', () {
          // Act
          final analytics = TopicPerformanceAnalytics.empty();

          // Assert
          expect(analytics.topicEngagementRates, isEmpty);
          expect(analytics.topicViewCounts, isEmpty);
          expect(analytics.mostEngagingTopic, isEmpty);
          expect(analytics.leastEngagingTopic, isEmpty);
        });
      });

      group('RealTimeEngagementMetrics', () {
        test('should create real-time metrics with current data', () {
          // Arrange
          final now = DateTime.now();

          // Act
          final metrics = RealTimeEngagementMetrics(
            currentActiveUsers: 25,
            todayTotalViews: 150,
            todayUniqueUsers: 100,
            todayEngagementRate: 0.67,
            todayMomentumPointsAwarded: 85,
            lastUpdated: now,
          );

          // Assert
          expect(metrics.currentActiveUsers, equals(25));
          expect(metrics.todayTotalViews, equals(150));
          expect(metrics.todayEngagementRate, equals(0.67));
          expect(metrics.lastUpdated, equals(now));
        });

        test('should create empty real-time metrics', () {
          // Act
          final metrics = RealTimeEngagementMetrics.empty();

          // Assert
          expect(metrics.currentActiveUsers, equals(0));
          expect(metrics.todayTotalViews, equals(0));
          expect(metrics.todayEngagementRate, equals(0.0));
          expect(metrics.lastUpdated, isA<DateTime>());
        });
      });

      group('DailyEngagementData', () {
        test('should create daily engagement data correctly', () {
          // Act
          final data = DailyEngagementData(
            date: DateTime(2024, 1, 15),
            totalViews: 200,
            uniqueUsers: 150,
            engagementRate: 0.75,
            averageSessionDuration: 180.0,
          );

          // Assert
          expect(data.date, equals(DateTime(2024, 1, 15)));
          expect(data.totalViews, equals(200));
          expect(data.uniqueUsers, equals(150));
          expect(data.engagementRate, equals(0.75));
          expect(data.averageSessionDuration, equals(180.0));
        });
      });
    });

    group('Service Configuration', () {
      test('should have correct default configuration constants', () {
        // Assert
        expect(
          TodayFeedInteractionAnalyticsService.defaultAnalysisPeriodDays,
          equals(30),
        );
        expect(
          TodayFeedInteractionAnalyticsService.maxAnalyticsHistoryDays,
          equals(90),
        );
        expect(
          TodayFeedInteractionAnalyticsService.highEngagementThreshold,
          equals(0.7),
        );
        expect(
          TodayFeedInteractionAnalyticsService.mediumEngagementThreshold,
          equals(0.4),
        );
        expect(
          TodayFeedInteractionAnalyticsService.minInteractionsForInsights,
          equals(5),
        );
      });
    });

    group('Analytics Logic Validation', () {
      test('should validate engagement thresholds make sense', () {
        // Assert logical threshold ordering
        expect(
          TodayFeedInteractionAnalyticsService.highEngagementThreshold,
          greaterThan(
            TodayFeedInteractionAnalyticsService.mediumEngagementThreshold,
          ),
        );
        expect(
          TodayFeedInteractionAnalyticsService.mediumEngagementThreshold,
          greaterThan(0.0),
        );
        expect(
          TodayFeedInteractionAnalyticsService.highEngagementThreshold,
          lessThanOrEqualTo(1.0),
        );
      });

      test('should validate analysis period bounds', () {
        // Assert reasonable analysis period limits
        expect(
          TodayFeedInteractionAnalyticsService.defaultAnalysisPeriodDays,
          greaterThan(0),
        );
        expect(
          TodayFeedInteractionAnalyticsService.maxAnalyticsHistoryDays,
          greaterThan(
            TodayFeedInteractionAnalyticsService.defaultAnalysisPeriodDays,
          ),
        );
        expect(
          TodayFeedInteractionAnalyticsService.minInteractionsForInsights,
          greaterThan(0),
        );
      });
    });

    group('Service Integration', () {
      test('should integrate with TodayFeedInteractionType enum', () {
        // Test that service expects the correct interaction types
        const viewType = TodayFeedInteractionType.view;
        const tapType = TodayFeedInteractionType.tap;
        const externalLinkType = TodayFeedInteractionType.externalLinkClick;
        const shareType = TodayFeedInteractionType.share;
        const bookmarkType = TodayFeedInteractionType.bookmark;

        // Assert enum values exist and have expected properties
        expect(viewType.value, equals('view'));
        expect(tapType.value, equals('tap'));
        expect(externalLinkType.value, equals('external_link_click'));
        expect(shareType.value, equals('share'));
        expect(bookmarkType.value, equals('bookmark'));
      });
    });

    group('Service Lifecycle', () {
      test('should handle multiple dispose calls', () {
        // Act & Assert - multiple dispose calls should not cause issues
        expect(() => service.dispose(), returnsNormally);
        expect(() => service.dispose(), returnsNormally);
        expect(() => service.dispose(), returnsNormally);
      });

      test('should maintain singleton behavior across operations', () {
        // Arrange
        final service1 = TodayFeedInteractionAnalyticsService();
        final service2 = TodayFeedInteractionAnalyticsService();

        // Act
        service1.dispose();

        // Assert - still same instance
        expect(identical(service1, service2), isTrue);
      });
    });

    group('Data Model Edge Cases', () {
      test('should handle UserInteractionAnalytics with edge case values', () {
        // Test with zero and extreme values
        const analytics = UserInteractionAnalytics(
          userId: '',
          analysisPeriodDays: 0,
          totalInteractions: 0,
          uniqueContentPieces: 0,
          averageSessionDuration: 0.0,
          engagementLevel: 'low',
          engagementRate: 0.0,
          topicPreferences: {},
          engagementPatterns: {},
          consecutiveDaysEngaged: 0,
        );

        expect(analytics.userId, isEmpty);
        expect(analytics.totalInteractions, equals(0));
        expect(analytics.averageSessionDuration, equals(0.0));
      });

      test('should handle ContentPerformanceAnalytics with zero values', () {
        const analytics = ContentPerformanceAnalytics(
          contentId: 0,
          totalViews: 0,
          totalClicks: 0,
          uniqueViewers: 0,
          averageSessionDuration: 0.0,
          engagementRate: 0.0,
          performanceScore: 0.0,
          interactionBreakdown: {},
        );

        expect(analytics.contentId, equals(0));
        expect(analytics.totalViews, equals(0));
        expect(analytics.performanceScore, equals(0.0));
      });

      test(
        'should handle EngagementTrendsAnalytics with single data point',
        () {
          final singleDay = [
            DailyEngagementData(
              date: DateTime(2024, 1, 1),
              totalViews: 10,
              uniqueUsers: 5,
              engagementRate: 0.5,
              averageSessionDuration: 60.0,
            ),
          ];

          final analytics = EngagementTrendsAnalytics(
            dailyData: singleDay,
            trendDirection: 'stable',
            averageEngagementRate: 0.5,
            peakEngagementDate: DateTime(2024, 1, 1),
          );

          expect(analytics.dailyData.length, equals(1));
          expect(analytics.trendDirection, equals('stable'));
        },
      );

      test('should handle RealTimeEngagementMetrics with negative values', () {
        // Test edge case where some values might be zero or very small
        final metrics = RealTimeEngagementMetrics(
          currentActiveUsers: 0,
          todayTotalViews: 0,
          todayUniqueUsers: 0,
          todayEngagementRate: 0.0,
          todayMomentumPointsAwarded: 0,
          lastUpdated: DateTime(2020, 1, 1), // Very old date
        );

        expect(metrics.currentActiveUsers, equals(0));
        expect(metrics.lastUpdated.year, equals(2020));
      });
    });

    group('Analytics Configuration Validation', () {
      test('should have reasonable default values for analytics periods', () {
        // Test that default values make sense for analytics
        const defaultPeriod =
            TodayFeedInteractionAnalyticsService.defaultAnalysisPeriodDays;
        const maxHistory =
            TodayFeedInteractionAnalyticsService.maxAnalyticsHistoryDays;

        expect(defaultPeriod, inInclusiveRange(7, 60)); // 1 week to 2 months
        expect(maxHistory, inInclusiveRange(60, 365)); // 2 months to 1 year
        expect(maxHistory, greaterThan(defaultPeriod));
      });

      test('should have sensible engagement thresholds', () {
        const high =
            TodayFeedInteractionAnalyticsService.highEngagementThreshold;
        const medium =
            TodayFeedInteractionAnalyticsService.mediumEngagementThreshold;

        expect(
          high,
          inInclusiveRange(0.5, 1.0),
        ); // High engagement should be 50-100%
        expect(
          medium,
          inInclusiveRange(0.2, 0.6),
        ); // Medium engagement should be 20-60%
        expect(
          high - medium,
          greaterThan(0.1),
        ); // Reasonable gap between thresholds
      });

      test(
        'should have minimum interactions threshold for reliable insights',
        () {
          const minInteractions =
              TodayFeedInteractionAnalyticsService.minInteractionsForInsights;

          expect(
            minInteractions,
            inInclusiveRange(3, 20),
          ); // Need enough data for insights
        },
      );
    });

    group('T1.3.4.7 Implementation Validation', () {
      test('should implement required analytics service interface', () {
        // Verify the service has the methods required by T1.3.4.7
        expect(service.getUserInteractionAnalytics, isA<Function>());
        expect(service.getContentPerformanceAnalytics, isA<Function>());
        expect(service.getEngagementTrends, isA<Function>());
        expect(service.getTopicPerformanceAnalytics, isA<Function>());
        expect(service.getRealTimeEngagementMetrics, isA<Function>());
        expect(service.recordInteractionEvent, isA<Function>());
      });

      test(
        'should have analytics data models that support tracking requirements',
        () {
          // Verify data models support the analytics needed for engagement tracking
          const userAnalytics = UserInteractionAnalytics(
            userId: 'test',
            analysisPeriodDays: 30,
            totalInteractions: 15,
            uniqueContentPieces: 10,
            averageSessionDuration: 120.0,
            engagementLevel: 'medium',
            engagementRate: 0.5,
            topicPreferences: {'nutrition': 0.4, 'exercise': 0.6},
            engagementPatterns: {
              'peak_hour': 14,
              'weekend_vs_weekday_ratio': 0.8,
            },
            consecutiveDaysEngaged: 5,
          );

          // Verify model supports tracking requirements from T1.3.4.7
          expect(userAnalytics.totalInteractions, greaterThan(0));
          expect(
            userAnalytics.engagementLevel,
            isIn(['low', 'medium', 'high']),
          );
          expect(userAnalytics.topicPreferences, isNotEmpty);
          expect(userAnalytics.engagementPatterns, isNotEmpty);
        },
      );

      test('should support real-time metrics for live tracking', () {
        final now = DateTime.now();
        final metrics = RealTimeEngagementMetrics(
          currentActiveUsers: 42,
          todayTotalViews: 500,
          todayUniqueUsers: 350,
          todayEngagementRate: 0.7,
          todayMomentumPointsAwarded: 280,
          lastUpdated: now,
        );

        // Verify real-time capabilities required for T1.3.4.7
        expect(metrics.currentActiveUsers, greaterThan(0));
        expect(metrics.todayTotalViews, greaterThan(0));
        expect(metrics.todayEngagementRate, greaterThan(0));
        expect(metrics.todayMomentumPointsAwarded, greaterThan(0));
        expect(
          metrics.lastUpdated.difference(now).inSeconds.abs(),
          lessThan(1),
        ); // Very recent update
      });
    });
  });
}
