import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<bool> ensurePermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
      if (permission == LocationPermission.deniedForever) return false;
      return true;
    } catch (e) {
      debugPrint('ensurePermission failed: $e');
      return false;
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final ok = await ensurePermission();
      if (!ok) return null;
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    } catch (e) {
      debugPrint('getCurrentPosition failed: $e');
      return null;
    }
  }

  Stream<Position> watchPosition() async* {
    final ok = await ensurePermission();
    if (!ok) {
      yield* const Stream.empty();
      return;
    }

    final settings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    yield* Geolocator.getPositionStream(locationSettings: settings).handleError((e) {
      debugPrint('Position stream error: $e');
    });
  }
}
