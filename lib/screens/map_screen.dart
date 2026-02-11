import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferoute/components/floating_info_card.dart';
import 'package:saferoute/components/map_action_pill.dart';
import 'package:saferoute/models/route_model.dart';
import 'package:saferoute/services/directions_service.dart';
import 'package:saferoute/services/location_service.dart';
import 'package:saferoute/theme.dart';

class MapScreen extends StatefulWidget {
  final TravelMode mode;

  const MapScreen({super.key, required this.mode});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _locationService = const LocationService();
  final _directionsService = DirectionsService();

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;

  Position? _current;
  LatLng? _destination;
  RouteModel? _route;

  bool _isFetchingRoute = false;
  DateTime? _lastRefetchAt;

  bool _navigationStarted = false;

  int _remainingDistanceMeters = 0;
  int _remainingDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final pos = await _locationService.getCurrentPosition();
    if (!mounted) return;

    if (pos == null) {
      _showSnack('Location permission is required. Please enable GPS and allow permission.');
      return;
    }

    setState(() => _current = pos);
  }

  void _startNavigation() {
    _positionSub = _locationService.watchPosition().listen((p) {
      _current = p;
      if (mounted) setState(() {});
      _updateCameraFollow();
      _updateMetrics();
      _checkDeviationAndRefetch();
    });

    setState(() => _navigationStarted = true);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _updateCameraFollow() async {
    final c = _mapController;
    final p = _current;
    if (c == null || p == null) return;

    try {
      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(p.latitude, p.longitude), zoom: 16.2, tilt: 0, bearing: p.heading.isNaN ? 0 : p.heading),
        ),
      );
    } catch (e) {
      debugPrint('animateCamera failed: $e');
    }
  }

  void _updateMetrics() {
    final route = _route;
    final pos = _current;
    if (route == null || pos == null) return;

    final currentLatLng = LatLng(pos.latitude, pos.longitude);
    final remaining = DirectionsService.remainingDistanceMetersAlongPolyline(currentLatLng, route.polyline);
    final remainingSecs = DirectionsService.estimateRemainingDurationSeconds(route: route, remainingDistanceMeters: remaining);

    setState(() {
      _remainingDistanceMeters = remaining;
      _remainingDurationSeconds = remainingSecs;
    });
  }

  Future<void> _checkDeviationAndRefetch() async {
    final route = _route;
    final dest = _destination;
    final pos = _current;
    if (route == null || dest == null || pos == null) return;

    final now = DateTime.now();
    final last = _lastRefetchAt;
    if (last != null && now.difference(last).inSeconds < 8) return;
    if (_isFetchingRoute) return;

    final currentLatLng = LatLng(pos.latitude, pos.longitude);
    final d = DirectionsService.minDistanceToPolylineMeters(currentLatLng, route.polyline);
    if (d <= 30) return;

    _lastRefetchAt = now;
    await _fetchRoute(origin: currentLatLng, destination: dest, showLoading: false);
  }

  Future<void> _fetchRoute({required LatLng origin, required LatLng destination, required bool showLoading}) async {
    if (_isFetchingRoute) return;

    setState(() => _isFetchingRoute = showLoading);
    try {
      final r = await _directionsService.fetchSafestRoute(origin: origin, destination: destination, mode: widget.mode);
      if (!mounted) return;

      // Distance boundary validation
      final maxDistanceMeters = widget.mode == TravelMode.run ? 25000 : 80000;
      if (r.distanceMeters > maxDistanceMeters) {
        final modeLabel = widget.mode == TravelMode.run ? 'run' : 'cycle';
        _showSnack('Destination too far for a single $modeLabel session.');
        return;
      }

      setState(() {
        _route = r;
        _remainingDistanceMeters = r.distanceMeters;
        _remainingDurationSeconds = r.durationInTrafficSeconds ?? r.durationSeconds;
      });

      if (_mapController != null) {
        final bounds = _boundsForPolyline(r.polyline);
        if (bounds != null) {
          await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
        }
      }
    } catch (e) {
      debugPrint('Route fetch failed: $e');
      if (mounted) _showSnack('Failed to fetch route. Check API key & internet.');
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }

  LatLngBounds? _boundsForPolyline(List<LatLng> polyline) {
    if (polyline.isEmpty) return null;

    var minLat = polyline.first.latitude;
    var maxLat = polyline.first.latitude;
    var minLng = polyline.first.longitude;
    var maxLng = polyline.first.longitude;

    for (final p in polyline) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  void _showSnack(String msg) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(msg, maxLines: 3, overflow: TextOverflow.ellipsis)));
  }

  String _formatDistance(int meters) {
    if (meters <= 0) return '--';
    if (meters < 1000) return '$meters m';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  String _formatEta(int seconds) {
    if (seconds <= 0) return '--';
    final mins = (seconds / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final pos = _current;
    final currentLatLng = pos == null ? null : LatLng(pos.latitude, pos.longitude);

    final markers = <Marker>{};
    if (currentLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: currentLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ));
    }
    if (_destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('dest'),
        position: _destination!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: const InfoWindow(title: 'Destination'),
      ));
    }

    final polylines = <Polyline>{};
    final route = _route;
    if (route != null && route.polyline.isNotEmpty) {
      polylines.add(Polyline(
        polylineId: const PolylineId('safe_route'),
        points: route.polyline,
        width: 6,
        color: scheme.primary,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ));
    }

    final trafficDelayMin = route == null ? 0 : (route.trafficDelaySeconds / 60.0).round();
    final trafficDelayText = trafficDelayMin > 0 ? '+$trafficDelayMin min' : null;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLatLng ?? const LatLng(28.6139, 77.2090),
                zoom: 14,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: markers,
              polylines: polylines,
              onMapCreated: (c) => _mapController = c,
              onTap: (latLng) async {
                final origin = currentLatLng;
                if (origin == null) {
                  _showSnack('Waiting for GPS…');
                  return;
                }

                setState(() {
                  _destination = latLng;
                  _route = null;
                  _remainingDistanceMeters = 0;
                  _remainingDurationSeconds = 0;
                });

                await _fetchRoute(origin: origin, destination: latLng, showLoading: true);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            children: [
                              Icon(widget.mode.icon, color: scheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${widget.mode.label} • Tap map to set destination',
                                  style: t.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.82)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      MapActionPill(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onTap: () => context.pop(),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (route != null && !_navigationStarted)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ElevatedButton.icon(
                          onPressed: _startNavigation,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start Navigation'),
                        ),
                      ),
                    )
                  else if (route != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: FloatingInfoCard(
                          distanceText: _formatDistance(_remainingDistanceMeters),
                          etaText: _formatEta(_remainingDurationSeconds),
                          safetyScore: route.safetyScore,
                          trafficDelayText: trafficDelayText,
                          isLoading: _isFetchingRoute,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: (route != null && _navigationStarted ? 172 : route != null ? 224 : 24) + MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MapActionPill(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter',
                  onTap: () async {
                    final p = _current;
                    if (p == null || _mapController == null) return;
                    try {
                      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.latitude, p.longitude), 16.2));
                    } catch (e) {
                      debugPrint('Recenter failed: $e');
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                MapActionPill(
                  icon: Icons.close_rounded,
                  tooltip: 'Clear route',
                  onTap: () {
                    _positionSub?.cancel();
                    setState(() {
                      _destination = null;
                      _route = null;
                      _navigationStarted = false;
                      _remainingDistanceMeters = 0;
                      _remainingDurationSeconds = 0;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
