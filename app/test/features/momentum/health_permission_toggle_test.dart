import 'dart:async';

import 'package:app/core/services/health_permission_manager.dart';
import 'package:app/core/services/wearable_data_models.dart';
import 'package:app/features/momentum/presentation/widgets/health_permission_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/health_permission_provider.dart';

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

      // Stub fresh permission check so provider await doesn't fail in tests
      when(
        () => mockManager.checkPermissions(useCache: false),
      ).thenAnswer((_) async => {});
    });

    tearDown(() {
      deltaController.close();
    });

    testWidgets('updates based on deltaStream', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthPermissionManagerProvider.overrideWithValue(mockManager),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HealthPermissionToggle()),
          ),
        ),
      );

      // Allow provider to emit initial value
      await tester.pumpAndSettle();

      // Initial state should show "Not Connected" subtitle
      expect(find.textContaining('Not Connected'), findsOneWidget);

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

      // Widget should now show "Connected" subtitle
      expect(find.text('Connected'), findsOneWidget);
    });
  });
}
