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

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;

  final LatLng _initialCenter = LatLng(23.8103, 90.4125);

  @override
  Widget build(BuildContext context) {
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
                          color: Colors.blue.shade600,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.my_location,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: reports.map((report) {
                  final point = LatLng(report.latitude, report.longitude);
                  return Marker(
                    point: point,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _onMarkerTap(report, point),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: report.isUrgent
                              ? Colors.red.shade700
                              : Colors.orange.shade700,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          report.isUrgent
                              ? Icons.warning_amber_rounded
                              : Icons.report_problem,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map,
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
                      icon: Icons.archive_outlined,
                      tooltip: 'Archived Reports',
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ArchivedReportsPage(),
                        ));
                      },
                    ),
                    const SizedBox(width: 8),
                    _circleButton(
                      icon: Icons.notifications_outlined,
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
                      builder: (_) => const MyReportsPage(),
                    ));
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.folder_open,
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'rush',
                  onPressed: hasActiveReport ? null : _submitRushReport,
                  backgroundColor: hasActiveReport
                      ? Colors.grey.shade400
                      : Colors.red.shade700,
                  child: const Icon(Icons.sos, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'reset_map',
                      onPressed: _resetMapView,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.center_focus_strong,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: 'my_location',
                      onPressed: _goToMyLocation,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.location_searching,
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
                      icon: const Icon(Icons.add),
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
    _mapController.move(point, 15.0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReportDetailSheet(report: report),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
