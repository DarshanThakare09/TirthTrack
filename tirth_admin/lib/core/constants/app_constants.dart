import 'package:latlong2/latlong.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'TirthTrack Admin';
  static const String appSubtitle = 'Nashik Kumbh Mela Management Portal';

  // Map defaults
  static const double defaultLat = 19.9975;
  static const double defaultLng = 73.7898;
  static const double defaultZoom = 13.0;
  static const LatLng nashikCenter = LatLng(defaultLat, defaultLng);
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Pagination / Limit defaults
  static const int defaultPageSize = 25;

  // Login Code Defaults
  static const int minLoginCodeLength = 6;
  static const int defaultExpiryDays = 7;
}
