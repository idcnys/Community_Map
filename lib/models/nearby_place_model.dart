/// Represents a nearby service/place fetched from OpenStreetMap Overpass API.
class NearbyPlace {
  final String id;
  final String name;
  final NearbyCategory category;
  final double latitude;
  final double longitude;
  final String? displayName;
  final String? address;
  final String? phone;
  final String? website;
  final String? openingHours;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.displayName,
    this.address,
    this.phone,
    this.website,
    this.openingHours,
  });

  factory NearbyPlace.fromOverpassElement(Map<String, dynamic> element) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    final type = element['type'] as String? ?? '';
    final id = element['id']?.toString() ?? '';
    final lat = (type == 'node')
        ? (element['lat'] as num?)?.toDouble() ?? 0
        : (element['center']?['lat'] as num?)?.toDouble() ?? 0;
    final lng = (type == 'node')
        ? (element['lon'] as num?)?.toDouble() ?? 0
        : (element['center']?['lon'] as num?)?.toDouble() ?? 0;

    final name = tags['name'] as String? ??
        tags['name:bn'] as String? ??
        _fallbackName(tags);

    return NearbyPlace(
      id: '${type}_$id',
      name: name,
      category: NearbyCategory.fromTags(tags),
      latitude: lat,
      longitude: lng,
      address: _buildAddress(tags),
      phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
      website: tags['website'] as String? ?? tags['contact:website'] as String?,
      openingHours: tags['opening_hours'] as String?,
    );
  }

  static String _fallbackName(Map<String, dynamic> tags) {
    final amenity = tags['amenity'] as String? ?? '';
    final emergency = tags['emergency'] as String? ?? '';
    final key = amenity.isNotEmpty ? amenity : emergency;
    return key.replaceAll('_', ' ').toUpperCase();
  }

  static String? _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    final street = tags['addr:street'] as String?;
    final city = tags['addr:city'] as String?;
    final postcode = tags['addr:postcode'] as String?;
    if (street != null) parts.add(street);
    if (city != null) parts.add(city);
    if (postcode != null) parts.add(postcode);
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// Categories of nearby services supported.
enum NearbyCategory {
  hospital('Hospital', 'amenity', 'hospital'),
  police('Police', 'amenity', 'police'),
  fireStation('Fire Station', 'amenity', 'fire_station'),
  pharmacy('Pharmacy', 'amenity', 'pharmacy');


  final String label;
  final String osmKey;
  final String osmValue;

  const NearbyCategory(this.label, this.osmKey, this.osmValue);

  /// Determine category from OSM tags.
  static NearbyCategory fromTags(Map<String, dynamic> tags) {
    for (final cat in values) {
      if (tags[cat.osmKey] == cat.osmValue) return cat;
    }
    return NearbyCategory.hospital; // fallback
  }

  /// Color for map markers.
  int get markerColor {
    switch (this) {
      case NearbyCategory.hospital:
        return 0xFFDC2626; // red
      case NearbyCategory.police:
        return 0xFF1D4ED8; // blue
      case NearbyCategory.fireStation:
        return 0xFFEA580C; // orange
      case NearbyCategory.pharmacy:
        return 0xFF16A34A; // green
    }
  }
}
