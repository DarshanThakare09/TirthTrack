import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration loaded from .env
class AppConfig {
  AppConfig._();

  static String get supabaseUrl {
    final v = dotenv.env['SUPABASE_URL'];
    assert(v != null && v.isNotEmpty, 'SUPABASE_URL is missing from .env');
    return v ?? '';
  }

  static String get supabaseAnonKey {
    final v = dotenv.env['SUPABASE_ANON_KEY'];
    assert(v != null && v.isNotEmpty, 'SUPABASE_ANON_KEY is missing from .env');
    return v ?? '';
  }

  static String get appName => dotenv.env['APP_NAME'] ?? 'TirthTrack Admin';
  static const String appVersion = '1.0.0';

  /// Nashik Kumbh Mela default center coordinates (Trimbakeshwar / Ramkund area)
  static const double kumbhCenterLat = 19.9975;
  static const double kumbhCenterLng = 73.7898;
}
