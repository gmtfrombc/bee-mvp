import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/health_data/services/biometric_flag_service.dart';
import 'package:app/core/health_data/models/biometric_flag.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('BiometricFlagService.fetchUnresolvedFlags', () {
    const userId = 'user-123';

    test('returns parsed list when data available', () async {
      final sampleRow = {
        'id': 'flag-1',
        'user_id': userId,
        'flag_type': 'low_steps',
        'detected_on': DateTime.utc(2025, 1, 1).toIso8601String(),
        'details': {'pct_of_mean': 50},
        'resolved': false,
      };

      final service = BiometricFlagService(
        supabaseClient: _MockSupabaseClient(),
        fetchOverride: (_) async => [sampleRow],
      );

      final result = await service.fetchUnresolvedFlags(userId);

      expect(result, hasLength(1));
      expect(result.first.id, equals('flag-1'));
      expect(result.first.type, equals(BiometricFlagType.lowSteps));
    });

    test('returns empty list when no data', () async {
      final service = BiometricFlagService(
        supabaseClient: _MockSupabaseClient(),
        fetchOverride: (_) async => [],
      );

      final result = await service.fetchUnresolvedFlags(userId);
      expect(result, isEmpty);
    });
  });
}
