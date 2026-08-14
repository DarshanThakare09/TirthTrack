import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingHelper {
  GeocodingHelper._();

  static const String _googleApiKey = 'AIzaSyB1axqjEo3cWgYbIL0nNNwq_t3Pdl43B4g';

  /// Reverse geocodes coordinates to a human-readable address description
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      // 1. Try Google Geocoding API first
      final googleUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleApiKey',
      );
      final googleResp = await http.get(googleUrl).timeout(const Duration(seconds: 4));
      if (googleResp.statusCode == 200) {
        final data = jsonDecode(googleResp.body) as Map<String, dynamic>;
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final results = data['results'] as List;
          final formatted = results.first['formatted_address'] as String?;
          if (formatted != null && formatted.isNotEmpty) {
            return formatted;
          }
        }
      }
    } catch (_) {}

    try {
      // 2. Fallback to OpenStreetMap Nominatim reverse geocode
      final osmUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final osmResp = await http.get(
        osmUrl,
        headers: {'User-Agent': 'TirthTrackAdmin/1.0 (contact@tirthtrack.gov.in)'},
      ).timeout(const Duration(seconds: 4));

      if (osmResp.statusCode == 200) {
        final data = jsonDecode(osmResp.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
    } catch (_) {}

    return null;
  }
}
