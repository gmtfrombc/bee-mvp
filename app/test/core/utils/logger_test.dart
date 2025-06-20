import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/logger.dart';

void main() {
  group('Logger utility wrappers', () {
    test('log methods execute without throwing', () {
      expect(() => logD('debug message'), returnsNormally);
      expect(() => logI('info message'), returnsNormally);
      expect(() => logW('warning message'), returnsNormally);
      expect(() => logE('error message'), returnsNormally);
    });
  });
}
