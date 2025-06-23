import 'dart:async';

import 'package:app/core/services/health_permission_manager.dart';
import 'package:app/core/services/wearable_data_models.dart';
import 'package:app/features/momentum/presentation/widgets/health_permission_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthPermissionManager extends Mock
    implements HealthPermissionManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthPermissionToggle', () {
    late MockHealthPermissionManager mockManager;
    late StreamController<List<PermissionDelta>> deltaController;

    setUp(() {
      mockManager = MockHealthPermissionManager();
      deltaController = StreamController<List<PermissionDelta>>.broadcast();

      // Default stubs
      when(
        () => mockManager.deltaStream,
      ).thenAnswer((_) => deltaController.stream);
      when(() => mockManager.isInitialized).thenReturn(true);
      when(() => mockManager.initialize()).thenAnswer((_) async => true);
      when(
        () => mockManager.config,
      ).thenReturn(const PermissionManagerConfig());

      // Start with permissions NOT granted
      when(() => mockManager.permissionCache).thenReturn({});

      // Stub requestPermissions to return granted
      when(
        () => mockManager.requestPermissions(),
      ).thenAnswer((_) async => {WearableDataType.steps: true});
    });

    tearDown(() {
      deltaController.close();
    });

    testWidgets('updates based on deltaStream', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HealthPermissionToggle(manager: mockManager)),
        ),
      );

      // Initial state should show Not Granted
      expect(find.text('Not Granted'), findsOneWidget);

      // Update permissionCache to granted for all required types
      final now = DateTime.now();
      final grantedMap = {
        for (final t in mockManager.config.requiredPermissions)
          t: PermissionCacheEntry(
            dataType: t,
            isGranted: true,
            lastChecked: now,
          ),
      };
      when(() => mockManager.permissionCache).thenReturn(grantedMap);

      // Emit delta to notify widgets
      deltaController.add([
        PermissionDelta(
          dataType: WearableDataType.steps,
          previousStatus: false,
          currentStatus: true,
          timestamp: now,
        ),
      ]);

      await tester.pumpAndSettle();

      // Widget should now show Granted
      expect(find.text('Granted'), findsOneWidget);
    });
  });
}
