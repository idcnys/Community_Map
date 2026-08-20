import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// A single instruction step along the route.
class RouteStep {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final LatLng startPoint;
  final LatLng endPoint;
  final int maneuverType; // 0=straight, 1=left, 2=right, etc.

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startPoint,
    required this.endPoint,
    this.maneuverType = 0,
  });

  /// Human-readable distance label.
  String get distanceLabel => distanceMeters < 1000
      ? '${distanceMeters.round()} m'
      : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

  /// Human-readable duration label.
  String get durationLabel {
    final mins = (durationSeconds / 60).round();
    if (mins < 1) return '<1 min';
    if (mins < 60) return '$mins min';
    final hrs = mins ~/ 60;
    final remMins = mins % 60;
    return remMins > 0 ? '$hrs hr $remMins min' : '$hrs hr';
  }
}

/// Result of an OSRM routing request.
class RouteResult {
  final List<LatLng> polylinePoints;
  final List<RouteStep> steps;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final String? error;

  const RouteResult({
    this.polylinePoints = const [],
    this.steps = const [],
    this.totalDistanceMeters = 0,
    this.totalDurationSeconds = 0,
    this.error,
  });

  bool get isSuccess => error == null && polylinePoints.isNotEmpty;

  /// Total distance as human-readable string.
  String get totalDistanceLabel => totalDistanceMeters < 1000
      ? '${totalDistanceMeters.round()} m'
      : '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';

  /// Total duration as human-readable string.
  String get totalDurationLabel {
    final mins = (totalDurationSeconds / 60).round();
    if (mins < 1) return '<1 min';
    if (mins < 60) return '$mins min';
    final hrs = mins ~/ 60;
    final remMins = mins % 60;
    return remMins > 0 ? '$hrs hr $remMins min' : '$hrs hr';
  }
}

/// Fetches driving/walking routes from OSRM public demo server.
class RouteService {
  static const String _osrmBaseUrl =
      'https://router.project-osrm.org/route/v1';

  /// Fetch a route between two points.
  /// [profile] can be 'driving', 'walking', or 'cycling'.
  Future<RouteResult> fetchRoute({
    required LatLng from,
    required LatLng to,
    String profile = 'driving',
  }) async {
    try {
      // OSRM uses lon,lat format
      final coordinates =
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';

      final uri = Uri.parse('$_osrmBaseUrl/$profile/$coordinates').replace(
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'true',
        },
      );

      final response = await http
          .get(uri, headers: {'User-Agent': 'CMap/1.0'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return RouteResult(error: 'Routing failed: HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final code = data['code'] as String? ?? '';

      if (code != 'Ok') {
        return RouteResult(error: 'Routing failed: $code');
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return const RouteResult(error: 'No route found');
      }

      final route = routes[0] as Map<String, dynamic>;

      // Parse geometry (GeoJSON LineString)
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coords = geometry?['coordinates'] as List<dynamic>? ?? [];

      final polylinePoints = coords.map((c) {
        final coord = c as List<dynamic>;
        return LatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        );
      }).toList();

      // Parse legs → steps for turn-by-turn instructions
      final steps = <RouteStep>[];
      final legs = route['legs'] as List<dynamic>? ?? [];

      for (final leg in legs) {
        final legSteps = (leg as Map<String, dynamic>)['steps'] as List<dynamic>? ?? [];
        for (final stepData in legSteps) {
          final step = stepData as Map<String, dynamic>;
          final maneuver = step['maneuver'] as Map<String, dynamic>? ?? {};
          final location = maneuver['location'] as List<dynamic>? ?? [0, 0];
          final modifier = maneuver['modifier'] as String? ?? '';
          final type = maneuver['type'] as String? ?? '';

          // Determine arrow direction from maneuver
          int maneuverCode = 0;
          if (modifier.contains('left')) {
            maneuverCode = 1;
          } else if (modifier.contains('right')) {
            maneuverCode = 2;
          } else if (type == 'turn' || type == 'depart' || type == 'arrive') {
            maneuverCode = 0;
          }

          // Build instruction text
          final name = step['name'] as String? ?? '';
          final instruction = _buildInstruction(type, modifier, name);

          final stepGeom = step['geometry'] as Map<String, dynamic>?;
          final stepCoords = stepGeom?['coordinates'] as List<dynamic>? ?? [];

          LatLng? endPoint;
          if (stepCoords.isNotEmpty) {
            final last = stepCoords.last as List<dynamic>;
            endPoint = LatLng(
              (last[1] as num).toDouble(),
              (last[0] as num).toDouble(),
            );
          }

          steps.add(RouteStep(
            instruction: instruction,
            distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0,
            durationSeconds: (step['duration'] as num?)?.toDouble() ?? 0,
            startPoint: LatLng(
              (location[1] as num?)?.toDouble() ?? 0,
              (location[0] as num?)?.toDouble() ?? 0,
            ),
            endPoint: endPoint ?? LatLng(0, 0),
            maneuverType: maneuverCode,
          ));
        }
      }

      return RouteResult(
        polylinePoints: polylinePoints,
        steps: steps,
        totalDistanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
        totalDurationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      return RouteResult(error: 'Route error: $e');
    }
  }

  String _buildInstruction(String type, String modifier, String roadName) {
    final road = roadName.isNotEmpty ? ' on $roadName' : '';
    switch (type) {
      case 'depart':
        return 'Start$road';
      case 'arrive':
        return 'Arrive at destination';
      case 'turn':
        if (modifier == 'left') return 'Turn left$road';
        if (modifier == 'right') return 'Turn right$road';
        if (modifier == 'straight') return 'Continue straight$road';
        return 'Turn $modifier$road';
      case 'merge':
        return 'Merge$road';
      case 'fork':
        return modifier == 'left' ? 'Keep left$road' : 'Keep right$road';
      case 'roundabout':
      case 'rotary':
        return 'Enter roundabout$road';
      case 'exit roundabout':
      case 'exit rotary':
        return 'Exit roundabout$road';
      case 'notification':
        return 'Continue$road';
      default:
        if (modifier.isNotEmpty) return '$modifier$road';
        return 'Continue$road';
    }
  }
}
