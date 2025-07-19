import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/health_data/mhs_category_mapper.dart';

void main() {
  group('mapMhsToCategory', () {
    test('returns firstGear for <20', () {
      expect(mapMhsToCategory(0), MhsCategory.firstGear);
      expect(mapMhsToCategory(19.9), MhsCategory.firstGear);
    });

    test('returns stepItUp for 20–39.9', () {
      expect(mapMhsToCategory(20), MhsCategory.stepItUp);
      expect(mapMhsToCategory(39.9), MhsCategory.stepItUp);
    });

    test('returns onTrack for 40–54.9', () {
      expect(mapMhsToCategory(40), MhsCategory.onTrack);
      expect(mapMhsToCategory(54.9), MhsCategory.onTrack);
    });

    test('returns inTheZone for 55–69.9', () {
      expect(mapMhsToCategory(55), MhsCategory.inTheZone);
      expect(mapMhsToCategory(69.9), MhsCategory.inTheZone);
    });

    test('returns peakMomentum for ≥70', () {
      expect(mapMhsToCategory(70), MhsCategory.peakMomentum);
      expect(mapMhsToCategory(99.9), MhsCategory.peakMomentum);
      expect(mapMhsToCategory(100), MhsCategory.peakMomentum);
    });

    test('throws for NaN input', () {
      expect(() => mapMhsToCategory(double.nan), throwsArgumentError);
    });
  });
}
