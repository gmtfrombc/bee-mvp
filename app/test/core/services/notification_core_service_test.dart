import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/notifications/domain/services/notification_core_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationCoreService Tests', () {
    late NotificationCoreService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = NotificationCoreService.instance;
    });

    tearDown(() async {
      await _clearCachedData();
    });

    test('should set up callbacks correctly during initialization', () async {
      expect(
        () async => await service.initialize(
          onMessageReceived: (message) {},
          onMessageOpenedApp: (message) {},
          onTokenRefresh: (token) {},
        ),
        returnsNormally,
      );

      expect(service.isAvailable, isFalse);
    });

    test('should return null token when Firebase unavailable', () async {
      final token = await service.getToken();
      expect(token, isNull);
    });

    test('should store and retrieve token locally', () async {
      const testToken = 'test-fcm-token-12345';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', testToken);
      await prefs.setInt(
        'fcm_token_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      final storedToken = await service.getToken();
      expect(storedToken, equals(testToken));
    });

    test('should handle token deletion', () async {
      const testToken = 'test-fcm-token-12345';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', testToken);

      await service.deleteToken();

      final deletedToken = await service.getToken();
      expect(deletedToken, isNull);
    });

    test(
      'should return false for permissions when Firebase unavailable',
      () async {
        final hasPermissions = await service.hasPermissions();
        expect(hasPermissions, isFalse);
      },
    );
  });
}

// Helper methods
Future<void> _clearCachedData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}
