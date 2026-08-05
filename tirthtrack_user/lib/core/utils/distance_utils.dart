// ============================================================
// core/utils/distance_utils.dart
// ============================================================

import 'dart:math';

/// Utility for geographic distance calculations.
class DistanceUtils {
  DistanceUtils._();

  static const double _earthRadiusKm = 6371.0;

  /// Returns distance in kilometers between two lat/lng points
  /// using the Haversine formula.
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Returns distance in meters.
  static double haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      haversineKm(lat1, lng1, lat2, lng2) * 1000;

  /// Human-readable distance string.
  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  static double _toRad(double deg) => deg * (pi / 180);
}
