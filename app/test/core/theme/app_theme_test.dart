import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme has expected primary colors', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppTheme.momentumRising);
      expect(theme.colorScheme.secondary, AppTheme.momentumSteady);
      expect(theme.colorScheme.tertiary, AppTheme.momentumCare);
      expect(theme.scaffoldBackgroundColor, AppTheme.surfaceSecondary);
    });

    test('darkTheme has expected primary colors', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppTheme.momentumRisingLight);
      expect(theme.colorScheme.secondary, AppTheme.momentumSteadyLight);
      expect(theme.colorScheme.tertiary, AppTheme.momentumCareLight);
      expect(theme.scaffoldBackgroundColor, AppTheme.darkSurfaceSecondary);
    });

    test('typography overrides apply', () {
      final light = AppTheme.lightTheme.textTheme.titleLarge;
      final dark = AppTheme.darkTheme.textTheme.titleLarge;
      // Ensure colors differ between light and dark schemes
      expect(light?.color, isNot(equals(dark?.color)));
      // Ensure font size remains consistent across modes
      expect(light?.fontSize, equals(dark?.fontSize));
    });
  });
}
