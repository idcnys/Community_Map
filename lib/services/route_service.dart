import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Fetches driving/walking routes from OSRM and decodes polylines.
class RouteService {
  static const String _osrmBaseUrl =
      'https://router.project-osrm.org/route/v1';
  static const Duration _timeout = Duration(seconds: 15);

  /// Transport profile: `driving`, `walking`, `cycling`
  Future<RouteResult> fetchRoute({
    required LatLng from,
    required LatLng to,
    String profile = 'driving',
  }) async {
    // OSRM uses lon,lat order
    final url = Uri.parse(
      '$_osrmBaseUrl/$profile/'
      '${from.longitude},${from.latitude};'
      '${to.longitude},${to.latitude}'
      '?overview=full&geometries=polyline&steps=true',
    );

    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'CMap/1.0 (community-safety-app)'})
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return RouteResult.error('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final code = data['code'] as String? ?? '';
      if (code != 'Ok') {
        return RouteResult.error('OSRM error: $code');
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return RouteResult.error('No route found');
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as String? ?? '';
      final distance = (route['distance'] as num?)?.toDouble() ?? 0;
      final duration = (route['duration'] as num?)?.toDouble() ?? 0;

      // Extract turn-by-turn instructions from legs
      final steps = <RouteStep>[];
      final legs = route['legs'] as List<dynamic>? ?? [];
      for (final leg in legs) {
        final legSteps = (leg as Map<String, dynamic>)['steps'] as List<dynamic>? ?? [];
        for (final step in legSteps) {
          final s = step as Map<String, dynamic>;
          final maneuver = s['maneuver'] as Map<String, dynamic>? ?? {};
          final instruction = s['name'] as String? ?? '';
          final modifier = maneuver['modifier'] as String? ?? '';
          final type = maneuver['type'] as String? ?? '';
          final stepDist = (s['distance'] as num?)?.toDouble() ?? 0;

          String description;
          if (type == 'depart') {
            description = 'Start';
          } else if (type == 'arrive') {
            description = 'Arrive at destination';
          } else if (instruction.isNotEmpty) {
            description = '$type ${modifier.isNotEmpty ? modifier : ""} onto $instruction'.trim();
          } else {
            description = '$type ${modifier}'.trim();
          }

          steps.add(RouteStep(
            instruction: description,
            distance: stepDist,
          ));
        }
      }

      final points = _decodePolyline(geometry);
      return RouteResult.success(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration,
        steps: steps,
      );
    } catch (e) {
      return RouteResult.error(e.toString());
    }
  }

  /// Decode Google-encoded polyline string into List<LatLng>.
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

/// Result of a route fetch operation.
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;
  final String? error;

  bool get isSuccess => error == null;

  const RouteResult._({
    this.points = const [],
    this.distanceMeters = 0,
    this.durationSeconds = 0,
    this.steps = const [],
    this.error,
  });

  factory RouteResult.success({
    required List<LatLng> points,
    required double distanceMeters,
    required double durationSeconds,
    List<RouteStep> steps = const [],
  }) =>
      RouteResult._(
        points: points,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        steps: steps,
      );

  factory RouteResult.error(String message) =>
      RouteResult._(error: message);

  /// Human-readable distance string.
  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  /// Human-readable duration string.
  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours hr ${mins > 0 ? "$mins min" : ""}';
  }
}

/// A single navigation step/instruction.
class RouteStep {
  final String instruction;
  final double distance;

  const RouteStep({required this.instruction, required this.distance});

  String get distanceLabel {
    if (distance < 1000) return '${distance.round()} m';
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }
}
