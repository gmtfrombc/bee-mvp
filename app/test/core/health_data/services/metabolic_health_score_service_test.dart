import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/health_data/services/metabolic_health_score_service.dart';
import 'package:app/core/models/sex.dart';

/// A fake [AssetBundle] that returns the provided [_json] string.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._json);

  final String _json;

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _json;

  @override
  Future<ByteData> load(String key) async => ByteData(0);
}

void main() {
  group('MetabolicHealthScoreService', () {
    late MetabolicHealthScoreService service;

    const sampleJson = '''{
      "male": {
        "18-29": { "height_cm_mean": 175.0, "height_cm_sd": 7.0,
                     "weight_kg_mean": 80.0,  "weight_kg_sd": 10.0 },
        "30-39": { "height_cm_mean": 176.0, "height_cm_sd": 7.2,
                     "weight_kg_mean": 85.0,  "weight_kg_sd": 11.0 }
      },
      "female": {
        "18-29": { "height_cm_mean": 162.0, "height_cm_sd": 6.0,
                     "weight_kg_mean": 70.0,  "weight_kg_sd": 9.0 },
        "30-39": { "height_cm_mean": 163.0, "height_cm_sd": 6.3,
                     "weight_kg_mean": 72.0,  "weight_kg_sd": 9.5 }
      }
    }''';

    setUp(() {
      service = MetabolicHealthScoreService(bundle: _FakeBundle(sampleJson));
    });

    test('returns ~50th percentile for mean values', () async {
      final score = await service.calculateScore(
        weightKg: 80.0,
        heightCm: 175.0,
        ageYears: 25,
        sex: Sex.male,
      );
      expect(score, closeTo(50.0, 0.5));
    });

    test('higher weight and height yields >50 percentile', () async {
      final score = await service.calculateScore(
        weightKg: 90.0,
        heightCm: 182.0,
        ageYears: 28,
        sex: Sex.male,
      );
      expect(score, greaterThan(50));
    });

    test('throws ArgumentError for unsupported age', () async {
      expect(
        () => service.calculateScore(
          weightKg: 80,
          heightCm: 175,
          ageYears: 10,
          sex: Sex.male,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
