import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/health_data/services/metabolic_health_score_service.dart';
import 'package:app/core/health_data/models/biometric_record.dart';
import 'package:app/core/health_data/mhs_coefficient_repository.dart';
import 'package:app/core/models/sex.dart';

// A simple fake AssetBundle that returns the provided JSON string.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._json);
  final String _json;
  @override
  Future<String> loadString(String key, {bool cache = true}) async => _json;
  @override
  Future<ByteData> load(String key) async => ByteData(0);
}

void main() {
  group('MetabolicHealthScoreService edge-case coverage', () {
    late MetabolicHealthScoreService service;

    // Minimal CDC reference JSON covering one male age-band – sufficient for tests.
    const cdcJson = '''{
      "male": {
        "18-29": { "height_cm_mean": 175, "height_cm_sd": 7,
                      "weight_kg_mean": 80,  "weight_kg_sd": 10 }
      }
    }''';

    setUp(() {
      service = MetabolicHealthScoreService(bundle: _FakeBundle(cdcJson));
    });

    test(
      'calculateScore throws when weight or height is non-positive',
      () async {
        expect(
          () => service.calculateScore(
            weightKg: 0,
            heightCm: 175,
            ageYears: 25,
            sex: Sex.male,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'calculateScore clamps extreme z-scores to 100th percentile',
      () async {
        final pct = await service.calculateScore(
          weightKg: 300, // far above mean
          heightCm: 500, // extreme height → |z| > 37 triggers fast-path CDF
          ageYears: 25,
          sex: Sex.male,
        );
        expect(pct, equals(100.0));
      },
    );

    group('calculateMhs', () {
      // JSON with deliberately extreme coefficients to exercise CDF edge paths.
      final negCoeffJson = jsonEncode({
        'non_hispanic_white_asian': {
          'male': [-100, 0, 0, 0, 0, 0],
        },
      });

      late MhsCoefficientRepository negRepo;

      setUp(() {
        negRepo = MhsCoefficientRepository.forBundle(_FakeBundle(negCoeffJson));
      });

      test('throws when TG is non-positive', () async {
        const rec = BiometricRecord(
          weightKg: 80,
          heightCm: 175,
          hdlMgDl: 50,
          sbp: 120,
          tgMgDl: 0, // invalid
          fgMgDl: 90,
          cohortKey: 'non_hispanic_white_asian',
          sex: Sex.male,
        );
        expect(
          () => service.calculateMhs(record: rec, coeffRepository: negRepo),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('returns 0th percentile for extremely negative Z-score', () async {
        const rec = BiometricRecord(
          weightKg:
              40, // low weight but irrelevant given huge negative intercept
          heightCm: 160,
          hdlMgDl: 40,
          sbp: 110,
          tgMgDl: 100,
          fgMgDl: 80,
          cohortKey: 'non_hispanic_white_asian',
          sex: Sex.male,
        );

        final mhs = await service.calculateMhs(
          record: rec,
          coeffRepository: negRepo,
        );
        expect(mhs, equals(0.0));
      });
    });
  });
}
