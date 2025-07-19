import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/health_data/validators/biometric_validators.dart';

void main() {
  group('BiometricValidators.weight', () {
    test('returns error when empty', () {
      expect(BiometricValidators.weight('', unit: 'kg'), isNotNull);
    });

    test('valid kg within range returns null', () {
      expect(BiometricValidators.weight('70', unit: 'kg'), isNull);
    });

    test('invalid kg below range returns error', () {
      expect(BiometricValidators.weight('10', unit: 'kg'), isNotNull);
    });

    test('valid lbs converts and passes', () {
      expect(BiometricValidators.weight('154', unit: 'lbs'), isNull); // 70 kg
    });
  });

  group('BiometricValidators.height', () {
    test('valid cm within range returns null', () {
      expect(BiometricValidators.height('175', unit: 'cm'), isNull);
    });

    test('invalid cm low', () {
      expect(BiometricValidators.height('100', unit: 'cm'), isNotNull);
    });

    test('valid ft converts and passes', () {
      expect(BiometricValidators.height('5.7', unit: 'ft'), isNull); // ~173 cm
    });
  });

  group('BiometricValidators.fastingGlucose', () {
    test('empty returns error', () {
      expect(BiometricValidators.fastingGlucose(''), isNotNull);
    });

    test('valid value returns null', () {
      expect(BiometricValidators.fastingGlucose('90'), isNull);
    });

    test('out of range returns error', () {
      expect(BiometricValidators.fastingGlucose('400'), isNotNull);
    });
  });

  group('BiometricValidators.a1c', () {
    test('empty returns error', () {
      expect(BiometricValidators.a1c(''), isNotNull);
    });

    test('valid value returns null', () {
      expect(BiometricValidators.a1c('5.4'), isNull);
    });

    test('out of range returns error', () {
      expect(BiometricValidators.a1c('20'), isNotNull);
    });
  });
}
