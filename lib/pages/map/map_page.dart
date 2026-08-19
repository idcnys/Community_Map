import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/report_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/group_providers.dart';
import '../../services/report_post_service.dart';
import '../../services/group_chat_service.dart';
import '../../models/report_post_model.dart';
import 'report_post_form.dart';
import 'archived_reports_page.dart';
import 'report_detail_sheet.dart';
import 'report_preview_sheet.dart';
import 'map_notification_panel.dart';
import 'my_reports_page.dart';
import 'member_detail_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/guest_provider.dart';
import '../../providers/nearby_providers.dart';
import '../../models/nearby_place_model.dart';
import 'nearby_service_sheet.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final _chatService = GroupChatService();
  LatLng? _userLocation;
  late final AnimationController _blinkController;

  // Group location state
  String _selectedGroupFilter = 'global'; // 'global' or groupId
  List<Map<String, dynamic>> _memberLocations = [];
  List<String> _membersWithoutLocation = [];
  Map<String, String> _memberAvatars = {};
  StreamSubscription? _locationSub;
  Timer? _debounceTimer;
  bool _hasShownMissingToast = false;

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
    _locationSub?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  final LatLng _initialCenter = LatLng(23.8103, 90.4125);

  void _onGroupFilterChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedGroupFilter = value;
      _memberLocations = [];
      _membersWithoutLocation = [];
      _memberAvatars = {};
    });
    _locationSub?.cancel();

    if (value != 'global') {
      _hasShownMissingToast = false;
      _locationSub = _chatService.getGroupMemberLocations(value).listen((
        locations,
      ) {
        // Debounce: wait 500ms after last emission before rebuilding
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (!mounted) return;

          final myGroups = ref.read(myJoinedGroupsProvider).value ?? [];
          final group = myGroups.where((g) => g.id == value).firstOrNull;
          final allMembers = group?.members ?? [];

          final locUids = locations
              .map((l) => l['uid'] as String? ?? '')
              .toSet();
          final missing = allMembers
              .where((m) => !locUids.contains(m))
              .toList();

          setState(() {
            _memberLocations = locations;
            _membersWithoutLocation = missing;
          });

          // Fetch avatar URLs for members with locations
          _fetchMemberAvatars(locations);

          // Show toast only once per group selection
          if (missing.isNotEmpty && !_hasShownMissingToast) {
            _hasShownMissingToast = true;
            final names = missing.length > 2
                ? '${missing.length} members haven\'t shared location'
                : '${missing.length} member(s) haven\'t shared location yet';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(names),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // Fit map to show all member locations
          if (locations.isNotEmpty) {
            _fitToLocations(locations);
          }
        });
      });
    }
  }

  Future<void> _fetchMemberAvatars(List<Map<String, dynamic>> locations) async {
    final firestore = FirebaseFirestore.instance;
    final uids = locations
        .map((l) => l['uid'] as String? ?? '')
        .where((u) => u.isNotEmpty)
        .toList();

    for (final uid in uids) {
      if (_memberAvatars.containsKey(uid)) continue; // already fetched
      try {
        final doc = await firestore.collection('users').doc(uid).get();
        final imageUrl = doc.data()?['imageUrl'] as String? ?? '';
        if (imageUrl.isNotEmpty && mounted) {
          setState(() => _memberAvatars[uid] = imageUrl);
        }
      } catch (e) { debugPrint('[] error: $e'); }
    }
  }

  void _fitToLocations(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) return;
    final points = locations
        .map(
          (l) => LatLng(
            (l['latitude'] as num?)?.toDouble() ?? 0,
            (l['longitude'] as num?)?.toDouble() ?? 0,
          ),
        )
        .where((p) => p.latitude != 0 && p.longitude != 0)
        .toList();
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 14);
    } else {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now(); // Compute once, not per-marker
    final isGuest = ref.watch(isGuestProvider);
    final reports = ref.watch(activeReportsProvider).value ?? [];
    final hasActiveReport = ref.watch(hasActiveReportProvider);
    final nearbyState = ref.watch(nearbyProvider);

    // Show feedback + auto-zoom when nearby places load
    ref.listen(nearbyProvider, (prev, next) {
      if (prev == null || !prev.isLoading) return;
      if (next.isLoading) return;

      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: ${next.error}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.places.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${next.places.length} places found nearby'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Zoom to user's location to show results
        if (_userLocation != null) {
          _mapController.move(_userLocation!, 13);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No places found in this area'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    final myGroups = ref.watch(myJoinedGroupsProvider).value ?? [];

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: FlutterMap(
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
                bounds: LatLngBounds(LatLng(20.5, 88.0), LatLng(26.7, 92.7)),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.communityapp',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              // User's own location marker
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
                          border: Border.all(
                            color: theme.colorScheme.onPrimary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withAlpha(77),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.locateFixed,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              // Report markers (only in global mode)
              if (_selectedGroupFilter == 'global')
                MarkerLayer(
                  markers: reports.map((report) {
                    final point = LatLng(report.latitude, report.longitude);
                    final color = _markerColor(report, now);
                    final blink = _shouldBlink(report, now);

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
              // Group member location markers (blue)
              if (_selectedGroupFilter != 'global')
                MarkerLayer(
                  markers: _memberLocations.map((loc) {
                    final lat = (loc['latitude'] as num?)?.toDouble() ?? 0;
                    final lng = (loc['longitude'] as num?)?.toDouble() ?? 0;
                    if (lat == 0 && lng == 0) {
                      return Marker(
                        point: const LatLng(0, 0),
                        width: 0,
                        height: 0,
                        child: const SizedBox.shrink(),
                      );
                    }
                    final uid = loc['uid'] ?? '';
                    final name = loc['name'] ?? 'Member';
                    final avatarUrl = _memberAvatars[uid];
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showMemberDetail(uid, name),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2563EB),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withAlpha(100),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Icon(
                                      LucideIcons.user,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          LucideIcons.user,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.user,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              // Nearby services markers
              if (nearbyState.places.isNotEmpty)
                MarkerLayer(
                  markers: nearbyState.places.map((place) {
                    return Marker(
                      point: LatLng(place.latitude, place.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _onNearbyMarkerTap(place),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(place.category.markerColor),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Color(place.category.markerColor).withAlpha(80),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _nearbyCategoryIcon(place.category),
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          ),

          // Nearby category filter chips
          if (_selectedGroupFilter == 'global')
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 62, left: 12, right: 12),
                  child: _buildNearbyCategoryChips(nearbyState),
                ),
              ),
            ),

          // Top bar with dropdown
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onPrimary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    20,
                                  ),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGroupFilter,
                                isDense: true,
                                isExpanded: true,
                                icon: Icon(
                                  LucideIcons.chevronDown,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                style: TextStyle(
                                  color: isGuest
                                      ? theme.colorScheme.onSurfaceVariant
                                            .withAlpha(120)
                                      : theme.colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'global',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.globe, size: 16),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Global',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isGuest)
                                    ...myGroups.map(
                                      (g) => DropdownMenuItem(
                                        value: g.id,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              LucideIcons.users,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                g.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                                onChanged: isGuest ? null : _onGroupFilterChanged,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),
                        _circleButton(
                          icon: LucideIcons.archive,
                          tooltip: 'Archived Reports',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ArchivedReportsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildLatestReportsButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom left — map controls
          Positioned(
            bottom: 24,
            left: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'reset_map',
                  onPressed: _resetMapView,
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(
                    LucideIcons.crosshair,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  onPressed: _goToMyLocation,
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(
                    LucideIcons.locate,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Bottom right — action buttons
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
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => MyReportsPage()));
                  },
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(
                    LucideIcons.folderOpen,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'rush',
                  onPressed: hasActiveReport ? null : _submitRushReport,
                  backgroundColor: hasActiveReport
                      ? theme.colorScheme.onSurfaceVariant.withAlpha(150)
                      : const Color(0xFFFF1A1A),
                  child: Icon(
                    LucideIcons.send,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'post_report',
                  onPressed: hasActiveReport
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ReportPostForm(),
                            ),
                          );
                        },
                  child: const Icon(LucideIcons.plus),
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
      child: const Icon(
        LucideIcons.alertTriangle,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Color _markerColor(ReportPostModel report, DateTime now) {
    final age = now.difference(report.createdAt).inHours;
    if (age < 8) return const Color(0xFFEF4444);
    if (age < 16) return const Color(0xFFF97316);
    if (age < 24) return const Color(0xFF8B5CF6);
    return const Color(0xFF9CA3AF);
  }

  bool _shouldBlink(ReportPostModel report, DateTime now) {
    final age = now.difference(report.createdAt).inHours;
    return age < 24;
  }

  void _resetMapView() {
    // Clear my-location marker and nearby POI markers (hospital, police, etc.)
    // Report markers are untouched — they come from a stream provider.
    setState(() => _userLocation = null);
    ref.read(nearbyProvider.notifier).clear();

    if (_selectedGroupFilter == 'global') {
      _mapController.move(_initialCenter, 7.5);
    } else {
      _fitToLocations(_memberLocations);
    }
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
    _mapController.move(latLng, 15);
  }

  void _onMarkerTap(ReportPostModel report, LatLng point) {
    _mapController.move(point, 14);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReportPreviewSheet(
        report: report,
        userLat: _userLocation?.latitude,
        userLng: _userLocation?.longitude,
      ),
    );
  }

  Future<void> _submitRushReport() async {
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

    final service = ref.read(reportPostServiceProvider);
    final error = await service.createUrgentReport(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Urgent report submitted!'),
          backgroundColor: error != null ? Colors.red : null,
        ),
      );
    }
  }

  void _showMemberDetail(String uid, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MemberDetailSheet(uid: uid, name: name),
    );
  }

  Widget _buildLatestReportsButton() {
    final latestReports = ref.watch(latestReportsProvider);
    final count = latestReports.value?.length ?? 0;

    return Badge.count(
      count: count,
      isLabelVisible: count > 0,
      backgroundColor: Theme.of(context).colorScheme.error,
      child: _circleButton(
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
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
            blurRadius: 6,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 15, color: Theme.of(context).colorScheme.onSurface.withAlpha(220)),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  // ─── Nearby Services ─────────────────────────────────────────────────

  Widget _buildNearbyCategoryChips(NearbyState nearbyState) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: NearbyCategory.values.map((cat) {
                final isActive = nearbyState.activeCategories.contains(cat);
                final color = Color(cat.markerColor);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat.label),
                    selected: isActive,
                    onSelected: (_) => _toggleNearbyCategory(cat),
                    selectedColor: color.withAlpha(40),
                    checkmarkColor: color,
                    showCheckmark: false,
                    backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(230),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? color : Theme.of(context).colorScheme.onSurface,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (nearbyState.isLoading)
          const Padding(
            padding: EdgeInsets.only(left: 6),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Future<void> _toggleNearbyCategory(NearbyCategory category) async {
    // Use user's location; fetch it if not available yet
    LatLng searchCenter;
    if (_userLocation != null) {
      searchCenter = _userLocation!;
    } else {
      final position = await ReportPostService.getCurrentLocation();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enable location to find nearby services'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      searchCenter = LatLng(position.latitude, position.longitude);
      setState(() => _userLocation = searchCenter);
    }

    ref.read(nearbyProvider.notifier).toggleCategory(
      category,
      searchCenter.latitude,
      searchCenter.longitude,
    );
  }

  void _onNearbyMarkerTap(NearbyPlace place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => NearbyServiceSheet(place: place),
    );
  }

  IconData _nearbyCategoryIcon(NearbyCategory category) {
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
