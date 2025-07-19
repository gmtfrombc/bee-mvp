import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/health_data/services/metabolic_health_score_service.dart';
import 'package:app/core/health_data/models/biometric_record.dart';
import 'package:app/core/models/sex.dart';
import 'package:app/core/health_data/mhs_coefficient_repository.dart';

/// Fake bundle returning a supplied JSON string.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._json);
  final String _json;
  @override
  Future<String> loadString(String key, {bool cache = true}) async => _json;
  @override
  Future<ByteData> load(String key) async => ByteData(0);
}

void main() {
  group('MetabolicHealthScoreService.calculateMhs', () {
    late MetabolicHealthScoreService service;
    late MhsCoefficientRepository repo;

    const coeffJson = '''{
        "non_hispanic_white_asian": {
            "male": [-4.8316, 0.0315, -0.0272, 0.0044, 0.8018, 0.0101],
            "female": [-6.5231, 0.0523, -0.0138, 0.0081, 0.6125, 0.0208]
        }
    }''';

    setUp(() {
      repo = MhsCoefficientRepository.forBundle(_FakeBundle(coeffJson));
      service = MetabolicHealthScoreService();
    });

    test('computes expected percentile for sample record', () async {
      const record = BiometricRecord(
        weightKg: 80,
        heightCm: 175,
        hdlMgDl: 50,
        sbp: 120,
        tgMgDl: 150,
        fgMgDl: 90,
        cohortKey: 'non_hispanic_white_asian',
        sex: Sex.male,
      );

      final mhs = await service.calculateMhs(
        record: record,
        coeffRepository: repo,
      );
      expect(mhs, closeTo(53, 1));
    });

    test('derives FG from A1C when FG missing', () async {
      const record = BiometricRecord(
        weightKg: 80,
        heightCm: 175,
        hdlMgDl: 50,
        sbp: 120,
        tgMgDl: 150,
        a1cPercent: 5.6,
        cohortKey: 'non_hispanic_white_asian',
        sex: Sex.male,
      );
      final mhs = await service.calculateMhs(
        record: record,
        coeffRepository: repo,
      );
      expect(mhs, greaterThan(0));
    });
  });
}
