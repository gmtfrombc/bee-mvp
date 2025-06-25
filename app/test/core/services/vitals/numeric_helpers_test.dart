import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/vitals/processing/numeric_helpers.dart';

class _FakeWrapper {
  final double numericValue;
  _FakeWrapper(this.numericValue);
}

void main() {
  group('NumericHelpers', () {
    test('converts num directly', () {
      expect(NumericHelpers.toDouble(42), 42.0);
      expect(NumericHelpers.toInt(42.7), 43);
    });

    test('extracts numericValue property', () {
      final wrapper = _FakeWrapper(55.5);
      expect(NumericHelpers.toDouble(wrapper), 55.5);
    });

    test('parses from string fallback', () {
      expect(
        NumericHelpers.toDouble('NumericHealthValue - numericValue: 215.0'),
        215.0,
      );
    });

    test('returns null when no number', () {
      expect(NumericHelpers.toDouble('no digits'), isNull);
    });
  });
}
