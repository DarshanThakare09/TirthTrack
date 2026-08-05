// ============================================================
// core/services/location_service.dart
// ============================================================

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../utils/logger.dart';

/// Wraps geolocator. Handles permission checks and position streams.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  // ── Permission check ──────────────────────────────────────
  Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Returns true if location is fully available.
  Future<bool> get isAvailable async {
    final serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) return false;
    final permission = await checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  // ── Get current position ──────────────────────────────────
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await isServiceEnabled();
      if (!serviceEnabled) {
        await openLocationSettings();
      }

      var perm = await checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      appLogger.w('LocationService getCurrentPosition fallback to lastKnown: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  // ── Position stream ───────────────────────────────────────
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // meters
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              'Tirth is tracking your location for safety.',
          notificationTitle: 'Tirth Active',
          enableWakeLock: true,
        ),
      ),
    );
  }
}
