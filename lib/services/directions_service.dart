import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' hide TravelMode;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saferoute/models/route_model.dart';

class DirectionsService {
  /// REPLACE THIS WITH YOUR GOOGLE API KEY
  static const String googleApiKey = 'AIzaSyDk3lK7B2sTYr2egPzYVfzgJ7PHX9x9eW4';

  Future<RouteModel> fetchSafestRoute({required LatLng origin, required LatLng destination, required TravelMode mode}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      // Make initial request with requested mode
      var uri = _buildDirectionsUri(origin: origin, destination: destination, mode: mode, departureTime: now);
      var res = await http.get(uri);

      if (res.statusCode != 200) throw Exception('Directions API HTTP ${res.statusCode}: ${res.body}');

      var jsonBody = json.decode(res.body);
      if (jsonBody is! Map<String, dynamic>) throw Exception('Unexpected JSON shape');

      var status = jsonBody['status']?.toString();

      // Fallback to walking mode if cycling returns ZERO_RESULTS
      if (status == 'ZERO_RESULTS' && mode == TravelMode.cycle) {
        debugPrint('ZERO_RESULTS for cycling mode, retrying with walking mode');

        uri = _buildDirectionsUri(origin: origin, destination: destination, mode: TravelMode.run, departureTime: now);
        res = await http.get(uri);

        if (res.statusCode != 200) throw Exception('Directions API HTTP ${res.statusCode}: ${res.body}');

        jsonBody = json.decode(res.body);
        if (jsonBody is! Map<String, dynamic>) throw Exception('Unexpected JSON shape');

        status = jsonBody['status']?.toString();
      }

      if (status != 'OK') {
        final msg = jsonBody['error_message']?.toString();
        throw Exception('Directions API error: $status ${msg ?? ''}'.trim());
      }

      return _parseDirectionsResponse(jsonBody, origin, destination, mode);
    } catch (e) {
      debugPrint('fetchSafestRoute failed: $e');
      rethrow;
    }
  }

  Uri _buildDirectionsUri({
    required LatLng origin,
    required LatLng destination,
    required TravelMode mode,
    required int departureTime,
  }) {
    return Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'alternatives': 'true',
      'avoid': 'highways',
      'departure_time': '$departureTime',
      'traffic_model': 'best_guess',
      'mode': mode.googleMode,
      'key': googleApiKey,
    });
  }

  RouteModel _parseDirectionsResponse(
    Map<String, dynamic> jsonBody,
    LatLng origin,
    LatLng destination,
    TravelMode mode,
  ) {
    final routes = jsonBody['routes'];
    if (routes is! List || routes.isEmpty) throw Exception('No routes returned');

    RouteModel? best;
    for (final r in routes) {
      if (r is! Map) continue;
      final legs = r['legs'];
      if (legs is! List || legs.isEmpty || legs.first is! Map) continue;
      final leg = legs.first as Map;

      final distanceMeters = ((leg['distance'] as Map?)?['value'] as num?)?.toInt() ?? 0;
      final durationSeconds = ((leg['duration'] as Map?)?['value'] as num?)?.toInt() ?? 0;
      final durationTrafficSeconds = ((leg['duration_in_traffic'] as Map?)?['value'] as num?)?.toInt();

      final overview = (r['overview_polyline'] as Map?)?['points']?.toString() ?? '';
      final decoded = PolylinePoints.decodePolyline(overview);
      final polyline = decoded.map((p) => LatLng(p.latitude, p.longitude)).toList(growable: false);

      final score = computeSafetyScore(mode: mode, distanceMeters: distanceMeters, durationSeconds: durationSeconds, durationInTrafficSeconds: durationTrafficSeconds);

      final candidate = RouteModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userId: 'local-user',
        mode: mode,
        origin: origin,
        destination: destination,
        polyline: polyline,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        durationInTrafficSeconds: durationTrafficSeconds,
        safetyScore: score,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (best == null || candidate.safetyScore > best.safetyScore) best = candidate;
    }

    if (best == null) throw Exception('Failed to parse routes');
    return best;
  }

  static int computeSafetyScore({required TravelMode mode, required int distanceMeters, required int durationSeconds, required int? durationInTrafficSeconds}) {
    final distanceKm = distanceMeters / 1000.0;
    final delaySeconds = durationInTrafficSeconds == null ? 0 : (durationInTrafficSeconds - durationSeconds).clamp(0, 1 << 31);
    final delayMinutes = delaySeconds / 60.0;

    final (distancePenaltyMultiplier, delayPenaltyMultiplier) = mode == TravelMode.run
        ? (3.0, 1.5)
        : (4.0, 3.0);

    final score = 100 - (distanceKm * distancePenaltyMultiplier) - (delayMinutes * delayPenaltyMultiplier);
    return score.clamp(0, 100).round();
  }

  static int estimateRemainingDurationSeconds({required RouteModel route, required int remainingDistanceMeters}) {
    final denom = route.distanceMeters <= 0 ? 1 : route.distanceMeters;
    final baseSeconds = route.durationInTrafficSeconds ?? route.durationSeconds;
    final secondsPerMeter = baseSeconds / denom;
    return (remainingDistanceMeters * secondsPerMeter).round().clamp(0, 1 << 31);
  }

  /// Returns the minimum distance from [point] to the [polyline] in meters.
  /// Uses a lightweight equirectangular projection approximation (good for city-scale).
  static double minDistanceToPolylineMeters(LatLng point, List<LatLng> polyline) {
    if (polyline.length < 2) return double.infinity;

    double best = double.infinity;
    for (var i = 0; i < polyline.length - 1; i++) {
      final d = _distancePointToSegmentMeters(point, polyline[i], polyline[i + 1]);
      if (d < best) best = d;
    }
    return best;
  }

  static int remainingDistanceMetersAlongPolyline(LatLng current, List<LatLng> polyline) {
    if (polyline.length < 2) return 0;

    var nearestIndex = 0;
    var nearestDist = double.infinity;
    for (var i = 0; i < polyline.length; i++) {
      final d = _haversineMeters(current, polyline[i]);
      if (d < nearestDist) {
        nearestDist = d;
        nearestIndex = i;
      }
    }

    var sum = 0.0;
    for (var i = nearestIndex; i < polyline.length - 1; i++) {
      sum += _haversineMeters(polyline[i], polyline[i + 1]);
    }

    return sum.round();
  }

  static double _distancePointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    const r = 6371000.0;
    final lat = p.latitude * (math.pi / 180.0);
    final cosLat = math.cos(lat);

    final ax = (a.longitude - p.longitude) * (math.pi / 180.0) * r * cosLat;
    final ay = (a.latitude - p.latitude) * (math.pi / 180.0) * r;
    final bx = (b.longitude - p.longitude) * (math.pi / 180.0) * r * cosLat;
    final by = (b.latitude - p.latitude) * (math.pi / 180.0) * r;

    final abx = bx - ax;
    final aby = by - ay;
    final apx = -ax;
    final apy = -ay;

    final abLen2 = abx * abx + aby * aby;
    if (abLen2 == 0) return math.sqrt(apx * apx + apy * apy);

    var t = (apx * abx + apy * aby) / abLen2;
    if (t < 0) t = 0;
    if (t > 1) t = 1;

    final cx = ax + t * abx;
    final cy = ay + t * aby;
    return math.sqrt(cx * cx + cy * cy);
  }

  static double _haversineMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * (math.pi / 180.0);
    final dLng = (b.longitude - a.longitude) * (math.pi / 180.0);
    final lat1 = a.latitude * (math.pi / 180.0);
    final lat2 = b.latitude * (math.pi / 180.0);

    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final h = sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
    return 2 * r * math.asin(math.sqrt(h));
  }
}
