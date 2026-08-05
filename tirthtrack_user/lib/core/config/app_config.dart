// ============================================================
// core/config/app_config.dart
// ============================================================

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application-wide configuration loaded from .env
/// Never hardcode keys here — always read from dotenv.
class AppConfig {
  AppConfig._();

  static String get supabaseUrl {
    final v = dotenv.env['SUPABASE_URL'];
    assert(v != null && v.isNotEmpty, 'SUPABASE_URL is missing from .env');
    return v!;
  }

  static String get supabaseAnonKey {
    final v = dotenv.env['SUPABASE_ANON_KEY'];
    assert(v != null && v.isNotEmpty, 'SUPABASE_ANON_KEY is missing from .env');
    return v!;
  }

  static String get chatbotApiUrl {
    final v = dotenv.env['CHATBOT_API_URL'];
    return (v != null && v.isNotEmpty)
        ? v
        : 'https://tirthchat.vercel.app/api/v1/chat';
  }

  static const String appName = 'Tirth';
  static const String appVersion = '1.0.0';

  /// Nashik Kumbh Mela approximate center coordinates
  static const double kumbhCenterLat = 19.9975;
  static const double kumbhCenterLng = 73.7898;
}
