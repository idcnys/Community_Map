import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/providers/nearby_providers.dart';
import 'package:cmap/models/nearby_place_model.dart';

void main() {
  group('NearbyState', () {
    test('default state is empty', () {
      const state = NearbyState();
      expect(state.places, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.activeCategories, isEmpty);
    });

    test('copyWith updates isLoading', () {
      const state = NearbyState();
      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
      expect(loading.places, isEmpty);
    });

    test('copyWith sets error', () {
      const state = NearbyState();
      final withError = state.copyWith(error: 'Location denied');
      expect(withError.error, 'Location denied');
    });

    test('copyWith clears error with clearError flag', () {
      final state = NearbyState(error: 'Some error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('copyWith updates places', () {
      const state = NearbyState();
      final places = <NearbyPlace>[
        NearbyPlace(id: '1', name: 'City Hospital', category: NearbyCategory.hospital, latitude: 23.78, longitude: 90.41),
        NearbyPlace(id: '2', name: 'Police Station', category: NearbyCategory.police, latitude: 23.79, longitude: 90.42),
      ];
      final updated = state.copyWith(places: places);
      expect(updated.places.length, 2);
      expect(updated.places[0].name, 'City Hospital');
    });

    test('copyWith updates activeCategories', () {
      const state = NearbyState();
      final updated = state.copyWith(activeCategories: {NearbyCategory.hospital});
      expect(updated.activeCategories, contains(NearbyCategory.hospital));
    });
  });

  group('NearbyCategory', () {
    test('has 4 categories', () {
      expect(NearbyCategory.values.length, 4);
    });

    test('hospital has correct label', () {
      expect(NearbyCategory.hospital.label, 'Hospital');
    });

    test('fromTags identifies hospital', () {
      final cat = NearbyCategory.fromTags({'amenity': 'hospital'});
      expect(cat, NearbyCategory.hospital);
    });

    test('fromTags identifies police', () {
      final cat = NearbyCategory.fromTags({'amenity': 'police'});
      expect(cat, NearbyCategory.police);
    });

    test('fromTags falls back to hospital for unknown', () {
      final cat = NearbyCategory.fromTags({'amenity': 'unknown'});
      expect(cat, NearbyCategory.hospital);
    });
  });
}
