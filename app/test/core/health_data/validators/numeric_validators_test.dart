import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/health_data/validators/numeric_validators.dart';

void main() {
  group('NumericValidators', () {
    test('isPositive', () {
      expect(NumericValidators.isPositive(5), isTrue);
      expect(NumericValidators.isPositive(0), isFalse);
      expect(NumericValidators.isPositive(-3), isFalse);
    });

    test('kg-lb converters are inverse within tolerance', () {
      const kg = 77.0;
      final lb = NumericValidators.kgToLb(kg);
      final kgBack = NumericValidators.lbToKg(lb);
      expect((kgBack - kg).abs() < 1e-6, isTrue);
    });

    test('weight validation', () {
      expect(NumericValidators.isWeightKgValid(70), isTrue);
      expect(NumericValidators.isWeightKgValid(10), isFalse);
      expect(NumericValidators.isWeightKgValid(400), isFalse);
    });

    test('heart rate validation', () {
      expect(NumericValidators.isHeartRateValid(60), isTrue);
      expect(NumericValidators.isHeartRateValid(25), isFalse);
      expect(NumericValidators.isHeartRateValid(300), isFalse);
    });
  });
}
