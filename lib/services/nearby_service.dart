import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/nearby_place_model.dart';

/// Result of a nearby places fetch.
class NearbyResult {
  final List<NearbyPlace> places;
  final String? error;

  const NearbyResult({this.places = const [], this.error});
}

/// Fetches nearby services using OpenStreetMap Nominatim API.
/// Caches per-category per-location to minimize API calls.
class NearbyService {
  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/search';
  static const int _defaultRadiusMeters = 10000; // 10km
  static const int _maxResults = 50;
  static const Duration _cacheExpiry = Duration(minutes: 15);
  static const Duration _minRequestGap = Duration(seconds: 1);

  // Per-category cache: key = "category|gridCell"
  final Map<String, _CacheEntry> _cache = {};
  DateTime _lastRequestTime = DateTime(2000);

  /// Fetch nearby places. Only makes API calls for uncached categories.
  Future<NearbyResult> fetchNearbyPlaces({
    required double latitude,
    required double longitude,
    required List<NearbyCategory> categories,
    int radiusMeters = _defaultRadiusMeters,
  }) async {
    if (categories.isEmpty) return const NearbyResult();

    // Use a ~1km grid cell so small movements don't bust cache
    final gridLat = (latitude * 100).roundToDouble() / 100;
    final gridLon = (longitude * 100).roundToDouble() / 100;
    final gridKey = '${gridLat.toStringAsFixed(2)},${gridLon.toStringAsFixed(2)}';

    final allPlaces = <NearbyPlace>[];
    final seen = <String>{};
    String? lastError;
    bool madeApiCall = false;

    for (final category in categories) {
      final cacheKey = '${category.osmValue}|$gridKey|$radiusMeters';

      // Check per-category cache
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        // Use cached data — no API call
        for (final place in cached.places) {
          if (!seen.contains(place.id)) {
            seen.add(place.id);
            allPlaces.add(place);
          }
        }
        continue;
      }

      // Need to fetch this category from API
      // Rate limit: Nominatim allows 1 req/sec
      if (madeApiCall) {
        await Future.delayed(const Duration(milliseconds: 1100));
      }

      final elapsed = DateTime.now().difference(_lastRequestTime);
      if (elapsed < _minRequestGap) {
        await Future.delayed(_minRequestGap - elapsed);
      }

      try {
        _lastRequestTime = DateTime.now();

        // Calculate bounding box
        final latOffset = radiusMeters / 111320.0;
        final lonOffset =
            radiusMeters / (111320.0 * cos(latitude * pi / 180));
        final viewbox =
            '${longitude - lonOffset},${latitude + latOffset},${longitude + lonOffset},${latitude - latOffset}';

        final uri = Uri.parse(_nominatimUrl).replace(queryParameters: {
          'q': category.osmValue,
          'format': 'jsonv2',
          'bounded': '1',
          'viewbox': viewbox,
          'limit': '$_maxResults',
          'addressdetails': '1',
          'extratags': '1',
        });

        final response = await http
            .get(uri, headers: {
              'User-Agent': 'CMap/1.0 (community-safety-app)',
            })
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 429) {
          lastError = 'Rate limited. Try again shortly';
          continue;
        }

        if (response.statusCode != 200) {
          lastError = 'HTTP ${response.statusCode}';
          continue;
        }

        final results = jsonDecode(response.body) as List<dynamic>;
        final categoryPlaces = <NearbyPlace>[];

        for (final item in results) {
          final place = _parseNominatimResult(
            item as Map<String, dynamic>,
            category,
          );
          if (place == null) continue;
          categoryPlaces.add(place);

          if (!seen.contains(place.id)) {
            seen.add(place.id);
            allPlaces.add(place);
          }
        }

        // Cache this category's results
        _cache[cacheKey] = _CacheEntry(places: categoryPlaces);
        madeApiCall = true;
      } catch (e) {
        lastError = e.toString();
        continue;
      }
    }

    if (allPlaces.isEmpty && lastError != null) {
      return NearbyResult(error: lastError);
    }

    return NearbyResult(places: allPlaces);
  }

  NearbyPlace? _parseNominatimResult(
    Map<String, dynamic> item,
    NearbyCategory category,
  ) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;

    final name = item['name'] as String? ??
        item['display_name']?.toString().split(',').first ??
        category.label;

    final address = item['address'] as Map<String, dynamic>?;
    final addressStr = address != null
        ? [
            address['road'],
            address['suburb'],
            address['city'] ?? address['town'] ?? address['village'],
          ].whereType<String>().where((s) => s.isNotEmpty).join(', ')
        : null;

    final extratags = item['extratags'] as Map<String, dynamic>?;

    return NearbyPlace(
      id: 'osm_${item['place_id']}',
      name: name,
      category: category,
      latitude: lat,
      longitude: lon,
      displayName: item['display_name'] as String?,
      address: addressStr?.isEmpty == true ? null : addressStr,
      phone: extratags?['phone'] as String? ??
          extratags?['contact:phone'] as String?,
      website: extratags?['website'] as String? ??
          extratags?['contact:website'] as String?,
      openingHours: extratags?['opening_hours'] as String?,
    );
  }
}

class _CacheEntry {
  final List<NearbyPlace> places;
  final DateTime fetchedAt;

  _CacheEntry({required this.places}) : fetchedAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > NearbyService._cacheExpiry;
}
