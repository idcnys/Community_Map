import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/report_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/report_post_service.dart';
import '../../models/report_post_model.dart';
import 'report_post_form.dart';
import 'archived_reports_page.dart';
import 'report_detail_sheet.dart';
import 'map_notification_panel.dart';
import 'my_reports_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  final LatLng _initialCenter = LatLng(23.8103, 90.4125);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reports = ref.watch(activeReportsProvider).value ?? [];
    final hasActiveReport = ref.watch(hasActiveReportProvider);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 7.5,
              minZoom: 6.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  LatLng(20.5, 88.0),
                  LatLng(26.7, 92.7),
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.communityapp.app',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                          border: Border.all(color: theme.colorScheme.onPrimary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withAlpha(77),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(LucideIcons.locateFixed,
                            color: theme.colorScheme.onPrimary, size: 20),
                      ),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: reports.map((report) {
                  final point = LatLng(report.latitude, report.longitude);
                  final color = _markerColor(report);
                  final blink = _shouldBlink(report);

                  return Marker(
                    point: point,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _onMarkerTap(report, point),
                      child: blink
                          ? AnimatedBuilder(
                              animation: _blinkController,
                              builder: (_, child) => Opacity(
                                opacity: 0.4 + (_blinkController.value * 0.6),
                                child: child,
                              ),
                              child: _markerDot(color, report),
                            )
                          : _markerDot(color, report),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.onSurface.withAlpha(26),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.map,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Reports Map',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _circleButton(
                      icon: LucideIcons.archive,
                      tooltip: 'Archived Reports',
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ArchivedReportsPage(),
                        ));
                      },
                    ),
                    const SizedBox(width: 8),
                    _circleButton(
                      icon: LucideIcons.bell,
                      tooltip: 'Latest Reports',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const MapNotificationPanel(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom right buttons
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'my_reports',
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MyReportsPage(),
                    ));
                  },
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(LucideIcons.folderOpen,
                      color: Theme.of(context).colorScheme.primary),
                ),
                SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'rush',
                  onPressed: hasActiveReport ? null : _submitRushReport,
                  backgroundColor: hasActiveReport
                      ? theme.colorScheme.onSurfaceVariant.withAlpha(150)
                      : theme.colorScheme.error,
                  child: Icon(LucideIcons.siren, color: theme.colorScheme.onPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'reset_map',
                      onPressed: _resetMapView,
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(LucideIcons.crosshair,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: 'my_location',
                      onPressed: _goToMyLocation,
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(LucideIcons.locate,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.extended(
                      heroTag: 'post_report',
                      onPressed: hasActiveReport
                          ? null
                          : () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const ReportPostForm(),
                              ));
                            },
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Report'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _markerDot(Color color, ReportPostModel report) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(100),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        LucideIcons.alertTriangle,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  /// Returns marker color based on report age.
  Color _markerColor(ReportPostModel report) {
    final age = DateTime.now().difference(report.createdAt).inHours;
    if (age < 8) return const Color(0xFFEF4444);   // red
    if (age < 16) return const Color(0xFFF97316);  // orange
    if (age < 24) return const Color(0xFF8B5CF6);  // blue-violet
    return const Color(0xFF9CA3AF);                 // gray
  }

  /// Whether the marker should blink (< 24 hours old).
  bool _shouldBlink(ReportPostModel report) {
    final age = DateTime.now().difference(report.createdAt).inHours;
    return age < 24;
  }

  void _resetMapView() {
    _mapController.move(_initialCenter, 7.5);
  }

  Future<void> _goToMyLocation() async {
    final position = await ReportPostService.getCurrentLocation();
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Enable GPS and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final latLng = LatLng(position.latitude, position.longitude);
    setState(() => _userLocation = latLng);
    _mapController.move(latLng, 14.0);
  }

  void _onMarkerTap(ReportPostModel report, LatLng point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReportDetailSheet(
        report: report,
        onZoomToLocation: () {
          Navigator.of(context).pop();
          _mapController.move(point, 16.0);
        },
      ),
    );
  }

  Future<void> _submitRushReport() async {
    final position = await ReportPostService.getCurrentLocation();
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location for urgent report.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final error = await ref.read(reportPostServiceProvider).createUrgentReport(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Urgent report submitted!'),
          backgroundColor: error != null ? Colors.red : Colors.green,
        ),
      );
    }
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withAlpha(26),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
