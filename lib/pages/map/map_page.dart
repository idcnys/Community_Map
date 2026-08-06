
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/report_post_service.dart';
import '../../models/report_post_model.dart';
import 'report_post_form.dart';
import 'archived_reports_page.dart';
import 'report_detail_sheet.dart';
import 'map_notification_panel.dart';
import 'my_reports_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _reportService = ReportPostService();
  final MapController _mapController = MapController();
  List<ReportPostModel> _reports = [];
  bool _hasActiveReport = false;
  StreamSubscription? _activeReportSub;
  LatLng? _userLocation;

  // Default center (Dhaka, Bangladesh)
  final LatLng _initialCenter = LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    _activeReportSub = _reportService.getMyReports().listen((myReports) {
      final cutoff = DateTime.now().subtract(const Duration(hours: 48));
      final hasActive = myReports.any((r) => r.createdAt.isAfter(cutoff));
      if (hasActive != _hasActiveReport) {
        setState(() => _hasActiveReport = hasActive);
      }
    });
  }

  @override
  void dispose() {
    _activeReportSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ─── LEAFLET MAP ──────────────────────────────────────────
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
                  LatLng(20.5, 88.0), // SW Bangladesh
                  LatLng(26.7, 92.7), // NE Bangladesh
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
              // User location marker
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
                              color: Colors.blue.withOpacity(0.3),
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
              // Report markers
              StreamBuilder<List<ReportPostModel>>(
                stream: _reportService.getActiveReports(),
                builder: (context, snapshot) {
                  _reports = snapshot.data ?? [];
                  return MarkerLayer(
                    markers: _reports.map((report) {
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
                                  color: Colors.black.withOpacity(0.25),
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
                  );
                },
              ),
            ],
          ),

          // ─── TOP BAR ──────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Title
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
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
                    // Archive button (top right)
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
                    // Notification button
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

          // ─── BOTTOM RIGHT: RESET + POST + RUSH ────────────────────
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // My Reports button
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
                // Rush button (urgent emergency)
                FloatingActionButton.small(
                  heroTag: 'rush',
                  onPressed: _hasActiveReport ? null : _submitRushReport,
                  backgroundColor: _hasActiveReport
                      ? Colors.grey.shade400
                      : Colors.red.shade700,
                  child: const Icon(Icons.sos, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reset map to default BD view
                    FloatingActionButton.small(
                      heroTag: 'reset_map',
                      onPressed: _resetMapView,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.center_focus_strong,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    // My location button
                    FloatingActionButton.small(
                      heroTag: 'my_location',
                      onPressed: _goToMyLocation,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.location_searching,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    // Post report button
                    FloatingActionButton.extended(
                      heroTag: 'post_report',
                      onPressed: _hasActiveReport
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

  // ─── RESET MAP VIEW ──────────────────────────────────────────────
  void _resetMapView() {
    _mapController.move(_initialCenter, 7.5);
  }

  // ─── GO TO MY LOCATION ───────────────────────────────────────────
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
    final point = LatLng(position.latitude, position.longitude);
    setState(() => _userLocation = point);
    _mapController.move(point, 15.0);
  }

  // ─── REPORT DETAIL ───────────────────────────────────────────────
  void _onMarkerTap(ReportPostModel report, LatLng point) {
    _mapController.move(point, 15.0);
    _showReportDetail(report);
  }

  void _showReportDetail(ReportPostModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportDetailSheet(report: report),
    );
  }

  // ─── RUSH REPORT ─────────────────────────────────────────────────
  Future<void> _submitRushReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final position = await ReportPostService.getCurrentLocation();

    if (position == null) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Enable GPS and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final error = await _reportService.createUrgentReport(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss loading
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 Urgent emergency reported!'),
            backgroundColor: Colors.red,
          ),
        );
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15,
        );
      }
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

}
