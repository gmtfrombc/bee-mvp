import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/validators/number_range_validator.dart';

void main() {
  group('NumberRangeValidator', () {
    test('weightLb returns error when empty', () {
      expect(NumberRangeValidator.weightLb(''), 'Required');
      expect(NumberRangeValidator.weightLb(null), 'Required');
    });

    test('weightLb returns error for non-numeric', () {
      expect(NumberRangeValidator.weightLb('abc'), 'Enter a valid number.');
    });

    test('weightLb returns error when out of range', () {
      expect(
        NumberRangeValidator.weightLb('40'),
        'Weight must be between 50 and 600.',
      );
      expect(
        NumberRangeValidator.weightLb('650'),
        'Weight must be between 50 and 600.',
      );
    });

    test('weightLb returns null when within range', () {
      expect(NumberRangeValidator.weightLb('150'), isNull);
      expect(NumberRangeValidator.weightLb('600'), isNull);
    });

    test('bpSystolic validation works', () {
      expect(
        NumberRangeValidator.bpSystolic('59'),
        'Systolic BP must be between 60 and 200.',
      );
      expect(NumberRangeValidator.bpSystolic('150'), isNull);
    });

    test('bpDiastolic validation works', () {
      expect(
        NumberRangeValidator.bpDiastolic('201'),
        'Diastolic BP must be between 60 and 200.',
      );
      expect(NumberRangeValidator.bpDiastolic('90'), isNull);
    });
  });
}
