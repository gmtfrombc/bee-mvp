import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/notifications/domain/models/notification_models.dart';
import 'package:app/core/notifications/domain/models/notification_types.dart';
import 'dart:convert';

void main() {
  group('NotificationAction', () {
    test('toMap serializes correctly', () {
      final action = NotificationAction(
        id: 'btn1',
        title: 'Open',
        action: 'open_app',
        metadata: {'route': '/dashboard'},
      );
      final map = action.toMap();
      expect(map['id'], 'btn1');
      expect(map['title'], 'Open');
      expect(map['action'], 'open_app');
      expect(map['metadata']['route'], '/dashboard');
    });
  });

  group('NotificationContent', () {
    final content = NotificationContent(
      type: 'coach_update',
      title: 'Momentum Rising!',
      body: 'Great job keeping your streak alive.',
      data: {'momentum': 'rising'},
      actionButtons: [
        NotificationAction(id: 'ok', title: 'OK', action: 'dismiss'),
      ],
    );

    test('toFCMPayload includes expected fields', () {
      final payload = content.toFCMPayload();
      expect(payload['notification']['title'], content.title);
      expect(payload['notification']['body'], content.body);
      expect(payload['data']['type'], content.type);
      expect(payload['data']['actions'], isA<List<dynamic>>());
    });

    test('toLocalNotificationPayload includes expected fields', () {
      final payload = content.toLocalNotificationPayload();
      expect(payload['title'], content.title);
      expect(payload['body'], content.body);
      expect(payload['payload']['type'], content.type);
    });
  });

  group('NotificationData serialization', () {
    final now = DateTime.utc(2024, 6, 30, 12);
    final data = NotificationData(
      notificationId: 'n1',
      interventionType: 'streak',
      actionType: 'open',
      actionData: {'foo': 'bar'},
      title: 'Hello',
      body: 'World',
      receivedAt: now,
    );

    test('toJson / fromJson symmetry', () {
      final jsonMap = data.toJson();
      final decoded = NotificationData.fromJson(jsonMap);
      expect(decoded.notificationId, data.notificationId);
      expect(decoded.interventionType, data.interventionType);
      expect(decoded.actionType, data.actionType);
      expect(decoded.actionData, data.actionData);
      expect(decoded.title, data.title);
      expect(decoded.body, data.body);
      expect(decoded.receivedAt.toIso8601String(), now.toIso8601String());
    });
  });

  group('PendingNotificationAction serialization', () {
    final now = DateTime.utc(2024, 6, 30, 13);
    final pending = PendingNotificationAction(
      notificationId: 'n2',
      actionType: 'dismiss',
      actionData: {'x': 1},
      receivedAt: now,
    );

    test('toJson / fromJson symmetry', () {
      final jsonMap = pending.toJson();
      final decoded = PendingNotificationAction.fromJson(jsonMap);
      expect(decoded.notificationId, pending.notificationId);
      expect(decoded.actionType, pending.actionType);
      expect(decoded.actionData, pending.actionData);
      expect(decoded.receivedAt.toIso8601String(), now.toIso8601String());
    });
  });

  group('NotificationVariant serialization', () {
    test('control factory returns correct default variant', () {
      final control = NotificationVariant.control();
      expect(control.name, 'control');
      expect(control.type.name, 'control');
      expect(control.config, isEmpty);
    });

    test('toJson / fromJson symmetry', () {
      final variant = NotificationVariant(
        name: 'test',
        type: VariantType.personalized,
        config: {'percentage': 50},
      );
      final jsonString = jsonEncode(variant.toJson());
      final decoded = NotificationVariant.fromJson(jsonDecode(jsonString));
      expect(decoded.name, variant.name);
      expect(decoded.type, variant.type);
      expect(decoded.config, variant.config);
    });
  });
}
