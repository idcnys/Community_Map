import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/models/nearby_place_model.dart';

void main() {
  group('NearbyPlace', () {
    group('fromOverpassElement', () {
      test('parses a node element', () {
        final element = <String, dynamic>{
          'type': 'node',
          'id': 12345,
          'lat': 23.8103,
          'lon': 90.4125,
          'tags': {
            'name': 'City Hospital',
            'amenity': 'hospital',
            'addr:street': 'Main Street',
            'addr:city': 'Dhaka',
            'phone': '02-1234567',
            'opening_hours': '24/7',
          },
        };

        final place = NearbyPlace.fromOverpassElement(element);

        expect(place.id, 'node_12345');
        expect(place.name, 'City Hospital');
        expect(place.category, NearbyCategory.hospital);
        expect(place.latitude, 23.8103);
        expect(place.longitude, 90.4125);
        expect(place.address, 'Main Street, Dhaka');
        expect(place.phone, '02-1234567');
        expect(place.openingHours, '24/7');
      });

      test('parses a way element with center', () {
        final element = <String, dynamic>{
          'type': 'way',
          'id': 67890,
          'center': {'lat': 23.82, 'lon': 90.42},
          'tags': {
            'name': 'Central Police Station',
            'amenity': 'police',
          },
        };

        final place = NearbyPlace.fromOverpassElement(element);

        expect(place.id, 'way_67890');
        expect(place.name, 'Central Police Station');
        expect(place.category, NearbyCategory.police);
        expect(place.latitude, 23.82);
        expect(place.longitude, 90.42);
      });

      test('uses name:bn as fallback for name', () {
        final element = <String, dynamic>{
          'type': 'node',
          'id': 111,
          'lat': 23.8,
          'lon': 90.4,
          'tags': {
            'name:bn': 'ঢাকা হাসপাতাল',
            'amenity': 'hospital',
          },
        };

        final place = NearbyPlace.fromOverpassElement(element);
        expect(place.name, 'ঢাকা হাসপাতাল');
      });

      test('uses amenity as fallback name when no name tag', () {
        final element = <String, dynamic>{
          'type': 'node',
          'id': 222,
          'lat': 23.8,
          'lon': 90.4,
          'tags': {
            'amenity': 'pharmacy',
          },
        };

        final place = NearbyPlace.fromOverpassElement(element);
        expect(place.name, 'PHARMACY');
      });

      test('handles missing tags gracefully', () {
        final element = <String, dynamic>{
          'type': 'node',
          'id': 333,
          'lat': 23.8,
          'lon': 90.4,
        };

        final place = NearbyPlace.fromOverpassElement(element);
        expect(place.name, isEmpty);
        expect(place.address, isNull);
        expect(place.phone, isNull);
      });

      test('builds address from all parts', () {
        final element = <String, dynamic>{
          'type': 'node',
          'id': 444,
          'lat': 23.8,
          'lon': 90.4,
          'tags': {
            'name': 'Test',
            'amenity': 'hospital',
            'addr:street': 'Road 5',
            'addr:city': 'Dhaka',
            'addr:postcode': '1207',
          },
        };

        final place = NearbyPlace.fromOverpassElement(element);
        expect(place.address, 'Road 5, Dhaka, 1207');
      });

      test('returns null address when no addr fields', () {
        final element = <String, dynamic>{
          'type': 'node',
          'id': 555,
          'lat': 23.8,
          'lon': 90.4,
          'tags': {
            'name': 'No Address Place',
            'amenity': 'hospital',
          },
        };

        final place = NearbyPlace.fromOverpassElement(element);
        expect(place.address, isNull);
      });

      test('parses contact:phone fallback', () {
        final element = <String, dynamic>{
          'type': 'node',
          'id': 666,
          'lat': 23.8,
          'lon': 90.4,
          'tags': {
            'name': 'Contact Place',
            'amenity': 'police',
            'contact:phone': '+880-1234',
          },
        };

        final place = NearbyPlace.fromOverpassElement(element);
        expect(place.phone, '+880-1234');
      });

      test('parses contact:website fallback', () {
        final element = <String, dynamic>{
          'type': 'node',
          'id': 777,
          'lat': 23.8,
          'lon': 90.4,
          'tags': {
            'name': 'Web Place',
            'amenity': 'fire_station',
            'contact:website': 'https://example.com',
          },
        };

        final place = NearbyPlace.fromOverpassElement(element);
        expect(place.website, 'https://example.com');
      });
    });
  });

  group('NearbyCategory', () {
    test('fromTags identifies hospital', () {
      expect(
        NearbyCategory.fromTags({'amenity': 'hospital'}),
        NearbyCategory.hospital,
      );
    });

    test('fromTags identifies police', () {
      expect(
        NearbyCategory.fromTags({'amenity': 'police'}),
        NearbyCategory.police,
      );
    });

    test('fromTags identifies fire_station', () {
      expect(
        NearbyCategory.fromTags({'amenity': 'fire_station'}),
        NearbyCategory.fireStation,
      );
    });

    test('fromTags identifies pharmacy', () {
      expect(
        NearbyCategory.fromTags({'amenity': 'pharmacy'}),
        NearbyCategory.pharmacy,
      );
    });

    test('fromTags defaults to hospital for unknown tags', () {
      expect(
        NearbyCategory.fromTags({'amenity': 'unknown'}),
        NearbyCategory.hospital,
      );
    });

    test('fromTags defaults to hospital for empty tags', () {
      expect(NearbyCategory.fromTags({}), NearbyCategory.hospital);
    });

    test('markerColor returns correct colors', () {
      expect(NearbyCategory.hospital.markerColor, 0xFFDC2626);
      expect(NearbyCategory.police.markerColor, 0xFF1D4ED8);
      expect(NearbyCategory.fireStation.markerColor, 0xFFEA580C);
      expect(NearbyCategory.pharmacy.markerColor, 0xFF16A34A);
    });

    test('labels are human-readable', () {
      expect(NearbyCategory.hospital.label, 'Hospital');
      expect(NearbyCategory.police.label, 'Police');
      expect(NearbyCategory.fireStation.label, 'Fire Station');
      expect(NearbyCategory.pharmacy.label, 'Pharmacy');
    });
  });
}
