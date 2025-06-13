/// Tests for Android Permission Guidance Widget
///
/// Focuses on core business logic and essential functionality
/// following the project's testing policy of ≥85% coverage on core logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/wearable/ui/android_permission_guidance_widget.dart';
import 'package:app/features/wearable/ui/health_permissions_state.dart';
import 'package:app/core/services/wearable_data_models.dart';

void main() {
  group('AndroidPermissionGuidanceWidget', () {
    testWidgets(
      'shows guidance when permissions permanently denied on Android',
      (tester) async {
        // Arrange
        const state = HealthPermissionsState(
          isPermanentlyDenied: true,
          isHealthConnectAvailable: true,
          status: HealthPermissionStatus.denied,
        );

        bool settingsOpened = false;
        bool dismissed = false;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AndroidPermissionGuidanceWidget(
                state: state,
                onTryOpenSettings: () => settingsOpened = true,
                onDismiss: () => dismissed = true,
                forceShow: true, // Force show for testing
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Permissions Permanently Denied'), findsOneWidget);
        expect(find.text('Open Health Connect'), findsOneWidget);
        expect(
          find.text('Follow these steps to enable permissions:'),
          findsOneWidget,
        );

        // Test button interactions
        await tester.tap(find.text('Open Health Connect'));
        expect(settingsOpened, isTrue);

        await tester.tap(find.text('Dismiss'));
        expect(dismissed, isTrue);
      },
    );

    testWidgets('shows fallback guidance when Health Connect unavailable', (
      tester,
    ) async {
      // Arrange
      const state = HealthPermissionsState(
        isPermanentlyDenied: true,
        isHealthConnectAvailable: false,
        status: HealthPermissionStatus.denied,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AndroidPermissionGuidanceWidget(
              state: state,
              onTryOpenSettings: () {},
              onDismiss: () {},
              forceShow: true, // Force show for testing
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Open device Settings'), findsOneWidget);
      expect(
        find.textContaining('Consider installing Health Connect'),
        findsOneWidget,
      );
    });

    testWidgets('hides widget when not permanently denied', (tester) async {
      // Arrange
      const state = HealthPermissionsState(
        isPermanentlyDenied: false,
        isHealthConnectAvailable: true,
        status: HealthPermissionStatus.notDetermined,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AndroidPermissionGuidanceWidget(
              state: state,
              onTryOpenSettings: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Permissions Permanently Denied'), findsNothing);
    });
  });
}
