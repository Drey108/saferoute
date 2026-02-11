import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TravelMode { run, cycle }

extension TravelModeX on TravelMode {
  String get label => this == TravelMode.run ? 'Run' : 'Cycle';

  /// Used for Google Directions API.
  String get googleMode => this == TravelMode.run ? 'walking' : 'bicycling';

  IconData get icon => this == TravelMode.run ? Icons.directions_run_rounded : Icons.directions_bike_rounded;
}

class RouteModel {
  final String id;
  final String userId;
  final TravelMode mode;
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> polyline;
  final int distanceMeters;
  final int durationSeconds;
  final int? durationInTrafficSeconds;
  final int safetyScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RouteModel({
    required this.id,
    required this.userId,
    required this.mode,
    required this.origin,
    required this.destination,
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.durationInTrafficSeconds,
    required this.safetyScore,
    required this.createdAt,
    required this.updatedAt,
  });

  int get trafficDelaySeconds {
    final t = durationInTrafficSeconds;
    if (t == null) return 0;
    return (t - durationSeconds).clamp(0, 1 << 31);
  }

  RouteModel copyWith({
    String? id,
    String? userId,
    TravelMode? mode,
    LatLng? origin,
    LatLng? destination,
    List<LatLng>? polyline,
    int? distanceMeters,
    int? durationSeconds,
    int? durationInTrafficSeconds,
    int? safetyScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      polyline: polyline ?? this.polyline,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      durationInTrafficSeconds: durationInTrafficSeconds ?? this.durationInTrafficSeconds,
      safetyScore: safetyScore ?? this.safetyScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'mode': mode.name,
    'origin': {'lat': origin.latitude, 'lng': origin.longitude},
    'destination': {'lat': destination.latitude, 'lng': destination.longitude},
    'polyline': polyline.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    'distance_meters': distanceMeters,
    'duration_seconds': durationSeconds,
    'duration_in_traffic_seconds': durationInTrafficSeconds,
    'safety_score': safetyScore,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    LatLng parseLatLng(dynamic raw) {
      if (raw is Map) {
        final lat = (raw['lat'] as num?)?.toDouble() ?? 0;
        final lng = (raw['lng'] as num?)?.toDouble() ?? 0;
        return LatLng(lat, lng);
      }
      return const LatLng(0, 0);
    }

    final createdRaw = json['created_at'];
    final updatedRaw = json['updated_at'];

    final polyRaw = json['polyline'];
    final poly = <LatLng>[];
    if (polyRaw is List) {
      for (final p in polyRaw) {
        poly.add(parseLatLng(p));
      }
    }

    return RouteModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      mode: TravelMode.values.firstWhere((m) => m.name == json['mode'], orElse: () => TravelMode.run),
      origin: parseLatLng(json['origin']),
      destination: parseLatLng(json['destination']),
      polyline: poly,
      distanceMeters: (json['distance_meters'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      durationInTrafficSeconds: (json['duration_in_traffic_seconds'] as num?)?.toInt(),
      safetyScore: (json['safety_score'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(createdRaw?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(updatedRaw?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
