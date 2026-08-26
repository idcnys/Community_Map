import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/nearby_place_model.dart';

/// Bottom sheet showing details of a nearby service.
class NearbyServiceSheet extends StatelessWidget {
  final NearbyPlace place;
  final LatLng? userLocation;
  /// Called when user taps "Route" to show in-app navigation on map.
  final VoidCallback? onShowRoute;

  const NearbyServiceSheet({
    super.key,
    required this.place,
    this.userLocation,
    this.onShowRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(place.category.markerColor);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: icon + name + category
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon(place.category), color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.category.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Distance from user
          if (userLocation != null) ...[
            _distanceChip(context, color),
            const SizedBox(height: 12),
          ],

          // Full address from display_name
          if (place.displayName != null)
            _infoRow(context, LucideIcons.mapPin, place.displayName!),

          // Structured address (if different from displayName)
          if (place.address != null && place.address != place.displayName)
            _infoRow(context, LucideIcons.navigation, place.address!),

          // Contact info
          if (place.phone != null) _infoRow(context, LucideIcons.phone, place.phone!),
          if (place.openingHours != null)
            _infoRow(context, LucideIcons.clock, place.openingHours!),
          if (place.website != null)
            _infoRow(context, LucideIcons.globe, place.website!),

          // Coordinates
          _infoRow(
            context,
            LucideIcons.crosshair,
            '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
          ),

          const SizedBox(height: 16),

          // Route + Navigate buttons side by side
          Row(
            children: [
              // In-app Route button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: userLocation != null && onShowRoute != null
                      ? () {
                          Navigator.pop(context);
                          onShowRoute!();
                        }
                      : null,
                  icon: const Icon(LucideIcons.route, size: 18),
                  label: const Text('রুট'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // External Navigate button
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openInMaps(context),
                  icon: const Icon(LucideIcons.navigation, size: 18),
                  label: const Text('নেভিগেট'),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),

            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openInMaps(BuildContext context) {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _distanceChip(BuildContext context, Color color) {
    final distMeters = _haversineDistance(
      userLocation!.latitude,
      userLocation!.longitude,
      place.latitude,
      place.longitude,
    );
    final label = distMeters < 1000
        ? '${distMeters.round()} মিটার দূরে'
        : '${(distMeters / 1000).toStringAsFixed(1)} কিমি দূরে';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.ruler, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Haversine distance in meters between two lat/lng points.
  static double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  IconData _categoryIcon(NearbyCategory category) {
    switch (category) {
      case NearbyCategory.hospital:
        return LucideIcons.hospital;
      case NearbyCategory.police:
        return LucideIcons.shield;
      case NearbyCategory.fireStation:
        return LucideIcons.flame;
      case NearbyCategory.pharmacy:
        return LucideIcons.pill;
    }
  }
}
