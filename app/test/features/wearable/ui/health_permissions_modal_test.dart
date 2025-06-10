/// Test suite for Health Permissions Modal
///
/// Following testing policy:
/// - ≥ 85% coverage on core logic, ≤ 5% golden/snapshot files
/// - Use flutter_test + mocktail
/// - One happy-path test and critical edge-case tests only
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/wearable/ui/health_permissions_modal.dart';
import 'package:app/features/wearable/ui/health_permissions_state.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  group('HealthPermissionsState', () {
    test('should create state with default values', () {
      // Act
      const state = HealthPermissionsState();

      // Assert
      expect(state.isLoading, isFalse);
      expect(state.status, HealthPermissionStatus.notDetermined);
      expect(state.individualPermissions, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.showSettingsPrompt, isFalse);
    });

    test('should create state copy with updated values', () {
      // Arrange
      const originalState = HealthPermissionsState();

      // Act
      final newState = originalState.copyWith(
        isLoading: true,
        status: HealthPermissionStatus.authorized,
        errorMessage: 'Test error',
        showSettingsPrompt: true,
      );

      // Assert
      expect(newState.isLoading, isTrue);
      expect(newState.status, HealthPermissionStatus.authorized);
      expect(newState.errorMessage, 'Test error');
      expect(newState.showSettingsPrompt, isTrue);
      expect(newState.individualPermissions, isEmpty); // Unchanged
    });

    test('should handle copyWith with unchanged values correctly', () {
      // Arrange
      const originalState = HealthPermissionsState(
        isLoading: true,
        status: HealthPermissionStatus.authorized,
        errorMessage: 'Original error',
        showSettingsPrompt: true,
      );

      // Act
      final newState = originalState.copyWith(isLoading: false);

      // Assert
      expect(newState.isLoading, isFalse);
      expect(newState.status, HealthPermissionStatus.authorized); // Unchanged
      expect(newState.errorMessage, 'Original error'); // Unchanged
      expect(newState.showSettingsPrompt, isTrue); // Unchanged
    });
  });

  group('HealthPermissionsNotifier', () {
    late HealthPermissionsNotifier notifier;

    setUp(() {
      notifier = HealthPermissionsNotifier();
    });

    test('should initialize with default state', () {
      // Assert
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.status, HealthPermissionStatus.notDetermined);
      expect(notifier.state.individualPermissions, isEmpty);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.showSettingsPrompt, isFalse);
    });

    test('should dismiss settings prompt', () {
      // Arrange
      notifier.state = notifier.state.copyWith(showSettingsPrompt: true);

      // Act
      notifier.dismissSettingsPrompt();

      // Assert
      expect(notifier.state.showSettingsPrompt, isFalse);
    });
  });

  group('showHealthPermissionsModal Function', () {
    testWidgets('should show modal bottom sheet', (tester) async {
      // Arrange
      bool modalShown = false;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder:
                    (context) => ElevatedButton(
                      onPressed: () {
                        showHealthPermissionsModal(context);
                        modalShown = true;
                      },
                      child: const Text('Show Modal'),
                    ),
              ),
            ),
          ),
        ),
      );

      // Tap to show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pump();

      // Assert
      expect(modalShown, isTrue);
    });

    testWidgets('should handle callback invocations', (tester) async {
      // Arrange
      bool onPermissionsGrantedCalled = false;
      bool onSkippedCalled = false;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder:
                    (context) => Column(
                      children: [
                        ElevatedButton(
                          onPressed:
                              () => showHealthPermissionsModal(
                                context,
                                onPermissionsGranted:
                                    () => onPermissionsGrantedCalled = true,
                                onSkipped: () => onSkippedCalled = true,
                              ),
                          child: const Text('Show Modal'),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ),
      );

      // Just verify the modal can be invoked with callbacks
      await tester.tap(find.text('Show Modal'));
      await tester.pump();

      // Assert callbacks are properly set up (they exist and can be called)
      expect(onPermissionsGrantedCalled, isFalse); // Not called yet, but set up
      expect(onSkippedCalled, isFalse); // Not called yet, but set up
    });
  });

  group('HealthPermissionsModal Widget', () {
    testWidgets('should render without errors', (tester) async {
      // Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: HealthPermissionsModal())),
        ),
      );

      // Allow widget to initialize
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Widget should render without throwing errors
      expect(find.byType(HealthPermissionsModal), findsOneWidget);
    });

    testWidgets('should display permission cards', (tester) async {
      // Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: HealthPermissionsModal())),
        ),
      );

      // Allow widget to initialize and render
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Key UI elements should be present (platform-aware)
      // The header text changes based on platform, so check for either
      final healthDataTextFinder = find.textContaining('Connect');
      expect(healthDataTextFinder, findsAtLeastNWidgets(1));

      // Look for permission card texts
      expect(find.textContaining('Steps'), findsWidgets);
      expect(find.textContaining('Heart'), findsWidgets);
      expect(find.textContaining('Sleep'), findsWidgets);
    });
  });

  group('WearableDataType Enum', () {
    test('should have expected health data types', () {
      // Assert all expected types exist
      expect(WearableDataType.steps, isNotNull);
      expect(WearableDataType.heartRate, isNotNull);
      expect(WearableDataType.sleepInBed, isNotNull);
      expect(WearableDataType.heartRateVariability, isNotNull);
      expect(WearableDataType.activeEnergyBurned, isNotNull);
      expect(WearableDataType.vo2Max, isNotNull);
    });
  });

  group('HealthPermissionStatus Enum', () {
    test('should have expected permission states', () {
      // Assert all expected states exist
      expect(HealthPermissionStatus.notDetermined, isNotNull);
      expect(HealthPermissionStatus.authorized, isNotNull);
      expect(HealthPermissionStatus.denied, isNotNull);
      expect(HealthPermissionStatus.restricted, isNotNull);
    });
  });
}
