// ============================================================
// core/services/location_service.dart
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
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

  /// Returns true if location is fully available (service enabled + permission granted).
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
      final serviceEnabled = await isServiceEnabled();
      if (!serviceEnabled) {
        return await Geolocator.getLastKnownPosition();
      }

      final perm = await checkPermission();
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
    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // 0 meters for precise updates
        intervalDuration: const Duration(seconds: 5), // 5 seconds
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              'Tirth is tracking your location for safety.',
          notificationTitle: 'Tirth Active',
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }
}
