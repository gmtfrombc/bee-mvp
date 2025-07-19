import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_theme.dart';
import 'dart:math' as math;

// Helper that returns the relative luminance of a colour per WCAG formula.
double _linearizeComponent(double channel) {
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color c) {
  final double r = _linearizeComponent(c.r);
  final double g = _linearizeComponent(c.g);
  final double b = _linearizeComponent(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

// Compute WCAG contrast ratio between two colours.
double _contrastRatio(Color a, Color b) {
  final double l1 = _relativeLuminance(a);
  final double l2 = _relativeLuminance(b);
  final double lighter = math.max(l1, l2);
  final double darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const Color lightBackground = Color(0xFFFFFFFF);
  const Color darkBackground = Color(0xFF121212);
  const double minContrast = 3.0; // WCAG AA threshold for non-text graphics

  final mhsColours = <Color>{
    AppTheme.mhsExcellent,
    AppTheme.mhsGood,
    AppTheme.mhsFair,
    AppTheme.mhsPoor,
    AppTheme.mhsVeryPoor,
  };

  for (final colour in mhsColours) {
    test('MHS colour $colour meets WCAG contrast ≥3', () {
      final ratioLight = _contrastRatio(colour, lightBackground);
      final ratioDark = _contrastRatio(colour, darkBackground);
      expect(
        ratioLight >= minContrast,
        isTrue,
        reason:
            'Contrast against white too low (ratio = ${ratioLight.toStringAsFixed(2)})',
      );
      expect(
        ratioDark >= minContrast,
        isTrue,
        reason:
            'Contrast against dark surface too low (ratio = ${ratioDark.toStringAsFixed(2)})',
      );
    });
  }
}
