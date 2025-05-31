import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/notifications/domain/models/notification_models.dart';
import 'package:app/core/notifications/domain/models/notification_types.dart';

void main() {
  group('Domain NotificationAnalyticsService Data Models', () {
    group('NotificationAnalytics', () {
      test('should create from JSON correctly', () {
        // Arrange
        final json = {
          'notification_date': '2024-01-01',
          'notification_type': 'momentum',
          'delivery_status': 'delivered',
          'count': 10,
          'unique_users': 8,
          'engagement_score': 0.75,
        };

        // Act
        final analytics = NotificationAnalytics.fromJson(json);

        // Assert
        expect(analytics.notificationDate, DateTime.parse('2024-01-01'));
        expect(analytics.notificationType, 'momentum');
        expect(analytics.deliveryStatus, 'delivered');
        expect(analytics.count, 10);
        expect(analytics.uniqueUsers, 8);
        expect(analytics.engagementScore, 0.75);
      });

      test('should handle missing engagement score gracefully', () {
        // Arrange
        final json = {
          'notification_date': '2024-01-01',
          'notification_type': 'momentum',
          'delivery_status': 'delivered',
          'count': 10,
          'unique_users': 8,
        };

        // Act
        final analytics = NotificationAnalytics.fromJson(json);

        // Assert
        expect(analytics.engagementScore, 0.0);
      });
    });

    group('NotificationInteraction', () {
      test('should serialize to and from JSON correctly', () {
        // Arrange
        final interaction = NotificationInteraction(
          id: 'test-id',
          userId: 'user-123',
          notificationId: 'notification-456',
          interactionType: NotificationInteractionType.clicked,
          metadata: {'action': 'view_momentum'},
          timestamp: DateTime.parse('2024-01-01T12:00:00Z'),
        );

        // Act
        final json = interaction.toJson();
        final restored = NotificationInteraction.fromJson(json);

        // Assert
        expect(restored.id, interaction.id);
        expect(restored.userId, interaction.userId);
        expect(restored.notificationId, interaction.notificationId);
        expect(restored.interactionType, interaction.interactionType);
        expect(restored.metadata, interaction.metadata);
        expect(restored.timestamp, interaction.timestamp);
      });

      test('should handle missing metadata gracefully', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'user_id': 'user-123',
          'notification_id': 'notification-456',
          'interaction_type': 'opened',
          'timestamp': '2024-01-01T12:00:00Z',
        };

        // Act
        final interaction = NotificationInteraction.fromJson(json);

        // Assert
        expect(interaction.id, 'test-id');
        expect(interaction.interactionType, NotificationInteractionType.opened);
        expect(interaction.metadata, isNull);
      });
    });

    group('NotificationVariant', () {
      test('should create control variant correctly', () {
        // Act
        final variant = NotificationVariant.control();

        // Assert
        expect(variant.name, 'control');
        expect(variant.type, VariantType.control);
        expect(variant.config, isEmpty);
      });

      test('should serialize to and from JSON correctly', () {
        // Arrange
        final variant = NotificationVariant(
          name: 'test_variant',
          type: VariantType.personalized,
          config: {'key': 'value'},
        );

        // Act
        final json = variant.toJson();
        final restored = NotificationVariant.fromJson(json);

        // Assert
        expect(restored.name, variant.name);
        expect(restored.type, variant.type);
        expect(restored.config, variant.config);
      });
    });

    group('ABTestResults', () {
      test('should create from JSON correctly', () {
        // Arrange
        final json = {
          'test_name': 'test-experiment',
          'variants': [
            {
              'name': 'control',
              'participants': 100,
              'delivery_rate': 0.95,
              'open_rate': 0.3,
              'click_rate': 0.1,
              'conversion_rate': 0.05,
              'engagement_score': 0.25,
            },
            {
              'name': 'variant_a',
              'participants': 95,
              'delivery_rate': 0.97,
              'open_rate': 0.35,
              'click_rate': 0.12,
              'conversion_rate': 0.07,
              'engagement_score': 0.32,
            },
          ],
          'statistical_significance': 0.85,
          'winning_variant': 'variant_a',
          'confidence_level': 0.95,
        };

        // Act
        final results = ABTestResults.fromJson(json);

        // Assert
        expect(results.testName, 'test-experiment');
        expect(results.variants, hasLength(2));
        expect(results.variants[0].name, 'control');
        expect(results.variants[1].name, 'variant_a');
        expect(results.statisticalSignificance, 0.85);
        expect(results.winningVariant, 'variant_a');
        expect(results.confidenceLevel, 0.95);
      });
    });

    group('VariantResults', () {
      test('should create from JSON correctly', () {
        // Arrange
        final json = {
          'name': 'test_variant',
          'participants': 150,
          'delivery_rate': 0.96,
          'open_rate': 0.34,
          'click_rate': 0.11,
          'conversion_rate': 0.06,
          'engagement_score': 0.28,
        };

        // Act
        final result = VariantResults.fromJson(json);

        // Assert
        expect(result.name, 'test_variant');
        expect(result.participants, 150);
        expect(result.deliveryRate, 0.96);
        expect(result.openRate, 0.34);
        expect(result.clickRate, 0.11);
        expect(result.conversionRate, 0.06);
        expect(result.engagementScore, 0.28);
      });
    });

    group('ABTest', () {
      test('should create from JSON correctly', () {
        // Arrange
        final json = {
          'test_name': 'engagement_test',
          'description': 'Testing different engagement strategies',
          'variants': [
            {'name': 'control', 'type': 'control', 'config': {}},
            {'name': 'urgent', 'type': 'urgent', 'config': {}},
          ],
          'traffic_allocation': {'control': 0.5, 'urgent': 0.5},
          'start_date': '2024-01-01T00:00:00Z',
          'end_date': '2024-01-31T23:59:59Z',
          'status': 'active',
        };

        // Act
        final test = ABTest.fromJson(json);

        // Assert
        expect(test.testName, 'engagement_test');
        expect(test.description, 'Testing different engagement strategies');
        expect(test.variants, hasLength(2));
        expect(test.trafficAllocation['control'], 0.5);
        expect(test.status, 'active');
        expect(test.startDate, DateTime.parse('2024-01-01T00:00:00Z'));
        expect(test.endDate, DateTime.parse('2024-01-31T23:59:59Z'));
      });

      test('should handle missing end date gracefully', () {
        // Arrange
        final json = {
          'test_name': 'open_ended_test',
          'description': 'Test with no end date',
          'variants': [
            {'name': 'control', 'type': 'control', 'config': {}},
          ],
          'traffic_allocation': {'control': 1.0},
          'start_date': '2024-01-01T00:00:00Z',
          'status': 'active',
        };

        // Act
        final test = ABTest.fromJson(json);

        // Assert
        expect(test.testName, 'open_ended_test');
        expect(test.endDate, isNull);
      });
    });

    group('Enum Tests', () {
      test('should have all required notification interaction types', () {
        // Act & Assert
        expect(
          NotificationInteractionType.values,
          contains(NotificationInteractionType.opened),
        );
        expect(
          NotificationInteractionType.values,
          contains(NotificationInteractionType.clicked),
        );
        expect(
          NotificationInteractionType.values,
          contains(NotificationInteractionType.dismissed),
        );
        expect(
          NotificationInteractionType.values,
          contains(NotificationInteractionType.completed),
        );
        expect(
          NotificationInteractionType.values,
          contains(NotificationInteractionType.actionTaken),
        );
        expect(
          NotificationInteractionType.values,
          contains(NotificationInteractionType.shared),
        );
      });

      test('should have all required variant types', () {
        // Act & Assert
        expect(VariantType.values, contains(VariantType.control));
        expect(VariantType.values, contains(VariantType.personalized));
        expect(VariantType.values, contains(VariantType.urgent));
        expect(VariantType.values, contains(VariantType.encouraging));
        expect(VariantType.values, contains(VariantType.social));
        expect(VariantType.values, contains(VariantType.gamified));
      });

      test('should have all required notification events', () {
        // Act & Assert
        expect(NotificationEvent.values, contains(NotificationEvent.sent));
        expect(NotificationEvent.values, contains(NotificationEvent.delivered));
        expect(NotificationEvent.values, contains(NotificationEvent.opened));
        expect(NotificationEvent.values, contains(NotificationEvent.clicked));
        expect(NotificationEvent.values, contains(NotificationEvent.dismissed));
        expect(NotificationEvent.values, contains(NotificationEvent.converted));
      });
    });
  });
}
