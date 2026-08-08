import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/models/nearby_place_model.dart';
import 'package:cmap/providers/nearby_providers.dart';

void main() {
  group('NearbyState', () {
    test('default state', () {
      const state = NearbyState();

      expect(state.places, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.activeCategories, isEmpty);
    });

    test('copyWith updates places', () {
      const state = NearbyState();
      final places = [
        const NearbyPlace(
          id: 'node_1',
          name: 'Hospital',
          category: NearbyCategory.hospital,
          latitude: 23.8,
          longitude: 90.4,
        ),
      ];

      final updated = state.copyWith(places: places);

      expect(updated.places.length, 1);
      expect(updated.places.first.name, 'Hospital');
    });

    test('copyWith updates isLoading', () {
      const state = NearbyState();
      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
    });

    test('copyWith sets error', () {
      const state = NearbyState();
      final updated = state.copyWith(error: 'Network error');

      expect(updated.error, 'Network error');
    });

    test('copyWith clearError removes error', () {
      final state = const NearbyState().copyWith(error: 'Some error');
      final updated = state.copyWith(clearError: true);

      expect(updated.error, isNull);
    });

    test('copyWith updates activeCategories', () {
      const state = NearbyState();
      final updated = state.copyWith(
        activeCategories: {NearbyCategory.hospital, NearbyCategory.police},
      );

      expect(updated.activeCategories.length, 2);
      expect(updated.activeCategories, contains(NearbyCategory.hospital));
      expect(updated.activeCategories, contains(NearbyCategory.police));
    });

    test('copyWith preserves unchanged fields', () {
      const state = NearbyState(isLoading: true);
      final updated = state.copyWith(error: 'err');

      expect(updated.isLoading, isTrue);
      expect(updated.error, 'err');
    });
  });
}
