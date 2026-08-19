import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/nearby_place_model.dart';
import '../../services/route_service.dart';
import 'package:latlong2/latlong.dart';

/// Bottom sheet showing details of a nearby service.
class NearbyServiceSheet extends StatefulWidget {
  final NearbyPlace place;
  /// Optional callback invoked after route is fetched, passing the result.
  /// Used by MapPage to draw the polyline on the map.
  final ValueChanged<RouteResult>? onRouteFetched;
  /// Callback to get user's current location for routing.
  final Future<LatLng?> Function()? onGetUserLocation;

  const NearbyServiceSheet({
    super.key,
    required this.place,
    this.onRouteFetched,
    this.onGetUserLocation,
  });

  @override
  State<NearbyServiceSheet> createState() => _NearbyServiceSheetState();
}

class _NearbyServiceSheetState extends State<NearbyServiceSheet> {
  bool _isFetchingRoute = false;
  RouteResult? _routeResult;
  String? _routeError;

  Future<void> _fetchRoute() async {
    if (widget.onGetUserLocation == null) return;

    setState(() {
      _isFetchingRoute = true;
      _routeResult = null;
      _routeError = null;
    });

    final userLoc = await widget.onGetUserLocation!();
    if (userLoc == null) {
      if (mounted) {
        setState(() {
          _isFetchingRoute = false;
          _routeError = 'Enable location to show route';
        });
      }
      return;
    }
    if (!mounted) return;

    final service = RouteService();
    final result = await service.fetchRoute(
      from: userLoc,
      to: LatLng(widget.place.latitude, widget.place.longitude),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _routeResult = result;
        _isFetchingRoute = false;
      });
      widget.onRouteFetched?.call(result);
    } else {
      setState(() {
        _isFetchingRoute = false;
        _routeError = result.error ?? 'Unknown error';
      });
    }
  }

  void _clearRoute() {
    setState(() {
      _routeResult = null;
      _routeError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(widget.place.category.markerColor);
    final hasRouting = widget.onRouteFetched != null && widget.onGetUserLocation != null;

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
                    child: Icon(_categoryIcon(widget.place.category), color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.place.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.place.category.label,
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

              // Full address from display_name
              if (widget.place.displayName != null)
                _infoRow(context, LucideIcons.mapPin, widget.place.displayName!),

              // Structured address (if different from displayName)
              if (widget.place.address != null && widget.place.address != widget.place.displayName)
                _infoRow(context, LucideIcons.navigation, widget.place.address!),

              // Contact info
              if (widget.place.phone != null) _infoRow(context, LucideIcons.phone, widget.place.phone!),
              if (widget.place.openingHours != null)
                _infoRow(context, LucideIcons.clock, widget.place.openingHours!),
              if (widget.place.website != null)
                _infoRow(context, LucideIcons.globe, widget.place.website!),

              // Coordinates
              _infoRow(
                context,
                LucideIcons.crosshair,
                '${widget.place.latitude.toStringAsFixed(5)}, ${widget.place.longitude.toStringAsFixed(5)}',
              ),

              const SizedBox(height: 16),

              // Action buttons row
              Row(
                children: [
                  // Show Route button (in-app navigation)
                  if (hasRouting)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isFetchingRoute ? null : _fetchRoute,
                        icon: _isFetchingRoute
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: color,
                                ),
                              )
                            : const Icon(LucideIcons.route, size: 18),
                        label: Text(_routeResult != null ? 'Route Shown' : 'Show Route'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _routeResult != null
                              ? theme.colorScheme.onSurfaceVariant
                              : color,
                          side: BorderSide(
                            color: _routeResult != null
                                ? theme.colorScheme.outlineVariant
                                : color,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  if (hasRouting) const SizedBox(width: 10),

                  // Navigate button (external Google Maps)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openInMaps(context),
                      icon: const Icon(LucideIcons.navigation, size: 18),
                      label: const Text('Navigate'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),

              // Route result toast bar (below buttons)
              if (_routeResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.route, size: 16, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_routeResult!.distanceLabel} · ${_routeResult!.durationLabel}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                            if (_routeResult!.steps.length > 2)
                              Text(
                                _routeResult!.steps[1].instruction,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearRoute,
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Route error toast
              if (_routeError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 16, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _routeError!,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _routeError = null),
                        child: const Icon(LucideIcons.x, size: 16, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],

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
        'https://www.google.com/maps/dir/?api=1&destination=${widget.place.latitude},${widget.place.longitude}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

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
